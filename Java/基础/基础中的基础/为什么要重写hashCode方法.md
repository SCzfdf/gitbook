# 为什么要重写hashCode()

[hashcode-与equals](https://snailclimb.gitee.io/javaguide/#/docs/java/Java%E5%9F%BA%E7%A1%80%E7%9F%A5%E8%AF%86?id=_27-hashcode-%e4%b8%8e-equals-%e9%87%8d%e8%a6%81)

[什么是hash](https://www.zhihu.com/question/26762707/answer/40119521)

[必须掌握的hashcode()方法](https://blog.csdn.net/dome_/article/details/92084823)



## 什么是hsah

hash（散列、杂凑）函数，是将任意长度的数据映射到有限长度的域上

直观解释起来，就是对一串数据m进行杂糅，输出另一段固定长度的数据h，作为这段数据的特征（指纹）。



hash函数获取的hash值有几个特征

1.  从hash值不可以反向推导出原始的数据
2.  输入数据的微小变化会得到完全不同的hash值，相同的数据会得到相同的值
3.  hash算法的冲突概率要小
4.  执行高效. 长的文本也能快速地计算出哈希值



## 什么是hashCode()

hashCode() 就是java默认实现的(在Object里) 用于获取对象hashCode 的方法



## equal() 和hashCode() 的关系

其实他们没什么关系

主要是java中**散列存储结构** (HashMap, HashSet, HashTable) 用的比较多. 而这些散列存储结构需要用到HashCode(快速获取, 快速查重)

由于Hash算法的优秀特征, 对象的HashCode用于粗略比较对象是否相等, equal() 用于精确相等

>   由于hash碰撞, 所以2个不同的对象也可能有相同的hashCode

>   1.  如果两个对象equals相等，那么这两个对象的HashCode一定也相同
>   2.  如果HashCode 相同. 不代表两个对象也相同

​		

