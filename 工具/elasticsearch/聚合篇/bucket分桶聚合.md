# bucket分桶聚合

[官网Aggregations » Bucket aggregations](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-aggregations-bucket.html)

类似数据库的group

![image-20220514212438520](bucket%E5%88%86%E6%A1%B6%E8%81%9A%E5%90%88.assets/image-20220514212438520.png)



## 分桶聚合过程

因为es是基于列式储存, 只需要加载对于的列, 为每个不同的列创建不同的bucket

和mysql的临时表不是一种逻辑

![image-20220514212541656](bucket%E5%88%86%E6%A1%B6%E8%81%9A%E5%90%88.assets/image-20220514212541656.png)





## 多分片情况下分桶聚合误差

在多分片的情况下, es会在每个分片上都执行一次分桶聚合操作. 如果分片上的数据差异比较大, 可能会造成误差. 如

share1: 1,2,3,4,5,6,1,2,3

share2: 1,2,3,4,5,6,1,2,3

share3: 6,6,6,6

此时如果值取前3个桶, 那么结果应该会是

"6": 4,    "1": 2,     "2" : 2

6的doc_count偏少

> 可以通过观察`doc_count_error_upper_bound`察觉是否有误差(正常应该是0)
>
> `sum_other_doc_count`: 未被聚合的文档数

为了解决这种情况可以增大参数`shard_size`尽可能的减少误差

默认情况下`shard_size=size*1.5+10`











