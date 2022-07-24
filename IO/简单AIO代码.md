# 简答AIO代码

https://www.jianshu.com/p/ca60733ab03b

[AIO代码](https://blog.csdn.net/a19881029/article/details/52099795)

[AIO代码2](https://blog.csdn.net/qq_29048719/article/details/81045258)

**AIO的客户端代码总有点奇奇怪怪的问题. 调了几天还是不行= =放弃了 后面再看吧**

调AIO的时候遇到个很奇怪的问题, 就是程序有时候可以进断点, 有时候又可以打日志. 后面后知后觉的发现主线程没有join. 在回调时JVM就关闭了也就不会打日志和进入断点了....

>   ~~突然想到.~~ 
>
>   ~~`channel.read(buffer, att, handler);`~~
>
>   ~~上面代码不是阻塞的啊. 是不是可以一下子注册read和write2个. 然后用附件关联觉得输入输出~~
>
>   ~~`channel.read(att.getReadBuffer(), att, new ReadHandler());`~~
>
>   ~~`channel.write(att.getWriteBuffer(), att, new WriteHandler());`~~
>
>   上面那样搞有问题, 而且同时执行read和write也没必要....



**服务端**(服务端是ok的. 用其他的客户端连是没问题的)

```java
public class AioEchoServer {
    private static final int PORT = 8000;
    private final AsynchronousServerSocketChannel serverSocketChannel;

    public static void main(String[] args) throws Exception {
        new AioEchoServer().service();
        // 记住join!
        Thread.currentThread().join();
    }
    
    public AioEchoServer() throws IOException {
        serverSocketChannel = AsynchronousServerSocketChannel.open();
        serverSocketChannel.bind(new InetSocketAddress(PORT));

        System.out.println("服务器启动");
    }

    public void service() throws InterruptedException {
        // 用匿名内部类的方式实现连接的回调
        serverSocketChannel.accept(null,
                new CompletionHandler<AsynchronousSocketChannel, Attachment>() {
                    @Override
                    public void completed(AsynchronousSocketChannel result, Attachment attachment) {
                        System.out.println("收到新的连接");

                        // 连接时创建附件, 并开始监听读事件
                        Attachment att = new Attachment(result, ByteBuffer.allocate(10), new StringBuilder());
                        result.read(att.getBuffer(), att, new ReadHandler());
                    }

                    @Override
                    public void failed(Throwable exc, Attachment attachment) {}
                }
        );
    }

    static class ReadHandler implements CompletionHandler<Integer, Attachment> {
        @Override
        public void completed(Integer result, Attachment attachment) {
            ByteBuffer buffer = attachment.buffer;
            StringBuilder sb = attachment.sb;
            AsynchronousSocketChannel channel = attachment.channel;

            if (attachment.isRead) { // 如果是
                buffer.flip();
                CharBuffer decode = StandardCharsets.UTF_8.decode(buffer);
                buffer.clear();
                char[] array = decode.array();
                sb.append(array);

                char a = array[result-1];
                // 以`;`为结束符
                if (a == ';') {
                    String msg = sb.toString();
                    System.out.println(msg);

                    if ("bye;".equals(msg)) {
                        try {
                            channel.close();
                            System.out.println("关闭连接");
                        } catch (IOException e) {
                            e.printStackTrace();
                        }

                    }else {
                        // 转为写模式 并写
                        sb.setLength(0);
                        attachment.isRead = false;
                        // TODO 这里有个问题. 因为buffer只有10个byte, 所以如果客户端传了>10的只能返回后10个byte. 
                        channel.write(buffer, attachment, this);

                    }
                } else {
                    // 如果最后一个字符不为`;`则继续监听读事件
                    channel.read(buffer, attachment, this);
                }
            } else {
                // 到这里，说明往客户端写数据也结束了，有以下两种选择:
                // 1. 继续等待客户端 2.断开
                attachment.isRead = true;
                buffer.clear();
                channel.read(buffer, attachment, this);
            }
        }

        @Override
        public void failed(Throwable exc, Attachment attachment) {
        }
    }
}
```

​		

**客户端**(就是这个一直调都有问题....)

```java
public class AioEchoClient {
    private static final int PORT = 8000;
    private final AsynchronousSocketChannel socketChannel;
    private final ByteBuffer buffer;
    private final CompletionHandler<Integer, Attachment> readHandler;
    private final CompletionHandler<Integer, Attachment> writeHandler;
    
    public static void main(String[] args) throws Exception {
        new AioEchoClient().service();
        // 记住join....
        Thread.currentThread().join();
    }

    public AioEchoClient() throws IOException {
        socketChannel = AsynchronousSocketChannel.open();

        readHandler = new ReadHandler(); // 原本和Server一样合在一起的
        writeHandler = new WriteHandler();

        buffer = ByteBuffer.allocate(10);
    }

    public void service() throws Exception {
        Attachment att = new Attachment(socketChannel, buffer, new StringBuilder(), readHandler, writeHandler);
        socketChannel.connect(new InetSocketAddress(InetAddress.getLocalHost(), PORT),
                att,
                new CompletionHandler<Void, Attachment>() {
                    @Override
                    public void completed(Void result, Attachment attachment) {
                        // 连接成功直接监听调用write()
                        write(att);
                    }

                    @Override
                    public void failed(Throwable exc, Attachment attachment) {
                    }
                });
    }

    static class WriteHandler implements CompletionHandler<Integer, Attachment> {
        @Override
        public void completed(Integer result, Attachment attachment) {
            write(attachment);
        }

        @Override
        public void failed(Throwable exc, Attachment attachment) {
            exc.printStackTrace();
        }
    }

    static class ReadHandler implements CompletionHandler<Integer, Attachment> {
        @Override
        public void completed(Integer result, Attachment attachment) {
            if (result == 0) {
                // 奇怪问题之一. 有时候result会返回0, 或者10. 可都是不正确的...
                // 有个想法CompletionHandler的2个泛型是怎么确定返回给我什么的
                attachment.channel.write(attachment.buffer, attachment, this);
            }

            ByteBuffer buffer = attachment.buffer;
            StringBuilder sb = attachment.sb;
            AsynchronousSocketChannel channel = attachment.channel;

            buffer.flip();
            CharBuffer decode = StandardCharsets.UTF_8.decode(buffer);
            buffer.clear();
            char[] array = decode.array();
            sb.append(array);

            System.out.println("read result:" + result + " buffer:" + Arrays.toString(array));

            char a = array[result-1];
            if (a == ';') {
                String msg = sb.toString();
                System.out.println(msg);

                if ("bye;".equals(msg)) {
                    try {
                        channel.close();
                        System.out.println("关闭连接");
                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                }else {
                    sb.setLength(0);
                    attachment.isRead = false;
                    // TODO 这里有个问题. 因为buffer只有10个byte, 所以如果客户端传了>10的只能返回后10个byte. 
                    channel.write(buffer, attachment, this);

                }
            } else {
                channel.read(buffer, attachment, this);
            }
        }

        @Override
        public void failed(Throwable exc, Attachment attachment) {
            exc.printStackTrace();
        }
    }

    private static void write(Attachment attachment) {
        try {
            // 检查是否已经有消息, 如果没有则等待输入
            checkWriteCacheAndWaitInput(attachment);

            ByteBuffer buffer = attachment.buffer;
            AsynchronousSocketChannel channel = attachment.channel;
            byte[] bytes = attachment.getWriteCaches();
            int length = bytes.length;
            int index = attachment.getIndex();

            System.out.println("write length:" + length + " index:" + index);
            if (length > 0) { // 肯定>0的...
                if (length > index) { // index表示写入的下标 => 如果还没写完则继续写
                    attachment.index = Math.min(attachment.index + buffer.capacity(), length);

                    buffer.clear();
                    buffer.put(bytes, 0, attachment.index);
                    buffer.flip();

                    channel.write(buffer, attachment, attachment.writeHandler);
                } else {
                    // 初始化init => 主要是缓存
                    attachment.init(true);
                    channel.read(attachment.buffer, attachment, attachment.readHandler);
                }
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    private static void checkWriteCacheAndWaitInput(Attachment attachment) throws IOException {
        if (attachment.writeCaches == null) {
            LineInputStream line = new LineInputStream(System.in);
            String msg = line.readLine();

            attachment.setWriteCaches(msg.getBytes(StandardCharsets.UTF_8));
            attachment.setIndex(0);
            attachment.setRead(false);
        }
    }
}
```



**附件**

```java
public class Attachment {
    // 2个handler是后来加的, 其实没必要
    CompletionHandler<Integer, Attachment> readHandler;
    CompletionHandler<Integer, Attachment> writeHandler;
    AsynchronousSocketChannel channel;
    ByteBuffer buffer;
    StringBuilder sb;
    byte [] writeCaches;
    int index;
    boolean isRead = true;

    public Attachment(AsynchronousSocketChannel channel, ByteBuffer buffer, StringBuilder sb) {
        this.channel = channel;
        this.buffer = buffer;
        this.sb = sb;
    }

    public Attachment(AsynchronousSocketChannel channel, ByteBuffer buffer, StringBuilder sb,
                      CompletionHandler<Integer, Attachment> readHandler,
                      CompletionHandler<Integer, Attachment> writeHandler) {
        this.readHandler = readHandler;
        this.writeHandler = writeHandler;
        this.channel = channel;
        this.buffer = buffer;
        this.sb = sb;
    }

    // 清理缓存, 初始化附件
    public void init(boolean isRead) {
        this.isRead = isRead;
        buffer.clear();
        sb.setLength(0);
        writeCaches = null;
        index = 0;
    }

    public byte[] getWriteCaches() {
        return writeCaches;
    }

    public Attachment setWriteCaches(byte[] writeCaches) {
        this.writeCaches = writeCaches;
        return this;
    }

    public int getIndex() {
        return index;
    }

    public Attachment setIndex(int index) {
        this.index = index;
        return this;
    }

    public boolean isRead() {
        return isRead;
    }

    public Attachment setRead(boolean read) {
        isRead = read;
        return this;
    }

    public AsynchronousSocketChannel getChannel() {
        return channel;
    }

    public ByteBuffer getBuffer() {
        return buffer;
    }

    public StringBuilder getSb() {
        return sb;
    }

    @Override
    public String toString() {
        return "Attachment{" +
                "channel=" + channel +
                ", buffer=" + buffer +
                ", sb=" + sb +
                ", isRead=" + isRead +
                '}';
    }
}
```

