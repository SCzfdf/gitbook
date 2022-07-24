# JMM内存屏障

内存屏障(Memory barrier): 是一类同步指令. 作用是:

*   禁止指令重排
*   将缓冲区的数据写回到主内存



---



下面是内存屏障的分类

<img src="%E5%86%85%E5%AD%98%E5%B1%8F%E9%9A%9C.assets/16589fc79fe1f5d5" alt="内存屏障指令" style="zoom: 60%;" />

StoreLoad是全能的通用型屏障, 在处理器中都会支持

