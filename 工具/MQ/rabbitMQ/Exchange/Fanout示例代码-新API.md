# Fanout示例代码(新API)

[RabbitMQ-queueBind-exchangeBind](https://www.jianshu.com/p/67922a4439dc)



1.  创建获取连接的方法

    ```java
    public class MqCommonConnection {
        public static Connection getConn() throws IOException, TimeoutException {
            ConnectionFactory factory = new ConnectionFactory();
            factory.setHost(MqArgument.RABBIT_HOST);
            factory.setPassword(MqArgument.RABBIT_PASSWORD);
            factory.setUsername(MqArgument.RABBIT_USERNAME);
            factory.setVirtualHost(MqArgument.RABBIT_VIRTUAL_HOST);
    
            return factory.newConnection();
        }
    }
    ```

2.  创建消费者

    ```java
    public class Consumer {
        public static void main(String[] args) {
            try  {
                // 1. 获取连接 不能用try(conn) 的方式自动关闭连接了,应该说连接不应该关闭
                Connection connection = MqCommonConnection.getConn();
                // 2. 获取通道
                Channel channel = connection.createChannel();
    
                // 4. 创建消费者
                DefaultConsumer myConsumer = new MyConsumer(channel);
    
                /*
                 * 5. 设置通道
                 * 参数1：队列名称
                 * 参数2：自动回复队列说消息消费成功, 高并发下不自动回复
                 *          使用channel.basicAck(envelope.getDeliveryTag(),false); 手动回复
                 * 参数3：具体消费者对象
                 */
                channel.basicConsume("test_queue", true, myConsumer);
    
            } catch (Exception e) {
                e.printStackTrace();
            }
    
        }
    }
    ```

3.  创建生产者

    ```java
    public class Producer {
        public static void main(String[] args) {
            // 1. 获取连接 注意,这样方法执行完连接自动关闭
            try (Connection connection = MqCommonConnection.getConn()) {
    
                // 2. 获取通道
                Channel channel = connection.createChannel();
    
                /*
                 * 3. 声明（创建）队列
                 * 参数1：队列名称
                 * 参数2：为true时server重启队列不会消失(持久化)
                 * 参数3：队列是否是独占的，如果为true只能被一个connection使用，其他连接建立时会抛出异常, 一般用于保证顺序消费
                 * 参数4：队列不再使用时是否自动删除（没有连接，并且没有未处理的消息)
                 * 参数5：建立队列时的其他参数
                 */
                channel.queueDeclare("test_queue", true, false, false, null);
    
                /*
                 * 4. 声明（创建）交换机
                 * 参数1：交换机名称
                 * 参数2：交换机类型
                 * 参数3：是否持久化(服务器关闭后依然存在)
                 * 参数4：是否自动删除(不再使用这个交换机时删除这个交换机)
                 * 参数5：是否是MQ内部(如果是属于内部客户不能直接发布)
                 * 参数6：交换机其他参数
                 */
                channel.exchangeDeclare("test_exchange", "fanout", true, false, false, null);
    
                // 5. 绑定交换机和队列
                channel.queueBind("test_queue", "test_exchange", "fanout", null);
    
                // 6. 设置消息属性
                AMQP.BasicProperties properties = new AMQP.BasicProperties.Builder()
                        .deliveryMode(2)
                        .expiration("20000")
                        .build();
    
    
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
                 String message = "hello rabbit ";
                 channel.basicPublish(
                         "test_exchange",
                         "test_queue",
                         false,
                         false,
                         properties,
                         message.getBytes()
                 );
            } catch (Exception e) {
                e.printStackTrace();
            }
    
        }
    }
    ```



~

