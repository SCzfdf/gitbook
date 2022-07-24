# kafkaProducer发送消息流程

![kafka.png](producer%E5%8F%91%E9%80%81%E6%B6%88%E6%81%AF%E6%B5%81%E7%A8%8B.assets/0d4c409951ff48818f8f87b8703d69c2.png)

消息发送整体流程. 生产端主要由Main线程和Sender线程协调运行

其中[拦截器](./拦截器.md), [序列化器](./序列化器), [分区器](./分区和副本.md)可以看前面的

​		

[Kafka生产者之Sender分析](https://blog.csdn.net/CSDNgaoqingrui/article/details/109029223)

[Sender详解](https://www.cnblogs.com/dingwpmz/p/12168351.html)

从属性开始

```java
/* kafka客户端, 主要封装与Broker的通讯 */
private final KafkaClient client;

/* 消息累加器 */
private final RecordAccumulator accumulator;

/* 元数据信息=>topic分区信息 */
private final ProducerMetadata metadata;

// 是否确保消息有序=>这里只的是是否确保重发时有序
// 由配置`max.in.flight.requests.per.connection`提供 > 1则不确保有序(false)
private final boolean guaranteeMessageOrder;

// 单次请求最大大小=>指序列化后的大小
// 由配置`max.request.size`设置
private final int maxRequestSize;

// 定义已提交的标准, 由配置`acks`决定
private final short acks;

/* 重试次数 */
private final int retries;

/* 时间工具类 */
private final Time time;

/* 线程状态=>ture表示sender运行中 */
private volatile boolean running;

/* 是否强制关闭=>强制关闭忽略未发送/发送中的消息 生产者调用close()时会置为true */
private volatile boolean forceClose;

/* 消息发送相关的配置=>点进去看SenderMetrics的属性就很清楚 */
private final SenderMetrics sensors;

/* 发送请求的最大超时时间 */
private final int requestTimeoutMs;

/* 重试之前的等待时间 */
private final long retryBackoffMs;

/* API版本信息 */
private final ApiVersions apiVersions;

/* 事务处理器 */
private final TransactionManager transactionManager;

// 正在发送的批次
private final Map<TopicPartition, List<ProducerBatch>> inFlightBatches;
```

​		

**run()**

```java
public void run() {
    // 下面代码为了节约行数删除了一些日志
    // 主业务循环 => 调用close则跳出循环
    while (running) {
        try {runOnce();} catch (Exception e) {}
    }
    
    // 非强制关闭 => 如果存在以下三种情况则等待完成
    // 1.累加器仍存在数据 2.存在正在发送的消息 2.存在需要但未开始的事务
    while (!forceClose && ((this.accumulator.hasUndrained() || this.client.inFlightRequestCount() > 0) || hasPendingTransactionalRequests())) {
        try {runOnce();} catch (Exception e) {}
    }

    // 非强制关闭 => 等待事务提交王超
    while (!forceClose && transactionManager != null && transactionManager.hasOngoingTransaction()) {
        if (!transactionManager.isCompleting()) {
            transactionManager.beginAbort();
        }
        try {runOnce();} catch (Exception e) {}
    }

    // 强制关闭 => 不管以上的情况
    if (forceClose) {
        if (transactionManager != null) {
            transactionManager.close();
        }
        this.accumulator.abortIncompleteBatches();
    }
    try {this.client.close();} catch (Exception e) {}
}
```

​		

主要看主业务的**runOnce()**

```java
void runOnce() {
    /* 省略事务相关代码= =我也想写没博客印证怕写错... */

    long currentTimeMs = time.milliseconds(); // 当前时间
    long pollTimeout = sendProducerData(currentTimeMs); // 准备请求 & 获取发送延迟
    client.poll(pollTimeout, currentTimeMs); // 发送请求
}
```

​		

**sendProducerData(currentTimeMs)**

```java
private long sendProducerData(long now) {
	// 获取集群信息
    Cluster cluster = metadata.fetch();
    // 从累加器中获取已经准备好的消息
    RecordAccumulator.ReadyCheckResult result = this.accumulator.ready(cluster, now);

    // 如果准备好的消息中包含的Topic还有一些不知道Leader节点的 =>更新元数据
    if (!result.unknownLeaderTopics.isEmpty()) {
        for (String topic : result.unknownLeaderTopics)
            this.metadata.add(topic, now);

        log.debug("Requesting metadata update due to unknown leader topics from the batched records: {}", result.unknownLeaderTopics);
        this.metadata.requestUpdate();
    }

    // 移除不准备发送消息的节点 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    Iterator<Node> iter = result.readyNodes.iterator();
    long notReadyTimeout = Long.MAX_VALUE;
    while (iter.hasNext()) {
        Node node = iter.next();
        if (!this.client.ready(node, now)) {
            iter.remove();
            notReadyTimeout = Math.min(notReadyTimeout, this.client.pollDelayMs(node, now));
        }
    }

    // 将累加器中的数据转移到inFlightBatches中 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    Map<Integer, List<ProducerBatch>> batches = this.accumulator.drain(cluster, result.readyNodes, this.maxRequestSize, now);
    addToInflightBatches(batches); // 把本批消息增加到inFlightBatches中表示正在发送
    if (guaranteeMessageOrder) {
        // 下面这段代码看不懂什么意义.如果要确保消息顺序则将本批次的topicPartition保存到累加器?
        for (List<ProducerBatch> batchList : batches.values()) {
            for (ProducerBatch batch : batchList)
                this.accumulator.mutePartition(batch.topicPartition);
        }
    }
	
    // 处理过期批次 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    accumulator.resetNextBatchExpiryTime(); // 重置累加器的到期时间
    // 从inFlightBatches中获取发送超时批次 并加入到累加器的过期批次集合中 
    // 由参数`delivery.timeout.ms`设置到期时间 默认120s
    List<ProducerBatch> expiredInflightBatches = getExpiredInflightBatches(now);
    List<ProducerBatch> expiredBatches = this.accumulator.expiredBatches(now);
    expiredBatches.addAll(expiredInflightBatches);

    if (!expiredBatches.isEmpty()) {
        log.trace("Expired {} batches in accumulator", expiredBatches.size());
    }
    for (ProducerBatch expiredBatch : expiredBatches) {
        String errorMessage = "错误信息......";
        // 针对超时批次做一些失败处理 
        // 如:事务发送abort请求, 移除inFlightBatches的相关topic, 记录错误信息到sensors
        failBatch(expiredBatch, -1, NO_TIMESTAMP, new TimeoutException(errorMessage), false);
        if (transactionManager != null && expiredBatch.inRetry()) {
            // 事务相关的看不是很懂...大概是标记这个Topic
            transactionManager.markSequenceUnresolved(expiredBatch);
        }
    }
    
    // 收集一些指标信息
    sensors.updateProduceRequestMetrics(batches);

    // 设置下一次发送的延迟时间
    // 1. 有数据准备好了则马上发送
    // 2. 在三个中取最小的 下一次数据准备的检查时间 & 累加器中的剩余超时时间 & 节点和连接的超时时间 
    long pollTimeout = Math.min(result.nextReadyCheckDelayMs, notReadyTimeout);
    pollTimeout = Math.min(pollTimeout, this.accumulator.nextExpiryTimeMs() - now);
    pollTimeout = Math.max(pollTimeout, 0);
    if (!result.readyNodes.isEmpty()) {
        log.trace("Nodes with data ready to send: {}", result.readyNodes);
        pollTimeout = 0;
    }
    
    // 按照Broker构建发送请求 => 只是构建请求, 并不发送
    sendProduceRequests(batches, now);
    return pollTimeout;
}
```

​		

**client.poll(pollTimeout, currentTimeMs);**

```java
public List<ClientResponse> poll(long timeout, long now) {
    ensureActive(); // 确保client存活

    if (!abortedSends.isEmpty()) {
        // 如果存在异常请求 则马上处理
        List<ClientResponse> responses = new ArrayList<>();
        handleAbortedSends(responses);
        completeResponses(responses);
        return responses;
    }

    // 尝试更新元数据(topic信息)
    long metadataTimeout = metadataUpdater.maybeUpdate(now);
    try {
        // 发送请求
        this.selector.poll(Utils.min(timeout, metadataTimeout, defaultRequestTimeoutMs));
    } catch (IOException e) {
        log.error("Unexpected error during I/O", e);
    }

    // process completed actions
    long updatedNow = this.time.milliseconds();
    List<ClientResponse> responses = new ArrayList<>();
    // 对结果收集处理
    handleCompletedSends(responses, updatedNow);
    handleCompletedReceives(responses, updatedNow);
    handleDisconnections(responses, updatedNow);
    handleConnections();
    handleInitiateApiVersionRequests(updatedNow);
    handleTimedOutConnections(responses, updatedNow);
    handleTimedOutRequests(responses, updatedNow);
    completeResponses(responses);

    return responses; // 返回结果
}
```

![Sender流程](producer%E5%8F%91%E9%80%81%E6%B6%88%E6%81%AF%E6%B5%81%E7%A8%8B.assets/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3ByZXN0aWdlZGluZw==,size_16,color_FFFFFF,t_70-16317215000662.png)







