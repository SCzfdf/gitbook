# Lock_Record和Monitor

`Lock Record`和`Monitor`都是因为`Mark Word`存在空间限制不能保存太多信息而产生的

`Lock Record`是偏向锁和轻量锁专用的, `Monitor`是重量锁专用的

>   不使用`Monitor`大概是因为`Monitor`需要和操作系统打交道比较慢

​		

## Lock Record

`Lock Record`存在于线程的栈中. 用于保存2个数据

1.  锁对象的`Mark Word`(官方称为`Displaced Mark Word`)
2.  执行锁对象的指针



​		

下图右边的就是`Lock Record`

![LockRecord](LockRecord%E5%92%8CMonitor.assets/68747470733a2f2f757365722d676f6c642d63646e2e786974752e696f2f323031382f31312f32382f313637353964643162323461633733643f773d38363926683d33353126663d706e6726733d3331313531)

**上锁流程**(`Lock Record`视角)

1.  在当前线程**找到**一个空闲的`Lock Record`(怎么创建的...不清楚)
2.  将`Lock Record`指向锁对象
3.  尝试修改锁对象的`Mark Word`. 如果成功并且为轻量锁则还需将`锁对象`的`Mark Work`复制到`Lock Record`中

>   偏向锁/轻量锁重入的话会创建多个`Lock Record`. 但`Displaced Mark Word`部分为null
>
>   解锁的话偏向锁只需要将`Lock Record`释放掉就可以了, 轻量级锁还需要将`Displaced Mark Word`还原到对象中去

​		

## Monitor

[Java中的Monitor机制](https://segmentfault.com/a/1190000016417017)

[ObjectMonitor结构](https://baijiahao.baidu.com/s?id=1639857097437674576&wfr=spider&for=pc)

---

1.  监视器, 也称为管程, 是基于操作系统原语`mutex` 和 `semaphore` 上提出的高级原语, 操作系统本身不支持`monitor` , `monitor` 属于编程语言实现的范畴
2.  可以看成是一个同步工具包. 他能保证仅仅有一个进程/线程进入临界区(同步代码块), 并且能管理其他进程/线程在**适当的时候**阻塞和唤醒



​		

### Java 对Monitor 的支持(MonitorObject)

在Java 中万物皆对象, 同时每个对象中都有一个`Monitor`与之关联(所以每个对象都能作为锁对象)

对象和`Monitor`之间的关系存在多种实现方式

1.  `Monitor`同对象一起创建和销毁
2.  当线程试图获取对象锁时生成(懒加载?)
3.  **当对象头中锁标志位为10(重量锁) 时其中指向的就是Monitor 对象的起始地址**



​		

在JVM(HotSpot)中`Monitor`由`ObjectMonitor`实现, 其主要数据结构如下

```c++
ObjectMonitor() {
    _header       = NULL;
    _count        = 0; // 线程获取锁的次数
    _waiters      = 0,
    _recursions   = 0; // 记录锁的重入次数
    _object       = NULL;
    _owner        = NULL; // 指向持有ObjectMonitor对象的线程地址
    _WaitSet      = NULL; // 处于wait状态的线程
    _WaitSetLock  = 0 ;
    _Responsible  = NULL ; // 防止锁搁浅. 就是如果设置的线程调用的是有超时时间的park
    _succ         = NULL ; 
    _cxq          = NULL ; // 竞争列表
    FreeNext      = NULL ;
    _EntryList    = NULL ; // 处于等待锁block状态的线程链表
    _SpinFreq     = 0 ;
    _SpinClock    = 0 ;
    OwnerIsThread = 0 ;
 }
```

**cxq:** cxq是一个被挂起线程等待重新竞争锁的**单向链表**, monitor通过CAS将包装成ObjectWaiter**写入到列表的头部**。为了避免插入和取出元素的竞争，所以Owner会从列表**尾部取元素**。

**EntryList:** EntryList是一个**双向链表**. 当EntryList为空, cxq不为空. Owener会在unlock时, 将cxq中的数据移动到EntryList. 并指定EntryList列表头的第一个线程为**OnDeckThread**。

**OnDeckThread:** 可竞争线程. 如果一个线程被设置为**OnDeck**则表示可进行`tryLock`操作. 若获取成功则表文**owner**, 失败则插回**EntryLock**头部

​		

**简单上锁过程**

每个等待锁的线程都会被封装成ObjectWaiter 对象, 在ObjectMonitor 中流转

1.  想要获取锁的线程进入`_EntryList`
2.  获取到锁(获取到`Monitor`对象), `Monitor`将`_owner` 设置为获取到锁对象的线程地址, `_count` 自加1
3.  线程调用`wait()` 则会进入`_WaitSet`. 将`_owner` 设置为null, `_count`自减1(释放锁)
4.  其他线程调用`notify()` 或`notifyAll` . 唤醒`_WaitSet` 中的某个线程尝试获取锁(在当前线程释放锁之后才会竞争锁)
5.  同步方法执行完成线程/异常被`Monitor`接收到会退出临界区, 将`_owner` 设置为null, `_count` 自减1

```java
synchronized(this){  //进入_EntryList队列  
	doSth();
    this.wait();  //进入_WaitSet队列
}
```

![synchronized上锁过程](LockRecord%E5%92%8CMonitor.assets/16ca34f7e0149c3d.png)

