# 内存栅栏-CyclicBarrier

基于ReentrantLock的同步工具. 作用是是一组线程在组内同步(组是虚拟概念)

​		

## 构造方法

传入线程组的个数(parties)和组内线程到达同步点是需要执行的方法(barrierAction)

```java
public CyclicBarrier(int parties, Runnable barrierAction) {
    if (parties <= 0) throw new IllegalArgumentException();
    this.parties = parties; // 组内线程的个数
    this.count = parties; 	// 初始计数
    // 达到同步点需要执行的方法 需要执行完该方法才会唤醒线程!!
    this.barrierCommand = barrierAction; 
}
```



## 使用

```java
CyclicBarrier cyclicBarrier = new CyclicBarrier(3, () -> {
    System.out.println("到达屏障-开始"); // try-cache忽略
    Thread.sleep(2000L);
    System.out.println("到达屏障-结束");
});

for (int i = 0; i < 3; i++) {
	new Thread(() -> {
        System.out.println(Thread.currentThread().getName() + "开始");
        cyclicBarrier.await(1, TimeUnit.SECONDS);
        System.out.println(Thread.currentThread().getName() + "结束");
    }, "Thread-" + i).start();
}
```

输出

```txt
Thread-0开始
Thread-2开始
Thread-1开始
到达屏障-开始 // 注意注意 Runnable执行完才唤醒!!
到达屏障-结束
Thread-1结束
Thread-2结束
Thread-0结束
```

​		

## API

```java
// 阻塞线程. 等待所有线程执行到达同步点才继续执行
int await() throws InterruptedException, BrokenBarrierException;

// 带超时的阻塞. 如果超时组内线程还未到达同步点则抛出异常
int await(long timeout, TimeUnit unit) throw InterruptedException,
                                             BrokenBarrierException,
                                             TimeoutException ;

// 重置屏障
void reset();

// 获取线程组的个数
int getParties();

// 获取还未到达同步点的个数
int getNumberWaiting();

// 检查栅栏是否被破坏
boolean isBroken()
```

​		

## 核心源码

因为是基于ReentrantLock的, 所以源码还好不怎么难

**要了解一个前提`dowait()`是在获得锁的情况下执行的**也是因为这样才简单一些

```java
private int dowait(boolean timed, long nanos)
        throws InterruptedException, BrokenBarrierException,TimeoutException {
    final ReentrantLock lock = this.lock;
    lock.lock(); // 获得锁
    try {
        // Generation内部只有一个boolean, 用于保存本次周期是否正常执行!!
        final Generation g = generation;

        if (g.broken) // 如果异常就直接抛出
            throw new BrokenBarrierException();

        if (Thread.interrupted()) { // 接受到线程中断时 组内线程都要唤醒 & 破坏屏障
            breakBarrier(); // 破坏屏障 & 唤醒组内线程
            throw new InterruptedException();
        }

        int index = --count; // 计数-1 
        if (index == 0) {  // 如果计数 == 0则唤醒组内线程
            boolean ranAction = false;
            try {
                final Runnable command = barrierCommand;
                // 如果构造函数中传了Runnable则会执行
                // 注意! 这里执行dowait()的是组内某个线程(最后一个). 
                if (command != null)
                    command.run();  // Runnable是用run()是在本线程(组内最后一个)执行的
                ranAction = true;
                // 等Runnable执行完之后在去唤醒线程 & 重置count
                nextGeneration();
                return 0;
            } finally {
                if (!ranAction) // 如果Runnable执行异常会在本线程抛出 & breakBarrier()
                    breakBarrier();
            }
        }

        // 计数不为0的时候需要阻塞
        
        for (;;) {
            try {
                if (!timed)
                    trip.await(); // 阻塞
                else if (nanos > 0L)
                    nanos = trip.awaitNanos(nanos); // 带超时的阻塞
            } catch (InterruptedException ie) {
                if (g == generation && ! g.broken) {
                    // 如果屏障还是挂起前的那个(同一个周期) & 没有发生异常, 那么认为是挂起前发生的终端, 直接 breakBarrier() & 抛出异常
                    breakBarrier();
                    throw ie;
                } else {
                    // 如果是其他则认为中断是挂起后发生的, 只需要传递信号
                    Thread.currentThread().interrupt();
                }
            }

            if (g.broken)
                throw new BrokenBarrierException();

            if (g != generation)
                return index;

            if (timed && nanos <= 0L) {
                breakBarrier();
                // 这里如果超时会抛出异常. 但最多只会抛出一个Timeout其余都是BrokenBarrier. 
                // 因为会破坏屏障并唤醒线程 而屏障判断在前面
                throw new TimeoutException();
            }
        }
    } finally {
        lock.unlock();
    }
}
```

​		

挺有意思. 在测试的时候发现2个比较有趣的现象

```java
CyclicBarrier cyclicBarrier = new CyclicBarrier(5, () -> {
    try {
        System.out.println("到达屏障-开始");
        Thread.sleep(2000L);
        System.out.println("到达屏障-结束");
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
});

for (int i = 0; i < 10; i++) {
    new Thread(() -> {
        try {
            System.out.println(Thread.currentThread().getName() + "开始");
            Thread.sleep(2000L); // 更整齐的到达同步点
            cyclicBarrier.await();
            System.out.println(Thread.currentThread().getName() + "结束");
        } catch (Exception e) {
            System.out.println(Thread.currentThread().getName());
            e.printStackTrace();
        }
    }, "Thread-" + i).start();
}
```

上面的代码无论怎样输出都是类似的. 看完源码才知道Runnable是在`Thread-9`中执行的

```txt
.....
Thread-9开始 // 线程名称可能不同
到达屏障-开始
到达屏障-结束
Thread-9结束 // 但最后一个输出开始的线程肯定会在一个屏障后输出结束
到达屏障-开始
到达屏障-结束
Thread-7结束
.....
```

​		

还有一个是打印异常的

将for循环次数减少到3. `cyclicBarrier.await();`改为`cyclicBarrier.await(1, TimeUnit.SECONDS);`即可复现

具体原因源码里有注释

```txt
java.util.concurrent.TimeoutException // timeout
	at java.util.concurrent.CyclicBarrier.dowait(CyclicBarrier.java:257)
	at java.util.concurrent.CyclicBarrier.await(CyclicBarrier.java:435)
	at com.sczfdf.ReentrantLockDemo.App.lambda$main$1(App.java:31)
	at java.lang.Thread.run(Thread.java:748)
java.util.concurrent.BrokenBarrierException // BrokenBarrier
	at java.util.concurrent.CyclicBarrier.dowait(CyclicBarrier.java:250)
	at java.util.concurrent.CyclicBarrier.await(CyclicBarrier.java:435)
	at com.sczfdf.ReentrantLockDemo.App.lambda$main$1(App.java:31)
	at java.lang.Thread.run(Thread.java:748)
java.util.concurrent.BrokenBarrierException // BrokenBarrier
	at java.util.concurrent.CyclicBarrier.dowait(CyclicBarrier.java:250)
	at java.util.concurrent.CyclicBarrier.await(CyclicBarrier.java:435)
	at com.sczfdf.ReentrantLockDemo.App.lambda$main$1(App.java:31)
	at java.lang.Thread.run(Thread.java:748)


```



