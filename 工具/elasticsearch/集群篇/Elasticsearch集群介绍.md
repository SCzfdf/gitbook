# Elasticsearch集群介绍

使用经典Master-Standby模型

必须有一个活跃的Master节点, 多个Standby节点. Master挂掉之后会从Standby中选举

集群元数据信息都会存在Master节点然后分发到Standby节点. 元数据信息包括

* 集群节点信息
* 集群索引信息
* 集群设置信息等

所以当Master节点挂掉之后只要重新选取一个就可以了. 

> 集群节点数量不宜过大, 正常30~40. 大规模无需超过100

![image-20220519133117869](Elasticsearch%E9%9B%86%E7%BE%A4%E4%BB%8B%E7%BB%8D.assets/image-20220519133117869.png)



## ES的弹性能力与集群选举

集群形成时, Raft算法会记住集群的数量信息. 只要集群可用节点数在半数以上. 则集群可用. 并且可以随意增加删除节点. **索引的分片和副本会自动转移到其他分片**(尽量的平衡). 这就是es集群的弹性能力

当集群首次组建时需要指定`cluster.initial_master_nodes`, 如果指定不当可能会导致集群组建失败

在Master节点宕机时. Raft算法只要有半数以上的节点认可节点成为Master节点即可

因此需要确保一个ES集群最少需要配置3个节点, 并确保其中2个节点可用

如果有偶数节点参与投票, 那么es集群会将一个节点排除在外. 确保集群为奇数



## 集群容错性

集群节点之间由于网络或者进程影响问题, 存在一定延迟通讯

通过设置[集群容错性](./集群恢复gateway.md), 避免集群过于敏感造成集群动荡

> 需要避免集群节点频繁增加与移除. 可以通过设置超时时间来延缓网络造成的动荡

ES可以支持跨版本集群, 但仍**需要避免**. ES跨版本集群一般用在集群升级上



## 集群节点增加/移除

1. 链接其中任意节点
2. 从Master节点获取集群信息
3. 从Master节点获取集群meta信息
3. 新增节点数据重平衡

> 可以利用这个特性来迁移集群. 
>
> 通过在新机器加入集群, 然后关闭旧集群的节点. 逐步迁移数据

![image-20220519145830135](Elasticsearch%E9%9B%86%E7%BE%A4%E4%BB%8B%E7%BB%8D.assets/image-20220519145830135.png)





## 集群设置

* 静态设置

  在es/config/[elasticsearch.yml](../Elasticsearch介绍.md/#elasticsearch.yml)

* 动态设置

  查看: `GET _cluster/settings`

  设置: `PUT _cluster/settings`

  其中`persistent`为持续设置, 重启有效`transient`为临时设置

> 优先级为`transient` > `persistent` > elasticsearch.yml > default

