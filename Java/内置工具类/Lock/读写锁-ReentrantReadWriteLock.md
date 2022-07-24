# 读写锁-ReentrantReadWriteLock

一种基于AQS的可重入读写锁

​		

## 构造方法

传入true或者false决定内部同步器是**公平还是非公平**

```java
public ReentrantReadWriteLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
    readerLock = new ReadLock(this);
    writerLock = new WriteLock(this);
}
```

默认是非公平锁, 非公平锁的性能要高一些

​		

## 使用

```java
public static void main(String[] args) {
    ReentrantLock lock = new ReentrantLock(false);
    ReentrantReadWriteLock.WriteLock writeLock = reentrantReadWriteLock.writeLock();

    // 在try代码块的上一行获取锁
    writeLock.lock();
    try{
        /** 执行逻辑 */
    }finally {
        // 在finally代码块的第一行释放锁
        writeLock.unlock();
    }
}
```

​		

## API

相比ReentrantLock来说ReentrantReadWriteLock的API更简单些

因为Lock和Condition的方法都在子类(WriteLock, ReadLock)中. ReentrantReadWriteLock的API都是监控相关的

```java
// 获取写锁
ReentrantReadWriteLock.WriteLock writeLock();

// 获取读锁
ReentrantReadWriteLock.ReadLock  readLock();
```

​		

基于Lock接口获取的API

```java
// 以阻塞方式获取锁 如果发生中断则传递信号
void lock();
	
// 以阻塞方式获取锁 如果发生中断则抛出异常
void lockInterruptibly() throws InterruptedException;

// 尝试获取锁, 如果获取成功返回true, 否则返回false
boolean tryLock();

// 尝试获取锁，可设置超时时间，超时返回false
boolean tryLock(long time, TimeUnit unit) throws InterruptedException;

// 释放锁
void unlock();
	
// 返回当前线程的Condition ，可多次调用
Condition newCondition();
```

​		

## 获取共享锁原理

互斥锁获取锁比较简单就不写了

​		

核心属性

```java
// state 存储在AQS中(使用AQS的state)
volatile int state;

// 位运算的准备. 表示使用(state)前16位和后16为储存不同数据
static final int SHARED_SHIFT   = 16;

// 共享锁单位, 因为共享锁用高位存储. 所以state加一个共享锁数量等同于 +65535
// 000000000000000 1 0000000000000000 (65536)
static final int SHARED_UNIT    = (1 << SHARED_SHIFT);
// 最大数量 65535
static final int MAX_COUNT      = (1 << SHARED_SHIFT) - 1;
// 00000000000000001111111111111111
static final int EXCLUSIVE_MASK = (1 << SHARED_SHIFT) - 1;

/** 传入state返回其高16为(共享锁数量)  */
static int sharedCount(int c)    { return c >>> SHARED_SHIFT; }
/** 传入state返回其低16为(互斥锁数量)  */
static int exclusiveCount(int c) { return c & EXCLUSIVE_MASK; }
```

>   这样设计的好处是可以只使用AQS的一个属性(state)就满足共享锁/互斥锁的储存
>
>   并且用起来还挺方便的

```java
// 返回负数代表获取失败 正数成功  	0本次成功但下次失败这里不会返回0
protected final int tryAcquireShared(int unused) {
    Thread current = Thread.currentThread();
    int c = getState();
    // 这里是针对在获取互斥锁的情况下在获取共享锁
    // 先判断是否是互斥锁(state低位!=0)并且是本线程
    if (exclusiveCount(c) != 0 &&
        getExclusiveOwnerThread() != current)
        return -1;// 如果当前存在互斥但不是本线程则获取失败

	// 没有互斥锁的情况走下面逻辑
	
    // 获取共享锁数量
    int r = sharedCount(c);
    if (!readerShouldBlock() &&  // 简单判断当前读锁是否应该阻塞 具体看下面
        r < MAX_COUNT && // 判断共享锁数量是否大于最大数量
        compareAndSetState(c, c + SHARED_UNIT)) { // CAS
        
        // 下面的是增加重入次数的的逻辑
        if (r == 0) {
            firstReader = current;
            firstReaderHoldCount = 1;
        } else if (firstReader == current) {
            firstReaderHoldCount++;
        } else {
            // 使用LocalThread保存重入次数
            HoldCounter rh = cachedHoldCounter;
            if (rh == null || rh.tid != getThreadId(current))
                cachedHoldCounter = rh = readHolds.get();
            else if (rh.count == 0)
                readHolds.set(rh);
            rh.count++;
        }
        return 1;
    }
    
    // 完整版获取共享锁的逻辑
    // 和简单版的大体相同, 增加了自旋和读重入的判断
    return fullTryAcquireShared(current);
}
```

​		

### readerShouldBlock()

>   readerShouldBlock具有一定的局限性, 只能简单判断是否能有资格获取读锁
>
>   一些特殊情况, 比如'A读-B写-A读重入' 这种情况A应该能再次获取读锁, 单使用readerShouldBlock()判断则会返回true(需要阻塞)
>
>   特殊情况就需要使用fullTryAcquireShared()

```java
// 公平模式判断当前线程是否应该阻塞依据: head.next不是当前线程(需要排队)
public final boolean hasQueuedPredecessors() {
    Node t = tail; // Read fields in reverse initialization order
    Node h = head;
    Node s;
    return h != t &&
        ((s = h.next) == null || s.thread != Thread.currentThread());
}

// ----------------------------------------
// 非公平模式判断当前线程是否应该阻塞依据: head.next不为共享模式
final boolean apparentlyFirstQueuedIsExclusive() {
    Node h, s;
    return (h = head) != null &&
        (s = h.next)  != null &&
        !s.isShared()         &&
        s.thread != null;
}
```



