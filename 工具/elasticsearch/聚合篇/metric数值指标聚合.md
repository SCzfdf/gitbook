# metric数值指标聚合

[官网Aggregations » Metrics aggregations](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-aggregations-metrics.html#search-aggregations-metrics)

对于float字段可能会造成精度丢失, 最好不要使用, 而是使用scaled_float. 



## 常用聚合函数

单指数值统计

大部分都支持`script`. 可以在聚合时对数据做一些操作

| 函数                            | 作用                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| **sum**                         | 相加                                                         |
| **max**                         | 取最大值                                                     |
| **min**                         | 取最小值                                                     |
| **avg**                         | 取平均值                                                     |
| **count**                       | 出现个数                                                     |
| **stats**                       | 将上面5种方式合并在一起返回                                  |
| **[percentiles](#percentiles)** | 百分位占比(采用tdigest算法, 非精确)                          |
| **percentiles ranks**           | 和percentiles相反. 提供数值查询所在百分位                    |
| **cardinality**                 | 基数统计(基于Hyperloglog算法, 默认3000个桶, 超过4w就是非精确的)<br />1,2,2,3,3,4 => 返回4 |
| **String stats**                | 字符串专用, 统计一些字符串信息(count, maxlength, avglength, entropy) |
| **extended_stats**              | 将很多统计都合并在一起返回                                   |





### percentiles

百分位占比. 不知道怎么解释. 直接看例子

```json
GET kibana_sample_data_ecommerce/_search
{
  "track_total_hits": true,
  "size": 0, 
  "aggs": {
    "per": {
      "percentiles": {
        "field": "taxful_total_price",
        "percents": [
          5,
          95
        ]
      }
    }
  }
}

// 返回
{
  "aggregations" : {
    "per" : {
      "values" : {
        "5.0" : 27.984375,
        "95.0" : 156.0
      }
    }
  }
}

// 验证
GET kibana_sample_data_ecommerce/_search
{
  "query": {
    "range": {
      "taxful_total_price": {
        "gte": 0,
        "lte": 156
      }
    }
  }
}
// 返回hit为4444. 总数据4675
// 4444/4675≈0.95
```

