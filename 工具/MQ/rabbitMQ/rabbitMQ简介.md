# rabbitMQ

[深入了解RabbitMQ工作原理及简单使用](https://www.cnblogs.com/vipstone/p/9275256.html)



使用erlang语言编写的, 实现了AMQP协议的消息队列服务



## 名词

**ConnectionFactory（连接管理器）：**应用程序与Rabbit之间建立连接的管理器，程序代码中使用；

**Channel（信道）：**消息推送使用的通道；

**Exchange（交换器）：**用于接受、分配消息；

**Queue（队列）**：用于存储生产者的消息；

**RoutingKey（路由键）**：用于把生成者的数据分配到交换器上；

**BindingKey（绑定键）**：用于把交换器的消息绑定到队列上；



