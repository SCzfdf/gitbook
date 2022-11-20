# happens-before原则

[Java 使用 happen-before 规则实现共享变量的同步操作(hb例子有问题)](http://ifeve.com/java-%e4%bd%bf%e7%94%a8-happen-before-%e8%a7%84%e5%88%99%e5%ae%9e%e7%8e%b0%e5%85%b1%e4%ba%ab%e5%8f%98%e9%87%8f%e7%9a%84%e5%90%8c%e6%ad%a5%e6%93%8d%e4%bd%9c/)

---



在JMM中默认定义了一套规则来保证多线程下的有序性和可见性. 即满足该规则的程序片段具有天生的有序性和可见性. 这个规则就是happens-before原则

>   简单的说: 如果2段代码间不存在happens-before关系, 那么在多线程下的有序性可见性都是不确定的

---



happens-before规则:

1.  **程序顺序规则**

    单线程内代码按照编写顺序执行

2.  **监视器锁规则**

    一个锁的解锁happens-before于**随后**对这个锁的加锁

3.  **volatile变量规则**

    对一个volatile变量的写happens-before于**随后**对这个变量的读

4.  **传递性规则(重要)**

    如果A happens-before B, 且B happens-before C. 那么A happens-before C

5.  **start规则**

    线程A中执行`ThreadB.start()`, 那么线程A的`ThreadB.start()` happens-before于线程B中的任意操作

6.  **Join规则**

    线程A中执行`ThreadB.join()`, 那么线程B中的任意操作happens-before于线程A的`ThreadB.start()`(包括`Thread.isAlive() = true`时)

7.  线程中断规则

    线程A执行`ThreadB.interrupt()`happens-before于线程B的`Thread.isInterrupted()`

8.  对象终结规则

    一个对象初始化完成happens-before于它的`finalize()`方法的调用

>   并发编程艺术只有前6个



操作A happens-before于操作B不代表操作AB不会被重排. **仅仅表示操作A的结果对操作B可见**



规则并不是单独使用的, 使用多个规则(尤其是传递性规则)的联用才能正确的判断代码的关系



---



简单例子. 根据start规则输出的一定是2

```java
static int a = 1;

public static void main(String[] args){
  Thread tb = new Thread(() -> {
      System.out.println(a);
  });
  Thread ta = new Thread(() -> {
      a = 2;
      tb.start();
  });

  ta.start();
}
```

