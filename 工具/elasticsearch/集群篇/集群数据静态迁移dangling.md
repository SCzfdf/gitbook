# 集群数据静态迁移dangling

当一个节点加入集群时, 发现本地data目录中的分片数据在集群中尚不存在. 集群就会认为这些分片数据属于`dangling`状态. 可以使用dangling API列出, 导入, 或者删除dangling分片

> 使用dangling API可以将一个集群中的索引加入到另一个集群中, 做一个数据的静态迁移!

​		

* `GET /_dangling`: 列出
* `POST /_dangling/<index-uuid>?accept_data_loss=true`: 将分片加入集群
* `DELETE /_dangling/<index-uuid>?accept_data_loss=true`: 删除分片

​		

**参数**(加入和删除公用)

* **accept_data_loss**: (boolean)

  必须设置true才能执行操作. 

  导入时因为es集群不知道数据来源, 无法确认哪些分片上的数据是最新版本, 哪些是陈旧版本(无法确认当时的Master节点). 所以导入可能会造成数据丢失(accept data loss)

  删除就必须accept data loss....

* **master_timeout**: (time)

  链接Master的超时时间

* **timeout**: (time)

  等待响应超时时间

