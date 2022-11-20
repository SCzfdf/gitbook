# Selector

当程序调用SelectableChannel对象的`register(selector, XX)`时对象关系如下图所示:

![Selector关系图](ChannelIO.assets/Selector%E5%85%B3%E7%B3%BB%E5%9B%BE.svg)

当Channel与Selector进行关联的时候会生成一个SelectionKey. **该对象的作用是用于跟踪被注册事件的句柄**

Selector会把该SelectionKey加入**all-keys**集合中. 

在SelectionKey对象的**有效期内**, Selector会一直监控SelectionKey对象相关的事件. 

如果有相关事件发生, Selector会把该SelectionKey加入**select-keys**集合中

​		

一个Selector对象中会包含3种类型的SelectionKey集合

1.  **all-keys**

    当前所有向Selector注册的SelectionKey集合. 使用`keys()`返回该集合

2.  **select-keys**

    当前所有已经被Selector捕获的SelectionKey集合. 使用`selectedKeys()`返回该集合

3.  **cancelled-keys**

    已经被取消的SelectionKey集合. 没有提供访问该集合的方法

>   无论是哪种集合. 返回的都是非线程安全的(直接返回对象)



# Selector

[Java NIO之Selector（选择器）](https://www.cnblogs.com/snailclimb/p/9086334.html)

Selector用于检查Channel的状态是否处于可读\可写状态.

由此实现用少量线程管理多个Channel

​		

注册到Selector上的Channel必须是**非阻塞**的

>   更准确的来说是实现了`SelectableChannel`接口的类, 并且实例需要调用了`configureBlocking(false)`使其处于非阻塞模式的Channel

​		

Selector可以简单的理解成操作系统级别的遍历Channel, 和下面代码的功能基本相同

频繁检测channel是否有数据返回, 有数据则返回对应标识符

```java
socketChannel.configureBlocking(false);
ByteBuffer read = ByteBuffer.allocateDirect(1024);
while (true) {
    if (socketChannel.read(read) != 0) { // 因为是非阻塞, 这里read()调用会很频繁
        read.flip();
        System.out.print(StandardCharsets.UTF_8.decode(read).toString());
        read.clear();
    }
}
```

执行上面代码CPU占用会非常的多. 单线程就能占用25%(可能和我的电脑是4核有关, 占满了一个核)

当然使用Selector也不会少到哪里去(一直注册**OP_WRITE**的话). 毕竟都是需要遍历

**使用Selector的优势是可以减少`read()`之类方法的系统调用, 从而减少耗时**



## 核心方法

[Selector源码解析](https://github.com/kangjianwei/LearningJDK/blob/master/src/java/nio/channels/Selector.java)

```java
public abstract class Selector implements Closeable {
    protected Selector() { }

    /**
     * 打开一个新的Selector
     * 会调用系统适配的SelectorProvider.再由SelectorProvider创建系统对应的Selector
     * (会根据你的系统来选择使用select, poll, epoll)
     */
    public static Selector open() throws IOException {
        return SelectorProvider.provider().openSelector();
    }

    // Selector是否打开 true:打开
    public abstract boolean isOpen();

    // 返回构造当前Selector的选择器工厂
    public abstract SelectorProvider provider();

    // 返回与该选择器关联的SelectionKey对象集合
    public abstract Set<SelectionKey> keys();

    // 返回与该选择器关联并事件已被捕获的SelectionKey对象集合
    public abstract Set<SelectionKey> selectedKeys();

    // 返回相关事件已经发送的SelectionKey数. 非阻塞 没有就返回0
    public abstract int selectNow() throws IOException;

    /**
     * 返回相关事件已经发送的SelectionKey数. 如果为0 则进入阻塞状态
     * 出现以下情况之一会从方法中返回:
     * 1. 至少有一个SelectionKey准备完成
     * 2. 其他线程调用了该Selector的wakeup()或close()
     * 3. 执行select()的线程被其他线程中断
     * 4. 超时(如果调用的是有超时参数的select(long time)的话)
     */
    public abstract int select(long timeout) throws IOException;
    public abstract int select() throws IOException;

    // 唤醒执行select()或者select(long)的线程一次
    public abstract Selector wakeup();

    /**
     * 关闭该选择器.
     * 该Selector占用的资源都将释放. 与之关联的SelectionKey都被取消
     * 如果有其他线程正在执行该Selector的select()则会立即返回
     */
    public abstract void close() throws IOException;

}
```



# SelectionKey

[NIO源码分析：SelectionKey](https://www.cnblogs.com/gaofei200/p/13974084.html)

当Channel与Selector进行关联的时候会生成一个SelectionKey. 

**该对象的作用是用于跟踪被注册事件的句柄**

在SelectionKey对象的**有效期内**, Selector会一直监控SelectionKey对象相关的事件. 

在以下情况下SelectionKey将会失效(Selector不会监控):

1.  线程调用SelectionKey的`cancel()`
2.  与该SelectionKey关联的Channel被关闭
3.  与该SelectionKey关联的Selector被关闭

>   Selector, Channel, SelectionKey相互依存. 当然Selector可以关联多个Channel

​		

在SelectionKey中定义了4种事件, 分别用4个int类型常量表示:

1.  **OP_ACCEPT** (10000 => 16) 

    接受连接就绪事件. 表示服务器已经监听到了客户端连接 (服务器用)

2.  **OP_CONNECT** (01000 => 8)

    连接就绪事件. 表示服务器和客户端已经成功建立连接了 (客户端用)

3.  **OP_WRITE** (00100 => 4)

    写就绪事件. 表示可以向通道中写数据了

4.  **OP_READ** (00001 => 1)

    读就绪事件. 表示通道中已经存在可读数据

以上事件分别占有不同的二进制位. 可以通过二进制的`|`运算将监听的事件进行任意组合

`socketChannel.register(selector, SelectionKey.OP_ACCEPT | SelectionKey.OP_CONNECT);`



## 核心方法

```java
// -- Channel and selector operations --
// 返回与该SelectionKey关联的Channel(即使该SelectionKey已调用cancel()也会返回)
public abstract SelectableChannel channel();

// 返回与该SelectionKey关联的Selector(即使该SelectionKey已调用cancel()也会返回)
public abstract Selector selector();

// 返回此SelectionKey是否在有效期内
public abstract boolean isValid();

/**
 * 使该SelectionKey失效
 * 会将Selector中的该SelectionKey加入到cancelled-keys集合中
 * 下次调用select()时将该SelectionKey从all-keys, selected-keys, cancelled-keys中删除
 */
public abstract void cancel();


// -- Operation-set accessors --
// 返回该SelectionKey监听的事件
public abstract int interestOps();

// 重新设置监听事件, 并返回
public abstract SelectionKey interestOps(int ops);

// 返回以就绪事件
public abstract int readyOps();


// -- Operation bits and bit-testing convenience methods --
public static final int OP_READ = 1 << 0;
public static final int OP_WRITE = 1 << 2;
public static final int OP_CONNECT = 1 << 3;
public static final int OP_ACCEPT = 1 << 4;

// 判断该SelectionKey读就绪事件是否发生. 如果没有监听则总返回false
public final boolean isReadable() {
    return (readyOps() & OP_READ) != 0;
}

// 判断该SelectionKey读就绪事件是否发生. 如果没有监听则总返回false
public final boolean isWritable() {
    return (readyOps() & OP_WRITE) != 0;
}

// 判断该SelectionKey连接就绪事件是否发生. 如果没有监听则总返回false
public final boolean isConnectable() {
    return (readyOps() & OP_CONNECT) != 0;
}

// 判断该SelectionKey接受连接就绪事件是否发生. 如果没有监听则总返回false
public final boolean isAcceptable() {
    return (readyOps() & OP_ACCEPT) != 0;
}


// -- Attachments --
private volatile Object attachment = null;

private static final AtomicReferenceFieldUpdater<SelectionKey,Object>
    attachmentUpdater = AtomicReferenceFieldUpdater.newUpdater(
        SelectionKey.class, Object.class, "attachment"
    );

// 将给定对象当初一个附件与SelectionKey关联. 只能关联一个附件
public final Object attach(Object ob) {
    return attachmentUpdater.getAndSet(this, ob);
}

// 返回当前附件
public final Object attachment() {
    return attachment;
}
```

