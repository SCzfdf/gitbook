# 信号量-Semaphore

信号量也称为令牌桶. 只有拿到令牌的线程才能往下执行. 是一种基于AQS的同步工具

​		

## 构造方法

需要穿入令牌的数量(permits)以及获取令牌的方式是否是公平的

```java
public Semaphore(int permits, boolean fair) {
    sync = fair ? new FairSync(permits) : new NonfairSync(permits);
}
```

​		

## 使用

```java
Semaphore semaphore = new Semaphore(1);

for (int i = 0; i < 5; i++) {
    new Thread(() -> {
        semaphore.acquireUninterruptibly();// 传递信号的中断
        try {
            Thread.sleep(1000L);
            System.out.println(Thread.currentThread().getName());
        } catch (Exception e) {
        } finally {
            semaphore.release(); 
        }
    }).start();
}
```

输出

```txt
Thread-0 // 每隔一秒输出一行
Thread-1
Thread-2
Thread-3
Thread-4
```

​		

## API

```java
// 获取令牌的↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
// 以阻塞方式获取令牌, 如果线程中断则抛出异常 permits表示需要获取的令牌个数
public void acquire() throws InterruptedException;
public void acquire(int permits) throws InterruptedException;

// 以阻塞方式获取令牌, 如果线程中断则传递型号 permits表示需要获取的令牌个数
public void acquireUninterruptibly();
public void acquireUninterruptibly(int permits);

// 尝试获取令牌(非阻塞), permits表示需要获取的令牌个数 后面表示超时时间
public boolean tryAcquire(int permits, long timeout, TimeUnit unit)
        throws InterruptedException;
public boolean tryAcquire(long timeout, TimeUnit unit) throws InterruptedException;
public boolean tryAcquire(int permits);
public boolean tryAcquire();

// 释放令牌的↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
// 释放令牌 permits表示需要获取的令牌个数
public void release();
public void release(int permits);

// 查看信息的↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
// 当前可用的令牌数
public int availablePermits();

// 获取剩余的所有令牌(霸道)
public int drainPermits();

// 获取当前工具是否是非公平的
public boolean isFair();

// 查询是否有线程正在等待获取令牌
public final boolean hasQueuedThreads();

// 获取等待线程的个数
public final int getQueueLength();

// 减少令牌(总数上减少) protected方法外部不能调用, 因为这个方法比较特殊所以也加上来
protected void reducePermits(int reduction);
```

​		

## 有意思的地方

[Semaphore，动态增减信号量](https://www.cnblogs.com/alipayhutu/archive/2012/05/25/2518620.html)

`semaphore`源码不难直接看吧= =

​		

在测试的时候发现了一个有意思的地方

```java
Semaphore semaphore = new Semaphore(1);
// semaphore.release();
semaphore.acquire(2); // 会一直阻塞
```

上面代码第二行不放开则会一直阻塞住, 很好理解: 因为确实没有那么多令牌(其实也挺恐怖的, 一直阻塞着...)

但如果放开第二行的注释, 则可以执行! `semaphore.release()`给令牌桶里永久增加了一个令牌. 

在`Saphore`里还看到了永久去除令牌的API(`reducePermits()`)不过是`protected`的, 外部不能调用(太危险了...)

