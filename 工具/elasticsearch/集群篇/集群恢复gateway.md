# 集群恢复gateway

[官网Set up Elasticsearch » Configuring Elasticsearch » Local gateway settings](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/modules-gateway.html#modules-gateway)

es可以随意增加删除节点. **索引的分片和副本会自动转移到其他分片**(尽量的平衡). 这就是es集群的弹性能力

但在集群启动时由于节点不是统一时间启动的, 所以可以会造成索引数据大规模漂移

​		

为了避免可以在启动时配置gateway参数

* **gateway.expected_data_nodes**: (integer)

  集群中预期的数据节点数. 默认`0`(集群数据量大且节点多时很容易漂移)

  只要集群中有n个或以上节点集群就开始恢复

* **gateway.recover_after_time**: (time)

  集群恢复等待超时, 默认`5m`

  在规定时间内集群没达到预期数目但达到`gateway.recover_after_data_nodes`的数目也会自动恢复

* **gateway.recover_after_data_nodes**: (integer)

  集群最小数据节点数, 没有默认值没配置就会报错

gateway是static参数, 需要在elasticsearch.yml中配置, 且只有在整个集群重新启动时才会生效. 所以最好在集群设计之初就加入

> 看源码是集群改变时就会调用这几个参数. 



​		


