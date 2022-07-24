# TTL与死信队列

[RabbitMQ高级特性-TTL队列/消息](https://blog.csdn.net/love905661433/article/details/85448991)

[RabbitMQ高级特性-死信队列(DLX)](https://blog.csdn.net/love905661433/article/details/85449191)



## TTL

-   TTL是Time To Live的缩写, 也就是生存时间
-   RabbitMQ支持消息的过期时间, 在消息发送时可以进行指定
-   RabbitMQ支持队列的过期时间, 从消息入队列开始计算, 只要超过了队列的超时时间配置, 那么消息会自动清除

过期时间按小的生效



设置队列的过期时间

```java
Map<String, Object> arguments = new HashMap<>(1);
// 设置队列超时时间为10秒
arguments.put("x-message-ttl", 60000);
channel.queueDeclare("test_queue_ttl2", true, false, false, arguments);
```



设置消息的过期时间

```java
// 设置设置在消息头
AMQP.BasicProperties properties = new AMQP.BasicProperties.Builder()
                    .deliveryMode(2)
                    .expiration("60000") // 60秒过期
                    .build();

channel.basicPublish(
                        "test_exchange_ttl2",
                        "test_queue_ttl2",
                        properties,
                        message.getBytes()
                );
```





## 死信队列

以下情况消息会变为死信, 如果有指定的话死信会发送到指定路由(不应该是死信交换机吗...)

-   消息被拒绝(basic.reject/basic.nack) 并且requeue重回队列设置成false
-   消息TTL过期
-   队列达到最大长度

>   测试过只有Topic 和Fanout 类型的交换机才能转发死信. 一开始创建Direct 的死活发不过去...

>   死信队列和普通的没什么区别, 只是在普通队列上指定`x-dead-letter-exchange` 参数就可以把死信转发到指定的交换机



声明死信队列和交换机

```java
// 和普通的队列和交换机一样的声明 死信交换机不能是Direct
```



声明普通队列和交换机

```java
// 声明交换机

// 声明队列
Map<String, Object> arguments = new HashMap<>(2);
// 设置队列超时时间为10秒
arguments.put("x-message-ttl", 10000);
arguments.put("x-dead-letter-exchange", "dlx.exchange");

channel.queueDeclare("test_queue_ttl3", true, false, false, arguments);

// 正常绑定
```















