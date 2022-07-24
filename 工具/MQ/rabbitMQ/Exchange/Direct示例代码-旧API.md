# Direct示例代码(旧API)

API是旧的不建议使用, 看下就好了

注意的是, 如果生产者不指定路由(只填个"")那么消息会转发到默认的Exchange

这个Exchange隐式与所有队列绑定, BindingKey是队列名称



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
            // 1. 获取连接
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
                channel.queueDeclare("test_queue",true,false,true,null);
    
                // 4. 创建消费者
                QueueingConsumer queueingConsumer = new QueueingConsumer(channel);
    
                /*
                 * 5. 设置通道
                 * 参数1：队列名称
                 * 参数2：自动回复队列说消息消费成功
                 * 参数3：具体消费者对象
                 */
                channel.basicConsume("test_queue", true, queueingConsumer);
    
                // 6.获取消息
                while (true) {
                    // 一直阻塞. 直到有消息进来, 带参数的表示超时时间
                    QueueingConsumer.Delivery delivery = queueingConsumer.nextDelivery();
                    System.out.println(new String(delivery.getBody()));
                    System.out.println(delivery.getEnvelope());
                    System.out.println(delivery.getProperties());
                }
    
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
            // 1. 获取连接
            try (Connection connection = MqCommonConnection.getConn()) {
    
                // 2. 获取通道
                Channel channel = connection.createChannel();
    
                /*
                 * 3. 发送消息
                 * 这里要注意, 这里没有指定交换机名称会使用一个默认的内置交换机
                 * 这个交换机默认是direct 的, 隐式与所有队列绑定, 其bindingKey 就是queueName
                 * 而且只有当发送参数immediate 为false 时才能发送出去
                 * 参数1：交换机名称
                 * 参数2：RoutingKey
                 * 参数3：是否强制 消息不可达时, false:mq自动删除, true:Return监听器会监听到
                 * 参数4：是否立即发送 Note that the RabbitMQ server does not support this flag.(mq服务器不支持这个标记...)
                 * 参数5：消息参数
                 * 参数6：消息体
                 */
                String message = "hello rabbit";
                channel.basicPublish(
                        "",
                        "test_queue",
                        true,
                        false,
                        null,
                        message.getBytes()
                );
    
            } catch (Exception e) {
                e.printStackTrace();
            }
    
        }
    }
    ```

    

