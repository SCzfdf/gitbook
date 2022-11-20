# Condition接口

[ReentrantLock之Condition源码分析](https://developer.aliyun.com/article/710835)



如果说ReentrantLock是Java语言层面上的synchronized, 

那么Condition就代码层面的监视器(Object.notify), 通过Condition可以实现线程之间的唤醒与挂起

---

condition核心属性

condition在内部维护了一个*单向*链表

```java
private transient Node firstWaiter;

private transient Node lastWaiter;
```

​		

condition暴露的接口

```java
/**
 * 使调用的线程进入阻塞状态(释放占有的锁, 进入阻塞队列)
 */
void await() throws InterruptedException;

/**
 * 和await()区别的是
 * awaitUninterruptibly()执行后调用 thread.interrupt()不会报错
 * await()则是会提示InterruptedException
 */
void awaitUninterruptibly();

/**
 * 设置阻塞时间的await()
 * 返回时间大于零, 表示是被唤醒
 * 小于零表示超时
 */
long awaitNanos(long nanosTimeout) throws InterruptedException;

// 类似awaitNanos(long nanosTimeout) 返回值：被唤醒true，超时false
boolean await(long time, TimeUnit unit) throws InterruptedException;

// 类似await(long time, TimeUnit unit) 
boolean awaitUntil(Date deadline) throws InterruptedException;

// 唤醒指定线程
void signal();

// 唤醒全部线程
void signalAll();
```

从上面暴露接口可以知道2个点

1.  调用await() 前提是获取锁
2.  调用await() 后就会马上释放锁

还有一个点先知道可以帮助理解: await()和signal()本质是将node在AQS和condition2个链表中转移的过程

​		

---

## 源码解析

​		

### await()

```java
// 因为await()需要获取锁才能调用, 所以在真正释放锁前不用考虑线程安全问题
public final void await() throws InterruptedException {
    if (Thread.interrupted())
        throw new InterruptedException(); // 执行前检查中断 

    // 把当前线程加入到condition的等待链表中
    // 在加入前会清除取消状态的节点(waitStatus != condition), 我相信未来的我也一定看得懂的不写了
    Node node = addConditionWaiter();

    // 将线程占用的资源释放掉(重入次数重置为0), 并唤醒AQS链表中的next线程(同样相信未来的我)
    int savedState = fullyRelease(node);
    int interruptMode = 0; // 中断模式

    // isOnSyncQueue() 判断是否在AQS队列中 true:在AQS队列中
    while (!isOnSyncQueue(node)) {
        LockSupport.park(this); // 不在AQS队列中就挂起.第一次肯定是不在的

        // checkInterruptWhileWaiting()看下面
        if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
            break;
    }

    // acquireQueued()熟悉的抢占锁
    if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
        interruptMode = REINTERRUPT;

    // 清理condition链表 搞不懂为什么要清理. 感觉不清理也可以啊...
    if (node.nextWaiter != null)
        unlinkCancelledWaiters();

    // 根据中断模式(这里的中断模式根据是否在signal()前中断决定)决定是抛出异常还是恢复中断
    if (interruptMode != 0)
        reportInterruptAfterWait(interruptMode);
}
```



```java
// 检查中断
private int checkInterruptWhileWaiting(Node node) {
    return Thread.interrupted() ?
        (transferAfterCancelledWait(node) ? 
         		THROW_IE : // signal()之前发生需要抛出异常
         		REINTERRUPT)  // signal()之后发生需要传递中断
        	:
        0; // 0表示没有中断
}

// 只有中断才会调用此方法(看checkInterruptWhileWaiting)
// 这个方法的作用是判断中断是在signal()之前还是之后发生的 true:之前
final boolean transferAfterCancelledWait(Node node) {
    // CAS修改waitStatus成功表示是signal()之前发生的中断. 
    // (signal() 唤醒后会修改状态waitStatus!=condition)
    // 换句话说就是中断在await()时发生就抛出异常, 在线程活动时中断就传递
    // (有可能signal()后不马上释放锁)
    if (compareAndSetWaitStatus(node, Node.CONDITION, 0)) {
        enq(node);
        return true;
    }
    
    // CAS修改waitStatus失败表示已经加入同步队列了. 但可能还没执行玩enq()
    // 这里等待enq()执行完成后在返回false
    // 不然的话await() 下面的while (!isOnSyncQueue(node)) 会再次将线程挂起
    while (!isOnSyncQueue(node))
        Thread.yield();
    return false;
}
```

​			

### signal()

```java
public final void signal() {
    // 判断当前线程是否占有锁
    // 结合transferAfterCancelledWait的理解来看. 用工具异常唤醒的线程是不能调用signal()的
    if (!isHeldExclusively())
        throw new IllegalMonitorStateException();
    
    Node first = firstWaiter;
    if (first != null)
        doSignal(first); // condition队列有node时执行唤醒
}
```



```java
private void doSignal(Node first) {
    do {
        // 将condition队列中first节点(旧frist)的next节点变为frist结点(新frist)
        if ( (firstWaiter = first.nextWaiter) == null)
            // 如果新frist为空 那么尾节点也应该为空(condition队列空了)
            lastWaiter = null;
        
        // 旧frist断开连接
        first.nextWaiter = null;
        
    } while (!transferForSignal(first) &&
             (first = firstWaiter) != null);
}

// 将节点转移到AQS队列
final boolean transferForSignal(Node node) {
    /*
     * 结合await()的 transferAfterCancelledWait()看
     * 如果异常唤醒或者某种原因导致修改失败(参考说是取消, 可是我记得取消只在超时时设置) 返回false
     * 本次唤醒当做失败(需要在唤醒一次)
     */
    if (!compareAndSetWaitStatus(node, Node.CONDITION, 0))
        return false;

    // 加入队列 注意!这里的p是prev节点!	
    Node p = enq(node);
    int ws = p.waitStatus;
    
    // 如果prev节点为CANCELLED则唤醒线程
    // (尝试获取锁+触发shouldParkAfterFailedAcquire()清除取消节点)
    // CAS如果失败表示prev节点为head(head在unlock的时候会CAS自身)
    // CAS如果成功则可以减少一次lock的自旋
    if (ws > 0 || !compareAndSetWaitStatus(p, ws, Node.SIGNAL))
        // 这里的唤醒不是必须的, 因为AQS有自带的唤醒机制
        // 这里唤醒的话让1.代码更快的执行逻辑 2.可以使unlock中去除CANCELLED节点异步执行
        LockSupport.unpark(node.thread);
    return true;
}
```



