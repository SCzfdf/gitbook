# Java中的引用

[软引用、弱引用、虚引用-他们的特点及应用场景](https://www.jianshu.com/p/825cca41d962)

[ReferenceQueue的使用](https://www.cnblogs.com/dreamroute/p/5029899.html)

​		

Java中的引用有4种, 分别为:

1.   强引用
2.   软引用
3.   弱引用
4.   虚引用

>   除强引用外, 其余三种引用都有一个对应的`Reference`用于声明, 对于`Reference`对象本身是强引用的
>
>   >   `SoftReference<Object> sr = new SoftReference<>(obj);`
>   >
>   >   `sr`是强引用的. `obj`和`sr`之间是软引用
>
>   这3种引用构造时还能传一个队列作为参数, 目的是当一个对象被GC掉时通过该队列通知到用户(看弱引用)

​				

## 强引用

最普遍的引用, 只要对象还存在一个强引用就不会被回收(当然还要经过可达性分析)

```java
// 直接new出来的对象就是强引用
Object object = new Object();
```

​		

## 软引用

用来保存一些有用但不是必要的对象. 当对象**只包含软引用**且**内存不足时**才会被回收

```java
// 启动是要把jvm调小 -Xms5m -Xmx5m
public static void main(String[] args) throws InterruptedException {
    MyObject obj = new MyObject();
    SoftReference<MyObject> sr = new SoftReference<>(obj);
    
    System.out.println("1: " + sr.get());
    // 将强引用关系移除. 只保留sr和obj的弱引用
    obj = null;
    List<MyObject> list = new ArrayList<>();
    while (sr.get() != null) {
        list.add(new MyObject());
        System.gc();
    }
    System.out.println("end: " + sr.get());

}

static class MyObject {
    // 增大对象大小, 减少等待时间
    private Object object[] = new Object[1000];
}
```



## 弱引用

比软引用还要弱一些. 不必等到内存不足. 只需要**一次GC**即可被回收

```java
private static final ReferenceQueue<Object> queue = new ReferenceQueue<>();

public static void main(String[] args) throws InterruptedException {
    // 传queue用于gc回调
    MyWeakReference sr = new MyWeakReference(new MyObject(1), queue);

    System.out.println("1: " + sr.get() + " poll:" + queue.poll());
    // 因为不必等到内存不足, 只要GC即可触发
    Thread.sleep(1000L);
    System.gc();
    Thread.sleep(1000L);

    // 被回收时queue返回MyWeakReference对象, 但注意的是referent已经为null了!
    MyWeakReference poll = (MyWeakReference) queue.poll();
    System.out.println("end: " + sr.get() + " poll:" + poll.getX());

}

static class MyObject{
    private Integer x;

    public MyObject(Integer x) {
        this.x = x;
    }

    public Integer getX() {
        return x;
    }
}

// WeakReference是保存不了信息的, 因此要一个子类保存信息(类似WeakHashMap)
static class MyWeakReference extends WeakReference<Object>{
    private Integer x;

    public MyWeakReference(Object referent, ReferenceQueue<? super Object> q) {
        super(referent, q);
        this.x = ((MyObject) referent).getX();
    }

    public Integer getX() {
        return x;
    }
}
```



## 虚引用

虚引用也叫幽灵引用. 需引用**不会对对象的生命周期产生影响**. 也无法通过Reference对象来获取关联的对象. 为一个对象设置虚引用关联的唯一目的就是能在这个对象被收集器回收时收到一个系统通知

```java
public static void main(String[] args) throws InterruptedException {
    ReferenceQueue queue = new ReferenceQueue();
    PhantomReference ref = new PhantomReference(new Object(), queue);

    System.gc();

    Reference poll;
    while ((poll = queue.poll()) == null) {}
    System.out.println(ref == poll);
}
```



