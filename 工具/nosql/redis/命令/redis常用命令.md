# redis常用命令

[Redis 如何从海量数据中查询出某一个 Key？](https://www.cnblogs.com/vipstone/p/12373734.html)

[Redis的scan命令](http://doc.redisfans.com/key/scan.html)



```shell
# 计算数据库key数量
dbsize

# 计算出数据库所有的key, 支持通配符(keys h* 查出h开头的所有key)(生产master节点不建议用)
keys [pattern]

# 获取key的储存类型
type {key}
```



## 过期时间

```shell
# 设置key的过期时间
expire {key} {seconds}

# 查看key的过期时间(-2代表过期, -1代表没有过期时间)
ttl {key}

# 去掉过期时间
persist {key}
```



## 查询key

```shell
# 第一次迭代使用 0 作为游标， 表示开始一次新的迭代。
# 一套命令SCAN 、 SSCAN 、 HSCAN 和 ZSCAN
# scan 0 match key99* count 1000 (从0开始遍历，匹配key99*，总数是1000)
# {cursor 游标} {pattern key正则} {count limit}
scan {cursor} MATCH {pattern} COUNT {count}
```

