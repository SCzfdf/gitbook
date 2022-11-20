# Kafka Segment

为了防止Partition不断写入数据导致log过大. 以至于检索消息速度下降. 

Kafka将Partition划分为多个Segment

​		

在磁盘上Segment由以下部分组成

1.   .log  日志文件
2.   .index  偏移量索引文件
3.   .timeindex  时间索引文件



## 稀疏索引

由于一个Segment里可能存放很多消息, 为每条消息建立一个索引会占用大量的空间, 并且插入和删除的开销也会随之增大.

因此Kafka并不会为每一条消息都新建一条索引. 这种方式称为稀疏索引

>   默认写入消息超过4Kb会新建一个索引

![kafka稀疏索引](segment.assets/kafka%E7%A8%80%E7%96%8F%E7%B4%A2%E5%BC%95.svg)



## 时间索引

时间索引并不会在查询中直接使用, 主要用于

1.   日志清理
2.   日志切分
3.   流式处理

>   时间戳有2种, 分别是`CreateTime`(生产者创建时间)和`LogAppendTime`(Kafka写入时间)



## 检索数据

1.   通过offset确认Segment

     >   Segment是根据base offset命名的, 所以可以根据二分查找找到对应Segment

2.   再次通过二分查询从.index文件中找到对应的稀疏索引的position

     >   找到小于等于offset的最大offset, 获取position

3.   获取position后从.log文件中查找offset, 和需要的offset比较直到找到消息



## Kafka为什么不使用Mysql底层的B+Tree

从查询性能上B+Tree优于稀疏索引. 

但因为插入和删除数据会导致B+Tree进行调整. 导致消耗额外的性能

对于CURD并重的Mysql来说使用B+Tree非常合适

但是对于Kafka来说为了查询更快而使用更高级的B+Tree并不适合

并且在消息顺序读的业务场景下, 预读消息大概率会很快的被消费掉. 因此可以一次读取尽可能多的消息到内存中从而减少读取次数

