# kafka Rebalance

[rebalance流程](https://www.cnblogs.com/chanshuyi/p/kafka_rebalance_quick_guide.html)

[Kafka Rebalance 客户端原理](https://zhmin.github.io/2019/03/18/kafka-consumer-coordinator/)

[渐进式Rebalance](https://zhuanlan.zhihu.com/p/98770059)

Rebalance(重平衡). 重新**将partition与consumer的对应关系重新分配. 从而达到平衡状态的一种操作**

在Rebalance过程中需要所有Consumer都停止消费等待Rebalance完成(类似JVM的STW). 因此尽可能的需要避免Rebalance(最新的渐进式Rebalance不需要)



## Rebalance触发条件

1.   消费者组成员数发生改变

     *   新成员加入
     *   旧成员主动离开
     *   旧成员崩溃

2.   partition数量发生改变

3.   订阅的topic发生改变

     >   `consumer.subscribe(TOPICS);`中的`TOPICS`可以为正则. 在运行中创建了一个符合的Topic则会重新订阅, 从而触发Rebalance.  这样算新成员加入吧?

后两者是可以通过运维和代码尽可能的规避

第一种则无法避免. 值得注意的是**consumer正常依次启动也会发生Rebalance**



## Rebalance相关协议

1.   **Heartbeat请求**

     consumer定期向coordinator汇报心跳表明自己依然存活

2.   **JoinGroup请求**

     consumer请求加入组

3.   **SyncGroup请求**

     group leader把分配方案同步到组内所有成员中

4.   **LeaveGroup请求**

     consumer主动通知coordinator该conumer即将离组。

5.   **DescribeGroup请求**

     供管理员使用，查看组的所有信息，包括成员信息，协议信息，分配方案以及订阅信息等

在成功rebalance之后，组内所有consumer都需要定期向coordinator发送Heartbeat请求

而每个consumer也是**根据Heartbeat请求的响应中是否包含`REBALANCE_IN_PROGRESS`来判断当前group是否开启了新一轮rebalance**



## Rebalance流程

新的consumer加入到组中的过程如下: 

1.   寻找coordinate

2.   向coordinate发送JoinGroup请求

3.   coordinate通过心跳请求通知其余consumer发送JoinGroup请求

     >   在收到`REBALANCE_IN_PROGRESS`时Consumer会尽可能的提交offset

4.   coordinate为每个consumer分配编号, 并从中选取第一个为Leader. 

     角色和与分配有关的所有信息(用于制定方案)也会通过JoinGroup请求返回

     >   这样新加入的必然为Leader?

5.   consumer发送SyncGroup请求. 其中Leader的SyncGroup请求会附带Rebalance分配方案. 

6.   分配方案会随着SyncGroup请求返回

7.   consumer按照方案订阅其中的partition

>   简单的说: 找coordinate => consumer集合 => 找Leader => 重新分配
>
>   其余情况的Rebalance大同小异, 可以看参考中的

用时序图表示如下图: 

![Rebalance新成员入组时序图](Rebalance.assets/Rebalance%E6%96%B0%E6%88%90%E5%91%98%E5%85%A5%E7%BB%84%E6%97%B6%E5%BA%8F%E5%9B%BE.webp)



## Rebalance问题处理思路及相关配置

-   **session.timeout.ms**

    表示Broker在规定时间内应该收到至少1次Consumer的心跳

    如果时间内没有收到心跳则认为Consumer离线. 触发Rebalance

-   **heartbeat.interval.ms**

    表示Consumer向Broker发送心跳的间隔. 一般来说**session.timeout.ms** >= heartbeat * 3

    同时这个参数还是隐藏的Rebalance通知频率参数. 更小的心跳可以更快的感知Rebalance的触发

-   **max.poll.interval.ms**

    2次poll时间的最大间隔

    如果时间到了还未执行下一次poll则会触发Rebalance(认为已经离线了)

-   **max.poll.records**

    每次poll的消息数. 拉取越多消费时间越长, 需要保证在**max.poll.interval.ms**设置的时间范围内消费完成

    >   阿里云官方文档建议 **max.poll.records** 参数要远小于当前消费组的消费能力（records < 单个线程每秒消费的条数 x 消费线程的个数 x session.timeout的秒数）




## 渐进式Rebalance

![渐进式Rebalance协议](Rebalance.assets/%E6%B8%90%E8%BF%9B%E5%BC%8FRebalance%E5%8D%8F%E8%AE%AE.jpg)

如上图所示. 渐进式Rebalance相对于传统Rebalance相比会发起多次Rebalance, 但却不用将Consumer停止

具体差距在于

第一次收到SyncGroup返回并不会释放全部Partition只会释放多余的Partition

第二次的Rebalance才是对新增Consumer的Partition分配

