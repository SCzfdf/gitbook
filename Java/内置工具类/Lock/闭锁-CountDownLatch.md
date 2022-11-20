# 闭锁-CountDownLatch

一个基于AQS的同步工具类. 作用是使一组线程等待另一组线程执行到完毕(计数为0)后在继续执行

​		

## 构造方法

传入次数, 等待线程的个数(不太准确, 具体看api)

```java
public CountDownLatch(int count) {
    if (count < 0) throw new IllegalArgumentException("count < 0");
    this.sync = new Sync(count);
}
```

​		

## 使用

```java
public static void main(String[] args) throws InterruptedException {
    CountDownLatch countDownLatch = new CountDownLatch(1);

    Thread thread = new Thread(() -> {
        Thread.sleep(2000L); // try-cache忽略
        countDownLatch.countDown();
    });
    
    thread.start();
    countDownLatch.await(); // 注释住等到调用countDown()才会执行
    System.out.println("main"); // 这里的main会等待2秒后在输出
}
```

​		

## API

countCownLath暴露的API很简单

```java
// 阻塞线程, 直到计数为0
void await() throws InterruptedException

// 计数-1 计数为0时调用await()阻塞的线程会唤醒. 后续调用await()的线程不会阻塞
void countDown();

// 返回当前计数
long getCount();
```

​		

内部逻辑都很简单就不写了



