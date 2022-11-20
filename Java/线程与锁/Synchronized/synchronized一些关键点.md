# synchronized一些关键点

[关于synchronized 可能需要了解的关键点](https://blog.csdn.net/javazejian/article/details/72828483#%E5%85%B3%E4%BA%8Esynchronized-%E5%8F%AF%E8%83%BD%E9%9C%80%E8%A6%81%E4%BA%86%E8%A7%A3%E7%9A%84%E5%85%B3%E9%94%AE%E7%82%B9)

[Java 多线程 锁释放问题](https://www.cnblogs.com/fyscn/p/11364065.html)

---



## 可重入性

从互斥锁的设计上来说, 当一个线程请求操作一个由其他线程所持有的临界资源时会阻塞该线程

但如果是线程本身就持有临界资源, 这种情况属于重入锁, 则请求会成功

>   大概是: 
>
>   在ObjectMonitor中
>
>    _recursions   = 0; // 记录锁的重入次数
>
>    _owner          = NULL; // 指向持有ObjectMonitor对象的线程地址
>
>   当owner=本线程 recursions+1







## 类锁

当synchronized 修饰静态方法时锁住的是类对象

当类对象有继承时如果子类没有重写(应该是重写吧, 不过不能加@Override) 该方法通过子类调用的静态方法锁住的是父类的类对象

```java
public class App2 {
    public static void main(String[] args) {
        // 结论: 当son 没有重写自己的sync方法时锁住的都是father 的类对象
        show("未上锁");

        Thread a = new Thread(() -> {
            Father.sync();
        });
        a.start();

        while (!Thread.State.TERMINATED.equals(a.getState())) {
            show("father 上锁中");
        }
        show("a线程消亡 father 解锁");


        Thread b = new Thread(() -> {
            Son.sync();
        });
        b.start();

        while (!Thread.State.TERMINATED.equals(b.getState())) {
            show("son 上锁中");
        }
        show("b线程消亡 son 解锁");
    }

    private static void show(String s) {
        ThreadTool.consoleOutHr(s,
                ClassLayout.parseInstance(Father.class).toPrintable()
                , ClassLayout.parseInstance(Son.class).toPrintable()
        );
    }
}
```

```java
public class Father {
    public static synchronized void sync() {
        ThreadTool.sleep(1000L);
    }
}

public class Son extends Father {
    /**
     * 当son 没有重写自己的sync方法时锁住的都是father 的类对象
     */
    public static synchronized void sync() {
        ThreadTool.sleep(1000L);
    }
}
```



## 线程锁释放

线程锁只有以下3种情况才会释放锁

1.  执行完同步代码块
2.  执行同步代码块的时候抛出异常
3.  执行了wait方法



其余情况都不会释放锁

