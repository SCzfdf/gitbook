# Return消息机制

[RabbitMQ的Return消息机制](https://www.jianshu.com/p/f23c784e163d)



1.  添加return监听：`addReturnListener`，生产端去监听这些不可达的消息，做一些后续处理，比如说，记录下消息日志，或者及时去跟踪记录，有可能重新设置一下就好了

    ```java
    channel.addReturnListener((replyCode, replyText, exchange, routingKey, properties1, body) -> {
    	System.err.println("---------handle  return----------");
        System.err.println("replyCode: " + replyCode);
        System.err.println("replyText: " + replyText);
        System.err.println("exchange: " + exchange);
        System.err.println("routingKey: " + routingKey);
        System.err.println("properties: " + properties1);
        System.err.println("body: " + new String(body));
    });
    ```

    

2.  发送消息时，设置`Mandatory`：如果为true，则监听器会接收到路由不可达的消息，然后进行后续处理，如果为false，那么broker端自动删除该消息！

    ```java
    /*
                 * 7. 发送消息
                 * 这里要注意, 这里没有指定交换机名称会使用一个默认的内置交换机
                 * 这个交换机默认是direct 的, 隐式与所有队列绑定, 其bindingKey 就是queueName
                 * 而且只有当发送参数immediate 为false 时才能发送出去
                 * 参数1：交换机名称
                 * 参数2：RoutingKey
                 * 参数3：是否强制. 消息不可达时, false:mq自动删除, true:Return监听器会监听到
                 * 参数4：是否立即发送 Note that the RabbitMQ server does not support this flag.(mq服务器不支持这个标记...)
                 * 参数5：消息参数
                 * 参数6：消息体
                 */
    channel.basicPublish(
            "test_exchange_topic",
            "topicxx",
            true, // 这个要true ReturnListener才生效
            false,
            properties,
            message.getBytes()
    );
    ```



可以配合Confirm监听器更优雅的实现消息确认投递

