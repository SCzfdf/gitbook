# Lock接口

Java中自带的很多并发工具基本上都是基于Lock, Condition, AQS实现的, 看懂了这几个的底层原理工具的使用会明了很多

​		

>   方法有`throws InterruptedException`的就是中断抛出异常, 没有的就是传递信号
>
>   不管怎样传递没传递 还是用`while (!Thread.currentThread().isInterrupted()) { `比较优雅

```java
/**
 * 以阻塞方式获取锁
 * 如果在获取锁的过程中被中断了, 会将中断信号传递
 */
void lock();
	
/**
 * 获取锁
 * 如果在获取锁的过程中被中断了, 那么在获取到锁后会马上抛出InterruptedException
 */
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

