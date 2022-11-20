# 简单NIO代码

**服务端**

```java
public class NioEchoServer {
    private static final int PORT = 8000;
    private final ServerSocketChannel serverSocketChannel;
    private final Selector selector;
    private final ByteBuffer buffer;
    private final Charset charset;

    public static void main(String[] args) throws IOException {
        new NioEchoServer().service();
    }

    public NioEchoServer() throws IOException {
        serverSocketChannel = ServerSocketChannel.open();
        serverSocketChannel.configureBlocking(false); // 非阻塞模式
        serverSocketChannel.socket().setReuseAddress(true);
        serverSocketChannel.socket().bind(new InetSocketAddress(PORT));

        selector = Selector.open();

        buffer = ByteBuffer.allocate(1024);
        charset = StandardCharsets.UTF_8;

        System.out.println("服务器启动");
    }

    public void service() throws IOException {
        serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);

        while (selector.select() > 0) {
            Set<SelectionKey> selectionKeySet = selector.selectedKeys();
            Iterator<SelectionKey> iterator = selectionKeySet.iterator();
            SelectionKey selectionKey;
            while (iterator.hasNext()) {
                selectionKey = iterator.next();
                iterator.remove();

                if (selectionKey.isAcceptable()) {
                    acceptable(selectionKey); // 连接就绪
                }else if (selectionKey.isReadable()) {
                    readable(selectionKey); // 读就绪
                }else if (selectionKey.isWritable()) {
                    writable(selectionKey); // 写就绪
                }
            }
        }

    }

    private void acceptable(SelectionKey selectionKey) throws IOException {
        // 连接就绪 => 把channel调节为非阻塞模式 并加入注册到selector中
        System.err.println("isAcceptable");
        ServerSocketChannel server = (ServerSocketChannel) selectionKey.channel();
        SocketChannel accept = server.accept();
        accept.configureBlocking(false);
        accept.register(selector, SelectionKey.OP_READ);
    }

    private void readable(SelectionKey selectionKey) throws IOException {
        // 读就绪 => 将读取到的字节转为字符并记录到附件中
        System.err.println("isReadable");
        SocketChannel channel = (SocketChannel) selectionKey.channel();

        if (channel.read(buffer) > 0) {
            buffer.flip();
            String msg = charset.decode(buffer).toString(); // byte->字符串
            buffer.clear();
            System.out.println(msg);
            if ("bye".endsWith(msg)) {
                channel.close(); // 如果是bye就断开
            }else {
                selectionKey.attach("echo:" + msg); // 加载到附件中
                // 因为是if-else 如果只监听SelectionKey.OP_WRITE就没有连接退出
                selectionKey.interestOps(SelectionKey.OP_WRITE | SelectionKey.OP_READ);
            }
        }else {
            // 连接断开会一直有一个读就绪事件. 但调用read()=0
            selectionKey.channel().close();
            System.out.println("链接退出");
        }
    }

    private void writable(SelectionKey selectionKey) throws IOException {
        // 写就绪 => 将附件中的内容返回
        System.err.println("isWritable");
        SocketChannel channel = (SocketChannel) selectionKey.channel();
        String msg = selectionKey.attachment().toString();

        // 这里用byte[]的方式是想多种写法
        byte[] bytes = msg.getBytes(StandardCharsets.UTF_8);
        int length = bytes.length;
        for (int i = 0; i < length;) {
            int min = Math.min(length - i, buffer.capacity());
            buffer.put(bytes, i, min);
            buffer.flip();
            channel.write(buffer);
            buffer.clear();
            i += min;
        }

        selectionKey.interestOps(SelectionKey.OP_READ);
    }
}
```



NIO代码比BIO复杂很多. 直到写完demo还有几个问题不知道怎么解决. 没办法= =IO代码本来就挺少的. 何况NIO

问题1 : 

如果有一个超大的文本(UTF-8 8G)这个要怎么接收. 

一部分一部分接收的话可能会出现一部分乱码. 因为使用Byte的, 所以也不能使用`isHighSurrogate()`判断是否高位. 如果比较小的话还可以一次性接收完.

>   或者手撕编码. 直接从手动转到最后一个
>
>   写到这里好像有点通了. 因为1char = 2byte. char要么高位要么低位. 是不是只判断最后2位就可以了?

​		

问题2 :

写demo的时候总觉得频繁改监听事件不太好. 可是没有什么好的想法. 总觉得demo哪里可以优化下

看太少优化不了了...

