# Confirm确认消息

[RabbitMQ系列（四）RabbitMQ事务和Confirm发送方消息确认——深入解读](https://www.cnblogs.com/vipstone/p/9350075.html)



1.  channel.waitForConfirms()普通发送方确认模式；
2.  channel.waitForConfirmsOrDie()批量确认模式；
3.  channel.addConfirmListener()异步监听发送方确认模式；



1.  首先要开启confirm模式

    ```java
    channel.confirmSelect();
    ```

2.  然后选择confirm的模式

    ```java
    if (channel.waitForConfirms()) {
       System.out.println("消息发送成功" );
    }
    
    // ----------------------------------------------------
    
    channel.waitForConfirmsOrDie(); //直到所有信息都发布，只要有一个未确认就会IOException
    System.out.println("全部执行完成");
    
    // ----------------------------------------------------
    // 异步消息确认有可能是批量确认的，是否批量确认在于返回的multiple的参数，此参数为bool值，如果true表示批量执行了deliveryTag这个值以前的所有消息，如果为false的话表示单条确认。
    channel.addConfirmListener(new ConfirmListener() {
    	@Override
    	public void handleNack(long deliveryTag, boolean multiple) throws IOException {
    	System.out.println("未确认消息，标识：" + deliveryTag);
    	}
        
    	@Override
        public void handleAck(long deliveryTag, boolean multiple) throws IOException {
    	System.out.println(String.format("已确认消息，标识：%d，多个消息：%b", deliveryTag, multiple)
    	);
    }
    });
    ```



>   异步监听handleAck方法的参数
>
>   deliveryTag 是channel 共享的
>
>   multiple 表示当前确认是否是多个: 
>
>   ​	**true**: deliveryTag 前的n个均成功ACK
>
>   ​	**false**表示当前deliveryTag 成功ACK



上面只是confirm的简单用法. 如果要用于生产还需要发送消息时记录下当前的deliveryTag, 如果rabbit返回ACK才把deliveryTag 对应的消息标记成功

然后补偿任务也要做相应处理

```java
for (int i = 0; i < 10; i++) {
    // 获取下一个deliveryTag 需要开启confirm模式 不然的话总是0
    System.out.println("getNextPublishSeqNo: "+channel.getNextPublishSeqNo());
    
    String message = "hello rabbit "+ 1;
    channel.basicPublish(
            "test_exchange",
            "test_queue",
            false,
            false,
            properties,
            message.getBytes()
    );

}
```



