# CAS

[Java里的CompareAndSet(CAS)](http://www.blogjava.net/mstar/archive/2013/04/24/398351.html)



---



compareAndSwap(比较并交换)简称CAS. JDK文档对该方法的定义如下:

1.  如果状态值等于预期值, 则以原子方式将同步状设置为给定的更新值. 
2.  此操作具有volatile的内存语义



---



## CAS的实现原理

CAS实现由Unsafe类调用JNI方法实现

```java
public final native boolean compareAndSwapInt(Object o, long offset,
                                              int expected,
                                              int x);
```

​	

其中Unsafe在JVM的实现位置是`\hotspot\src\share\vm\prims\unsafe.cpp`

从下面代码可以找到对应Unsafe_CompareAndSwapInt的实现位置

```C++
// unsafe.cpp:1450
static JNINativeMethod methods_15[] = {
	......;
    {CC"compareAndSwapInt",  CC"("OBJ"J""I""I"")Z",      FN_PTR(Unsafe_CompareAndSwapInt)},
    ......;
}
```

从下面代码可以看到实现跳转到Atomic里了, Atomic是一个类似抽象类真正的实现在Atomic_前缀的类里

```c++
// unsafe.cpp:1185
UNSAFE_ENTRY(jboolean, Unsafe_CompareAndSwapInt(JNIEnv *env, jobject unsafe, jobject obj, jlong offset, jint e, jint x))
  UnsafeWrapper("Unsafe_CompareAndSwapInt");
  oop p = JNIHandles::resolve(obj);
  jint* addr = (jint *) index_oop_from_field_offset_long(p, offset);
  return (jint)(Atomic::cmpxchg(x, addr, e)) == e;
UNSAFE_END
```

​	

找到其中一个实现`hotspot\src\os_cpu\linux_x86\vm\atomic_linux_x86.inline.hpp`

```c++
// atomic_linux_x86.inline.hpp:93
inline jint     Atomic::cmpxchg    (jint     exchange_value, volatile jint*     dest, jint     compare_value) {
  int mp = os::is_MP();
  __asm__ volatile (LOCK_IF_MP(%4) "cmpxchgl %1,(%3)"
                    : "=a" (exchange_value)
                    : "r" (exchange_value), "a" (compare_value), "r" (dest), "r" (mp)
                    : "cc", "memory");
  return exchange_value;
}
```

​	

可以看到最终实现是由 `LOCK_IF_MP()` 加 `cmpxchgl`共同完成的

`LOCK_IF_MP()`的作用是: 

1.  判断是否是多核(单核没必要进行下一步)
2.  发送一个LOCK指令到总线

**CAS之所以和volatile有相同的内存语义在于同样用了LOCK指令**. 回顾下LOCK指令的作用

1.  下一指令独占内存(下一个指令具有原子性)
2.  禁止指令重排
3.  执行完毕后将buffer中的数据提交到主内存

    

`cmpxchgl`是汇编指令, 比较并交换操作数. 

```java
// x86的cmpxchg指定
CPU: I486+
Type of Instruction: User

Instruction: CMPXCHG dest, src

Description: Compares the accumulator with dest. If equal the "dest"
is loaded with "src", otherwise the accumulator is loaded
with "dest".

Flags Affected: AF, CF, OF, PF, SF, ZF

CPU mode: RM,PM,VM,SMM
+++++++++++++++++++++++
Clocks:
CMPXCHG reg, reg 6
CMPXCHG mem, reg 7 (10 if compartion fails)
```

​	

## 使用unsafe

Unsafe类一般是不直接使用的, 一般如果要执行原子加减使用Atomic前缀的类

如果直接使用Unsafe的话可以通过反射的方法

```java
private static Unsafe reflectGetUnsafe() {
    try {
      Field field = Unsafe.class.getDeclaredField("theUnsafe");
      field.setAccessible(true);
      return (Unsafe) field.get(null);
    } catch (Exception e) {
      log.error(e.getMessage(), e);
      return null;
    }
}
```



还有一种是加启动参数, 把需要使用的类注册进bootstrap中

```cmd
-Xbootclasspath/a: ${path}   // 其中path为调用Unsafe相关方法的类所在jar包路径 
```



## CAS存在的问题

主要有3个问题:

1.  **ABA问题**

    内存值原来是A, 经过修改后变为B, 再经过修改后又变回A. 此时是符合修改要求的, 但实际上是有变化不应该修改的

    ABA问题的解决思路是在变量前添加版本号. 如:A-B-A, 改为1A-2B-3A

    JDK1.5后提供`AtomicStampedReference`来解决ABA问题

2.  **自旋开销问题**

    CAS是乐观锁, 适用与读多写少的情况

    如在写多读少的情况会导致其一直自旋给CPU带来非常大的开销

    这时候就应该适用悲观锁而不是CAS

    >   自旋开销:
    >
    >   *   在CPU核数增多的情况下与其他处理器争抢锁的开销
    >   *   频繁CAS修改共享内存中数据占用总线, 影响其他CPU的正常内存操作, 拖慢整体性能

3.  **只能保证一个共享变量的原子操作**

    因为CAS底层是使用LOCK + cmpxchgl指令共同完成的, 所以只能保证对1个变量操作的原子性

    要保证对多个变量原子性可以使用锁或者`AtomicReference`类

    



















