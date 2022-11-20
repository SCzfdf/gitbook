# kafka offset维护与更新

[消费者偏移量consumer_offsets相关解析](https://shirenchuang.blog.csdn.net/article/details/109306637)

[Kafka-消费,Offset手动提交,指定offset消费,指定分区消费](https://blog.csdn.net/weixin_37150792/article/details/89851731)

kafka中offset是消费者组与partition相对应的. 

**表示partition具体被消费到那条消息**



## 查看offset

offset储存在kafka中的`_consumer_offset`中

想要手动查看consumer_group与partition的offset可以输入以下命令查看

```shell
bin/kafka-consumer-groups.sh --bootstrap-server xxx1:9092,xxx2:9092,xxx3:9092 --describe --group szz1-group
```

![1](offset%E7%BB%B4%E6%8A%A4%E4%B8%8E%E6%9B%B4%E6%96%B0.assets/1.png)

**CURRENT-OFFSET**: 下一个未被使用的offset

**LOG-END-OFFSET**:  下一条待写入消息的offset

**LAG**: 延迟量, 服务端中所留存的消息与消费掉的消息之间的差值

>   `_consumer_offset`默认有50个分区, 每个分区默认1个副本
>
>   offsets.topic.num.partitions=50
>
>   offsets.topic.replication.factor=1



## offset结构

Topic可以存放对象类型的value(经过序列化). 

`consumer_offset`主要存放2种对象

1.   GroupMetadata: 保存consumer_group中的consumer信息
2.   OffsetAndMetadata: 保存consumer_group对应的partition的offset信息

可以通过如下命令查查

```shell
 .\bin\windows\kafka-console-consumer.bat  --topic _consumer_offsets --partition 3 --bootstrap-server 127.0.0.1:9092 --formatter "kafka.coordinator.group.GroupMetadataManager$OffsetsMessageFormatter" --from-beginning
# linux kafka.coordinator.group.GroupMetadataManager\$OffsetsMessageFormatter
```

前面的 是key 后面的是value

key: 消费组+Topic+分区数

value: 消费组的偏移量信息

![GroupMetadata与OffsetAndMetadata](offset%E7%BB%B4%E6%8A%A4%E4%B8%8E%E6%9B%B4%E6%96%B0.assets/GroupMetadata%E4%B8%8EOffsetAndMetadata.png)

​		

大致可以看成是:

![kafka__consumer_offset储存结构](offset%E7%BB%B4%E6%8A%A4%E4%B8%8E%E6%9B%B4%E6%96%B0.assets/kafka__consumer_offset%E5%82%A8%E5%AD%98%E7%BB%93%E6%9E%84.svg)



## 判断consumer_group所在_consumer_offset

消费者组id的hsahCode % _consumer_offset的分区数

```java
Math.abs(groupID.hashCode()) % numPartitions
```

​		

如果要查看对应的分区信息应该

先查询出所在partition, 然后通过上面命令的`--partition 32`指定查询



## offset更新

[Kafka consumer的offset的提交方式](https://www.jianshu.com/p/3a25a1aaebc1)

offset更新分为自动更新和手动更新



### 自动更新

在创建consumer时指定以下2个参数即可

```java
props.put("enable.auto.commit", "true"); // 开启自动提交
props.put("auto.commit.interval.ms", "1000"); // 提交时间为每秒
```

开启了自动更新会在**poll时**自动将最新的offset提交上去



### 手动更新

手动更新分为

*   同步提交

    `consumer.commitSync()`

    >   同步提交会影响TPS. 

*   异步提交

    `consumer.commitAsync(callback)`

    >   异步提交失败不会重试







## 使用多线程加速消费时offset的提交情况

[使用多线程增加kafka消费能力](https://segmentfault.com/a/1190000018640106)

因为KafkaConsumer在同一个消费者组的情况下是与一个Partition对应的

如果使用多线程加速消费, 并使用自动提交, 可能会导致提交了未完成消费的offset

如果是对offset有强烈需求(允许重复消费, 但不允许漏消费)可以写一段逻辑控制offset提交

有一点需要注意的是

consumer poll时是同时poll多条消息的, 默认的提交方法会将最大的offset提交上去(默认是全部都消费了)

>   poll返回500条时, 提交时就会将500作为偏移量提交上去

如果需要控制细粒度的提交可以

```java
private Map<TopicPartition, OffsetAndMetadata> offsets = new HashMap<>();
int count = 0;
while (true) {
    ConsumerRecords records = consumer.poll(Duration.ofSeconds(1));
    for (ConsumerRecord record: records) {
        process(record); // 处理消息
        
        offsets.put(new TopicPartition(
                record.topic(), record.partition()), 
                new OffsetAndMetadata(record.offset() + 1)
        );

        if（count % 10 == 0){
            consumer.commitAsync(offsets, null);// 回调处理逻辑是null 
        }
        count++;
    }
}
```





