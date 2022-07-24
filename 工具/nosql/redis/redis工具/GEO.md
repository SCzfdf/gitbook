# GEO

redis中用于储存计算经纬度的工具

实际上是使用zset

> 没有删除api 使用zrem key member

> **工作原理**
>
> sorted set使用一种称为[Geohash](https://en.wikipedia.org/wiki/Geohash)的技术进行填充。经度和纬度的位是交错的，以形成一个独特的52位整数. 我们知道，一个sorted set 的double score可以代表一个52位的整数，而不会失去精度。
>
> 这种格式允许半径查询检查的1 + 8个领域需要覆盖整个半径，并丢弃元素以外的半径。通过计算该区域的范围，通过计算所涵盖的范围，从不太重要的部分的排序集的得分，并计算得分范围为每个区域的sorted set中的查询。



## 关于误差

使用的距离公式是Haversine公式。

这个公式仅适用于地球，而不是一个完美的球体。当在社交网站和其他大多数需要查询半径的应用中使用时，这些偏差都不算问题。但是，在最坏的情况下的偏差可能是 **0.5%** ，所以一些地理位置很关键的应用还是需要谨慎考虑。



## 命令

```shell
# 增加地理位置 longitude(经度)在±180之间, latitude(纬度)在-85.05112878到85.05112878之间
# 例:geoadd cities 116.28 39.55 beijing
# 因为使用Geohash所以在转变为52位的时候会产生一些误差
geoadd {key longitude latitude member} [longitude latitude member...]

# 获取member对应的地理位置信息, 这是获取上面存入的beijing的到的
# 1) 1) "116.28000229597092"
#    2) "39.550000724547083"
geopos {key} {member...}

# 返回一个或多个位置元素的 Geohash 表示
 geohash {key} {member...}

# 计算两地距离
# unit 距离单位. m(米) km(千米) mi(英里) ft(尺)
grodist {key} {member1} {member2} [unit]

# 获取指定范围内的地理信息位置集合
groradius {key} {longitude} {latitude} {radius+unit} [WITHCOORD] [WITHDIST] [WITHHASH] [COUNT count]

# 获取指定member范围内的其他member
GEORADIUSBYMEMBER {key} {member1} {radius+unit} [WITHCOORD] [WITHDIST] [WITHHASH] [COUNT count] [asc|desc] [store key] [storedist key]

# GEORADIUSBYMEMBER和groradius区别是一个需要member一个需要经纬度
# WITHCOORD 返回结果中包含经纬度
# WITHDIST 返回结果中包含距离中心点的位置
# WITHHASH 返回结果中包含geohash
# COUNT 指定返回结果个数
# asc|desc 排序
# store key 将返回结果的地理位置信息保存到指定key
# storedist key  将返回结果距离中心节点的距离信息保存到指定key
```



## geohash

eohash是一种算法思想。geohash就是把二维的坐标点，用一串字符串表示，通过比较geohash值得相似程度来查找附近目标要素

> 通常我们使用一对(x,y)坐标来表示一个点的坐标。
>
> 在地图上会有很多点、线、面等空间要素。
>
> 如果我们要查询在自己位置附近1km以内的公交站。传统的想法是遍历所有的公交站，获取距离在1km以内的结果。然而这种方法太耗费时间和性能，没次都要计算点之间的距离。

用redis 返回的geohash可以在java中引入类库计算

