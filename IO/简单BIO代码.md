# 简单BIO代码

**服务端**

```java
public class BioEchoServer {
    private static final int POOL_MULTIPLE = 4; // 处理线程倍数
    private static final int PORT = 8000; // 端口
    private final ServerSocketChannel serverSocketChannel;
    private final ExecutorService executorService;
    
    public static void main(String[] args) throws IOException {
        new BioEchoServer().service();
    }

    public BioEchoServer() throws IOException {
        // 创建处理的线程
        executorService = new ScheduledThreadPoolExecutor(
            	// 核心线程数为: 核心处理器 * 4
                Runtime.getRuntime().availableProcessors() * POOL_MULTIPLE,
                new BasicThreadFactory
                        .Builder()
                        .namingPattern("echo-server-pool-%d")
                        .daemon(true)
                        .build()
        );

        serverSocketChannel = ServerSocketChannel.open();
        serverSocketChannel.configureBlocking(true); // 阻塞模式
        serverSocketChannel.socket().setReuseAddress(true); // 关闭后快速启用
        serverSocketChannel.socket().bind(new InetSocketAddress(PORT));
        
        System.out.println("服务器启动");
    }

    public void service() {
        while (true) {
            SocketChannel accept;
            try {
                accept = serverSocketChannel.accept();
                
                // 一旦有连接进来则丢给线程处理
                executorService.execute(new Handler(accept));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    static class Handler implements Runnable {
        SocketChannel socketChannel;

        public Handler(SocketChannel socketChannel) {
            this.socketChannel = socketChannel;
        }

        @Override
        public void run() {
            handle(socketChannel);
        }

        public void handle(SocketChannel socketChannel) {
            // 从Socket中获取输入输出流并转化为字符流
            try (Socket socket = socketChannel.socket();
                 BufferedReader br = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                 PrintWriter pw = new PrintWriter(new OutputStreamWriter(socketChannel.socket().getOutputStream()))) {

                System.out.println("接收到客户连接: " + socket.getInetAddress() + "_" + socket.getPort());

                // br.readLine()阻塞等待客户端的消息. 
                // 收到则打印并添加`echo:`返回给客户端
                String msg;
                while ((msg = br.readLine()) != null) {
                    System.out.println(msg);
                    pw.println("echo:" + msg);
                    pw.flush();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }    
}
```

​		

**客户端**

```java
public class BioEchoClient {
    private static final int PORT = 8000; // 端口
    private final SocketChannel socketChannel;
    
    public static void main(String[] args) throws IOException {
        new BioEchoClient().service();
    }

    public BioEchoClient() throws IOException {
        socketChannel = SocketChannel.open();
        socketChannel.connect(new InetSocketAddress(InetAddress.getLocalHost(), PORT));
        socketChannel.configureBlocking(true);
    }

    public void service() throws IOException {
        // 从socket中获取输入输出流. 并监控控制台的输入
        try (BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
             BufferedReader brSocket = new BufferedReader(new InputStreamReader(socketChannel.socket().getInputStream()));
             PrintWriter pwSocket = new PrintWriter(new OutputStreamWriter(socketChannel.socket().getOutputStream()))) {

            // br.readLine()会等待控制台的输入
            // 等监控到控制台输入后会发送给服务端并在brSocket.readLine()等待服务端返回
            String msg;
            while ((msg = br.readLine()) != null) {
                pwSocket.println(msg);
                pwSocket.flush();
                System.out.println(brSocket.readLine());

                if ("bye".equals(msg)) {
                    return;
                }
            }
        }
    }
}
```

​		

BIO的客户端和服务端代码都比较简单. 但有几个很明显的缺点.

1.  依赖线程池
2.  线程池满了则不能接受新的连接(特别是对于长连接)



​		

