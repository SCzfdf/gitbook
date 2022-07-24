# 可重入锁-ReentrantLock

一种基于AQS的可重入互斥锁

>   看多了感觉知道java中同步工具的套路了. 
>
>   首先是`AQS`. `AQS`是所有同步工具的父类. 但同步工具因为要让用户选择公平或者非公平一般不直接继承, 而是使用内部类的方式定义同步器(一般都是这三个`Sync`, `FairSync`, `NonFairSync`)
>
>   最标准的实现就是`ReentrantLock`.
>
>   一开始我还想着既然那么多同步工具都用到`Sync`为什么不暴露出来...还是太年轻, 都是不能复用的. 能复用的话直接用对应的工具类就好了. 比如`CycleBarrier`就是直接使用`ReentrantLock`

​		

## 构造方法

传入true或者false决定内部同步器是**公平还是非公平**

```java
public ReentrantLock(boolean fair) {
    sync = fair ? new FairSync() : new NonfairSync();
}
```

默认是非公平锁, 非公平锁的性能要高一些

>   非公平锁性能比较高的原因是线程有可能不用休眠就获取到锁(线程休眠和挂起需要耗费资源)

​		

## 使用

```java
public static void main(String[] args) {
    ReentrantLock lock = new ReentrantLock(false);

    // 在try代码块的上一行获取锁
    lock.lock();
    try{
        /* 判断是否中断 & 执行逻辑 */
    }finally {
        // 在finally代码块的第一行释放锁
        lock.unlock();
    }
}
```

>   **同步工具类要么抛出`InterruptedException`, 要么传递中断!!!** 如果没有显式抛异常记得判断下是否中断!
>
>   但是...一般都不会手动中断的hhh

​		

##常用API

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

自身API (大概就是那么多了..看晕我了)

```java
// 查询当前线程重入锁的次数 当前线程没有获取锁则返回0
int getHoldCount();

// 查询本线程是否获得锁
boolean isHeldByCurrentThread();

// 查询锁是否被占用
boolean isLocked();

// 查询锁是否是公平锁 true:公平锁
boolean isFair();

// 查询给定线程是否获取到锁
boolean hasQueuedThread(Thread thread) 

// 查询condition队列是否存在等待线程, 因为队列在不断变化所以不准确, 主要设计用于监视系统状态。
boolean hasWaiters(Condition condition);

// 查询condition队列存在等待线程数量, 因为队列在不断变化所以不准确, 主要设计用于监视系统状态。
int getWaitQueueLength(Condition condition);

// 查询AQS队列是否存在等下线程, 因为队列在不断变化所以不准确, 主要设计用于监视系统状态。
boolean hasQueuedThreads();

// 获取AQS队列(等待队列)的长度, 因为队列在不断变化所以不准确, 主要设计用于监视系统状态。
int getQueueLength();
```



​		

## ReentrantLock 类关系图

![ReentrantLock类关系图](%E5%8F%AF%E9%87%8D%E5%85%A5%E9%94%81-ReentrantLock.assets/image-20210124101254407.png)

