# redis主从复制

[复制](http://redisdoc.com/topic/replication.html)

[Redis及Sentinel配置详解](https://blog.csdn.net/zlfprogram/article/details/74395310)



## 主从复制的基本概念

1. 一个master可以有多个slave
2. 一个slave只能有一个master
3. slave也可以有子节点
4. 数据流向是单向的, 只能由master到slave



## 作用

1. 从节点可以作为主节点的备份
2. 读写分离, 写操作在主节点, 读操作在从节点. 扩充读写性能



## 相关命令

```shell
# 由子节点发起,表示成为ip:port的子节点
slaveof {ip} {port} {password}

# 由子节点发起,表示不做谁的子节点
slaveof no one
```



## 注意

1. 成为子节点会先把自身的全部数据都清空, 然后同步为主节点的数据

    但关系断开时不会清空数据

2. 全量复制非常耗费网络和io资源, 应该尽量规避

    > 使用小主节点, 尽量在低峰时触发

