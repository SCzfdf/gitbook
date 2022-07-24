# pipeline二次聚合

[官网Aggregations » Pipeline aggregations](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-aggregations-pipeline.html#search-aggregations-pipeline)

[elasticsearc使用指南之ES管道聚合(Pipeline Aggregation)](https://blog.csdn.net/prestigeding/article/details/88650584)

​		

将一个个聚合操作组合成管道, 上一个的聚合操作结果是下一个的输入

pipeline和Java的Stream.peek类似可以从一系列的数据中额外获取结果. 

pipeline只能处理数值类型

![image-20220515171257476](pipeline%E4%BA%8C%E6%AC%A1%E8%81%9A%E5%90%88.assets/image-20220515171257476.png)





## pipeline的类型

* **Parent**

  家长类型. 桶是有先后顺序的, 上一个桶的结果为下一个桶计算的入参

  | 分桶Key | 分桶值 | 求累计和     |
  | ------- | ------ | ------------ |
  | key1    | 10     | 10           |
  | key2    | 20     | 30 = 10 + 20 |
  | key3    | 30     | 60 = 30 + 30 |

* **Sibling**

  兄弟类型. 桶之间的关系是平行的

  | 分桶key | 分桶值 | 求最大值 |
  | ------- | ------ | -------- |
  | key1    | 10     |          |
  | key2    | 20     |          |
  | key3    | 30     |          |
  |         |        | 30       |



## buckets_path语法

buckets_path用于指定计算桶聚合的位置

```properties
AGG_SEPARATOR       =  `>` ;
METRIC_SEPARATOR    =  `.` ;
AGG_NAME            =  <the name of the aggregation> ;
METRIC              =  <the name of the metric (in case of multi-value metrics aggregation)> ;
MULTIBUCKET_KEY     =  `[<KEY_NAME>]`
PATH                =  <AGG_NAME><MULTIBUCKET_KEY>? (<AGG_SEPARATOR>, <AGG_NAME> )* ( <METRIC_SEPARATOR>, <METRIC> ) ;	
```

示例: `my_bucket>my_stats.avg`需要聚合`my_bucket`聚合下的`my_stats`聚合中的`avg`值



## pipeline使用

语法如下:

```json
{
  "aggs": {
    "<自定义aggs名称>": {},
    "<自定义pipeline名称>": {
      "<管道名称>": {
          "buckets_path": <buckets_path>
      }
    }
  }
}
```

​		

### 通用参数

* **gap_policy**: (enum)

  对空桶的处理. 默认`skip`

  `skip`:  跳过

  `insert_zeros`: 用0替换

  `keep_values`: 如果指标存在默认值则使用, 否则跳过

* **format**: (String)

  格式化. 不止针对日期, 还针对浮点型(保留n位小数)



### Sibling示例

```json
GET kibana_sample_data_flights/_search
{
  "track_total_hits": true,
  "size": 0,
  "aggs": {
    "Aggs1": {
      "terms": {
        "field": "DestCountry"
      },
      "aggs": {
        "Aggs2": {
          "terms": {
            "field": "DestCityName"
          },
          "aggs": {
            "Aggs3": {
              "stats": {
                "field": "FlightTimeMin"
              }
            }
          }
        },
        "p2": {
          "max_bucket": {
            "buckets_path": "Aggs2>Aggs3.sum"
          }
        }
      }
    },
    "p1": {
      "max_bucket": {
        "buckets_path": "Aggs1>p2"
      }
    }
  }
}
```

返回

```json
{
  "aggregations" : {
    "Aggs1" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 10688,
      "buckets" : [
        {
          "key" : "IT",
          "doc_count" : 2371,
          "Aggs2" : {
            "doc_count_error_upper_bound" : 0,
            "sum_other_doc_count" : 1981,
            "buckets" : [
              {
                "key" : "Verona",
                "doc_count" : 390,
                "Aggs3" : {
                  "count" : 390,
                  "min" : 0.0,
                  "max" : 1797.1661376953125,
                  "avg" : 391.001085407306,
                  "sum" : 152490.42330884933
                }
              }
            ]
          },
          "p2" : {
            "value" : 152490.42330884933,
            "keys" : [
              "Verona"
            ]
          }
        }
      ]
    },
    "p1" : {
      "value" : 152490.42330884933,
      "keys" : [
        "IT"
      ]
    }
  }
}
```

示例中`p1`的buckets_path不能直接使用`Aggs1>Aggs2>Aggs3.sum`. 找了挺多网站都没写为什么...

猜测是`max_bucket`为`Sibling`类型的聚合, 只能支持一个聚合的桶参与计算. 而正常写法桶就有2层了. 

而如果用`Aggs1>p2` 相当于是直接计算一层桶



### Parent示例

```json
GET kibana_sample_data_ecommerce/_search
{
  "track_total_hits": true,
  "size": 0,
  "aggs": {
    "Aggs1": {
      "terms": {
        "field": "customer_id"
      },
      "aggs": {
        "Aggs2": {
          "date_histogram": {
            "field": "order_date",
            "calendar_interval": "month"
          },
          "aggs": {
            "Aggs3": {
              "sum": {
                "field": "taxful_total_price"
              }
            },
            "p1": {
              // 累计和
              "cumulative_sum": {
                "buckets_path": "Aggs3"
              }
            }
          }
        }
      }
    }
  }
}
```

返回

```json
{
  "aggregations" : {
    "Aggs1" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 4327,
      "buckets" : [
        {
          "key" : "27",
          "doc_count" : 348,
          "Aggs2" : {
            "buckets" : [
              {
                "key_as_string" : "2022-04-01T00:00:00.000Z",
                "key" : 1648771200000,
                "doc_count" : 37,
                "Aggs3" : {
                  "value" : 3228.09375
                },
                "p1" : {
                  "value" : 3228.09375
                }
              },
              {
                "key_as_string" : "2022-05-01T00:00:00.000Z",
                "key" : 1651363200000,
                "doc_count" : 311,
                "Aggs3" : {
                  "value" : 27559.390625
                },
                "p1" : {
                  "value" : 30787.484375
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

注意p1的值第一个桶为`3228.09375`第二个桶为`30787.484375`



## 常用pipeline类型

| Sibling Pipeline      | 作用                          |
| --------------------- | ----------------------------- |
| max_bucket            | 求最大的值                    |
| min_bucket            | 求最小的值                    |
| avg_bucket            | 求平均值                      |
| sum_bucket            | 求汇总值                      |
| stats_bucket          | 组合常规聚合统计(上面4种)     |
| extended_stats_bucket | 组合多种拓展聚合统计          |
| percentiles_bucket    | 统计出桶的百分位占比          |
| serial_diff           | 基于2个分桶之间, 计算前后差值 |

​		

| Parent Pipeline        | 作用                               |
| ---------------------- | ---------------------------------- |
| cumulative_sum         | 累计桶的值                         |
| cumulative_cardinality | 累计基数                           |
| bucket_sort            | 对桶进行排序, 并可以取TopX         |
| moving_fn              | 移动窗口统计. 可以动态统计TopX个桶 |
| moving_percentiles     | 针对百分位的移动窗口统计.          |
| derivative             | 计算桶前后的差值, 延伸值           |
| bucket_selector        | 对桶进行过滤, 类似sql中的having    |
| bucket_script          | 可以使用脚本灵活计算               |

