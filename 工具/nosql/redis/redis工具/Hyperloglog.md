# Hyperloglog

[Redis HyperLogLog用法简介](https://www.cnblogs.com/mzq123/p/11203969.html)



Hyperloglog 本质是String, 基于Hyperloglog算法

作用是用极小的空间完成统计



## 命令

```shell
# 向hyperloglog添加元素
pfadd {key} {element...}

# 统计key中不重复元素的个数
pfcount {key}

# 合并多个Hyperloglog
pfmerge {destkey} {key...}
```

>   因为HyperLogLog 这个数据结构的发明人 是Philippe Flajolet教授 ，所以用发明人的英文缩写



## 缺点

有误差, 错误率在0.81%

>   HyperLogLog算法一开始就是为了大数据量的统计而发明的，所以很适合那种数据量很大，然后又没要求不能有一点误差的计算，HyperLogLog 提供不精确的去重计数方案，虽然不精确但是也不是非常不精确，标准误差是 0.81%
>
>   而HyperLogLog正好符合这种要求，不会占用太多存储空间，同时性能不错

不能取出某一条数据(没有get命令)



适合用在统计pv和uv

