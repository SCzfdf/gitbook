# 从字节码和对象头理解synchronized

[死磕Synchronized底层实现----很详细](https://github.com/farmerjohngit/myblog/issues/12)  ([英文版带图, 应该是2个作者都很好](https://www.fatalerrors.org/a/analysis-of-synchronized-jvm-source-code-and-the-significance-of-chatting-lock.html))

[Java中的偏向锁，轻量级锁， 重量级锁解析](https://blog.csdn.net/lengxiao1993/article/details/81568130)

[深入理解Java并发之synchronized实现原理](https://blog.csdn.net/javazejian/article/details/72828483)

​		

synchronized 是JAVA 中的关键字, 用于在多线程环境下保证synchronized 修饰的代码块不被多个线程同时执行

​			

## 字节码实现

[synchronized 在字节码层面上的实现同步的原理](https://blog.csdn.net/qq_41174684/article/details/90442798)

---

同步代码块 使用了**MonitorEnter** 和**MonitorExit** 来实现的, 分别表示代码块进出锁

而同步方法 则使用直接使用synchronized 关键字来表示

​		

**无论是使用同步代码块还是同步方法, JVM中的synchronized 实现都是基于进入和退出Monitor来实现的**, 当代码块内部抛出异常且内部没有处理该异常时, 在异常抛出代码块外部时锁会自动释放

![synchronized置于方法上的字节码](%E4%BB%8E%E5%AD%97%E8%8A%82%E7%A0%81%E5%92%8C%E5%AF%B9%E8%B1%A1%E5%A4%B4%E7%90%86%E8%A7%A3synchronized.assets/image-20201108222406264.png)



![synchronized置于代码块的字节码](%E4%BB%8E%E5%AD%97%E8%8A%82%E7%A0%81%E5%92%8C%E5%AF%B9%E8%B1%A1%E5%A4%B4%E7%90%86%E8%A7%A3synchronized.assets/image-20200312091325362.png)

​		

## 对象头

堆内存中对象在内存中的布局分为三块区域: **对象头, 实例变量, 填充数据**

*   对象头 = 标记部分 + 原始对象引用
    *   **标记部分(Mark Word)**: hashcode + GC分代年龄 + 锁状态标记 + 线程持有锁 + 偏向id + 偏向时间戳(但Mark Word是非固定结构的)
    *   **类型指针(Class Matedata Address)**: 指针, 指向类对象的源数据, 用于确定这个对象是哪个类的实例
*   实例变量 = 类的属性数据. 包括父类的属性数据. 如果是数组还包括数组长度
*   填充数据用于保证整个对象头正好是8字节的倍数, 不是必要存在(JVM要求对象都以8字节为单位对齐)

![堆内存中的对象结构](%E4%BB%8E%E5%AD%97%E8%8A%82%E7%A0%81%E5%92%8C%E5%AF%B9%E8%B1%A1%E5%A4%B4%E7%90%86%E8%A7%A3synchronized.assets/20170603163237166.png)



其中对象头的**标记部分(Mark Word)** 是非固定的结构, 可随着锁状态而改变

其中默认结构是

![MarkWord默认结构](%E4%BB%8E%E5%AD%97%E8%8A%82%E7%A0%81%E5%92%8C%E5%AF%B9%E8%B1%A1%E5%A4%B4%E7%90%86%E8%A7%A3synchronized.assets/image-20200312141845538.png)

>   由于对象头的信息是与对象自身定义的数据没有关系的额外存储成本，因此考虑到JVM的空间效率，Mark Word 被设计成为一个非固定的数据结构，以便存储更多有效的数据，它会根据对象本身的状态复用自己的存储空间

还有其余可变结构如下:

![MarkWord](%E4%BB%8E%E5%AD%97%E8%8A%82%E7%A0%81%E5%92%8C%E5%AF%B9%E8%B1%A1%E5%A4%B4%E7%90%86%E8%A7%A3synchronized.assets/%E5%AF%B9%E8%B1%A1%E5%A4%B4.png)

>   其中轻量级锁和偏向锁是JDK6 才引入的

通过倒数后3位判断出当前MarkWord的状态 就可以判断出其余位储存的是什么

```java
enum {  
    locked_value             = 0, // 0 00 轻量级锁
    unlocked_value           = 1, // 0 01 无锁
    monitor_value            = 2, // 0 10 重量级锁
    marked_value             = 3, // 0 11 gc标志
    biased_lock_pattern      = 5  // 1 01 偏向锁
};
```

