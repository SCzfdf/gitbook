# String和StringBuilder和StringBuffer

[为什么说String是线程安全的](https://www.cnblogs.com/651434092qq/p/11168608.html)

[String StringBuffer 和 StringBuilder 的区别是什么? String 为什么是不可变的?](https://snailclimb.gitee.io/javaguide/#/docs/java/Java基础知识?id=_12-string-stringbuffer-和-stringbuilder-的区别是什么-string-为什么是不可变的)



## 可变性

String 使用final关键字修饰的数组来保存 字符串`private final char value[];` 所以是Sting保存的字符串对象是不可变的

而StringBuilder和StringBuffer 继承的 AbstractStringBuilder 类中保存字符串的数组`char[] value;` 没有使用final 关键字修饰, 所以是可变的



## 线程安全性

由于String 使用final 关键字修饰保存字符的数组, 所以是线程安全的

StringBuffer 对操作数组的方法加了synchronized 关键字, 所以是线程安全的

StringBuilder 没有对操作数组的方法加了synchronized 关键字, 所以是线程不安全的



## 性能

String 每次操作字符串都会生成一个新字符数组, 速度最慢

StringBuffer 每次操作字符串都会生成锁, 速度比String快

StringBuilder 操作字符串没有锁, 速度最快

