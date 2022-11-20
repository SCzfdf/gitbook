# synchronized的种类与优化

[死磕Synchronized底层实现----很详细](https://github.com/farmerjohngit/myblog/issues/12)  ([英文版带图, 应该是2个作者都很好](https://www.fatalerrors.org/a/analysis-of-synchronized-jvm-source-code-and-the-significance-of-chatting-lock.html))

[Java中的偏向锁，轻量级锁， 重量级锁解析](https://blog.csdn.net/lengxiao1993/article/details/81568130)

[深入理解Java并发之synchronized实现原理](https://blog.csdn.net/javazejian/article/details/72828483)

[锁开销优化以及 CAS 简单说明](https://www.cnblogs.com/cposture/p/10761396.html)

​		

传统的锁(**重量级锁**)依赖于系统的同步函数, 在linux 上使用`mutex`互斥锁, 最底层依赖`futex` . 这些同步函数都涉及到用户态和内核态, 进程的上下文切换成本较高. 

对于加了`synchronized`关键字但**运行时并没有多线程竞争，或两个线程接近于交替执行的情况** 使用传统锁机制无疑效率是会比较低的

​		

JDK1.6之前synchronized 锁只有传统的锁机制, 在之后引入了**偏向锁** 和**轻量级锁** 用于解决在*没有多线程竞争或者没有竞争场景下*使用synchronized 的性能问题

![MarkWord](synchronized%E7%9A%84%E7%A7%8D%E7%B1%BB%E4%B8%8E%E4%BC%98%E5%8C%96.assets/%E5%AF%B9%E8%B1%A1%E5%A4%B4.png)



## 偏向锁

JDK1.6 之后加入的锁, 一种针对加锁操作的优化手段, 主要针对:

**在大多数情况下, 锁总是由同一线程获取的.** 

开启偏向锁:

```properties
-XX:+UseBiasedLocking
-XX:BiasedLockingStartupDelay=0
```

*   优点

    加解锁操作不需要太多额外的消耗, 和非同步方法相比的性能差距也不算太大(仅仅需要一次CAS操作, 之后仅需要解析对象头就行了)

*   缺点

    如果存在线程竞争, 则会带来额外的锁撤销的性能损耗

![image-20200318113430312](synchronized锁.assets/image-20200318113430312.png)

​		

## 轻量级锁

在偏向锁失败后, 并不会马上升级为重量级锁, 还会尝试一种叫 轻量锁 的优化手段, 主要针对:

**大部分同步代码块都是不存在竞争的, 由多个线程交替执行**

*   优点

    对于重量级锁上锁操作没有涉及到系统底层. 一切都是在内存中完成的



![image-20200318113514820](synchronized锁.assets/image-20200318113514820.png)

​		

## 重量级锁

传统意义上的锁, 使用系统原语实现同步, 主要针对:

**同步代码块有多个线程争抢执行**

![重量级锁](synchronized锁.assets/微信截图_20200403100008.png)

​		

## 锁优化

### 锁升/降级

偏向锁: 只有一个线程获取

轻量级锁: 若干个线程交替(无直接冲突)获取

重量级锁: 若干个线程直接竞争锁

![synchronized锁转换](synchronized%E7%9A%84%E7%A7%8D%E7%B1%BB%E4%B8%8E%E4%BC%98%E5%8C%96.assets/synchronized%E9%94%81%E8%BD%AC%E6%8D%A2.png)

​		

### 自旋锁

~~当轻量级锁失败后, 虚拟机为了避免线程真实的在操作系统层面挂起(升级为重量锁) 还会进行一项称为 **自旋** 的优化.~~ 

>   ~~自旋: 循环一定次数检查锁释放被释放(也有说的是空循环)~~

~~主要针对同步代码块很小(执行时间快, 持有锁的时间也会比较短)的情况, 这种情况没必要直接挂起线程, 避免了用户线程和内核切换的消耗~~

~~开启自旋锁~~

```properties
JDK1.6中 开启自旋和设置自旋次数
-XX:+UseSpinning
-XX:PreBlockSpin=10
JDK1.7以上去掉此参数改为由JVM控制的自适应自旋
```

*   ~~优点~~

    ~~在线程竞争不激烈且同步代码块小的情况下, 性能会有较明显的提高. 因为自旋的消耗会小于线程阻塞挂起再唤醒的消耗(挂起+唤醒=2次上下文的切换)~~

*   ~~缺点~~

    ~~在竞争激烈或者同步代码块执行比较耗时的时候自旋的cpu是白白消耗掉的~~

偏向锁和轻量级锁没有自旋. synchronized仅在获取重量级锁发送冲突是存在自旋

​		

### 锁消除

在JIT编译时, JVM会通过上下文的扫描去除不可能存在资源竞争的锁, 节省无意义的获取锁 (如在局部方法中使用StringBuffer 拼接字符串)

​		

### 锁膨胀

将多个连续的加锁、解锁操作连接在一起，扩展成一个范围更大的锁. 目的是防止频繁获得锁 (如在for 循环内部加锁)


