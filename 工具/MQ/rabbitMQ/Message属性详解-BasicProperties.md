# Message属性详解(BasicProperties)

[RabbitMQ发送消息附带BasicProperties属性详解](https://blog.csdn.net/yaomingyang/article/details/102636666)



```java
// 关联ID 一般用来当做消息的唯一id
private String correlationId;
// 1（nopersistent）非持久化，2（persistent）持久化
private Integer deliveryMode;
// 用于指定回复的队列的名称
private String replyTo;
// 消息的失效时间(如果设置10000(10秒). 如果没有被消费者消费就删除了)
private String expiration;
// 消息ID
private String messageId;


// 消息的内容类型，如：text/plain
private String contentType;
// 消息内容编码
private String contentEncoding;
// 设置消息的header,类型为Map<String,Object>
private Map<String,Object> headers;
// 消息的优先级(应该是从小到大.在集群中不能保证优先消费)
private Integer priority;
// 消息的时间戳
private Date timestamp;
// 类型
private String type;
// 用户ID
private String userId;
// 应用程序ID
private String appId;
// 集群ID
private String clusterId;
```

