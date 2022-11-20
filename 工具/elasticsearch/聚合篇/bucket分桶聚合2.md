# bucket分桶聚合2

[官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-aggregations-bucket.html)

​		

* **[Terms](#Terms)**

  词项分桶

* **[Histogram](#Histogram)**

  直方图

* **[Date Histogram](#Date Histogram)**

  日期类型直方图

* **Auot Date Histogram**

  同日期类型直方图, 不过不用指定间隔. 而是指定`buckets`的数量, 让es推测间隔

* **[Range](#Range)**

  基于数值类型, 自定义分桶范围. 类似于直方图

* **Date Range**

  时间类型的自定义分桶

* **Filter**

  过滤分桶. 用法和query差不多. 但优先是用query

  Filter一般用在子聚合的过滤中

* **Filters**

  类似`Filter`, 不过可以设置多个Filter

* **Join**

* **Geo**

* **[Composite](#Composite)**

  组合聚合
  
* **Global Aggs**

  全局统计. `global_aggs`下的聚合会**忽略query查询**的结果

  > 用在需要全局统计和局部(条件)统计一起返回的场景

* **Significant Text**

  关联词热词聚合. 类似于Suggest. 会提示与搜索文本相关的热词

* **Sampler**

  取样器分桶. 每个分片上取少量数据进行分桶聚合

* **Deversified Sampler**

  多样化取样分桶, 类似Sampler



## Terms

**示例**

```json
GET kibana_sample_data_flights/_search
{
  "track_total_hits": true,
  "size": 0,
  "aggs": {
    "per": {
      "terms": {
        "field": "OriginCountry",
        "doc_count_error_upper_bound": true
      },
      //"aggs": { // 可以在分组的基础上在进行一个细分
      //  "dest": {
      //    "terms": {
      //      "field": "DestCountry"
      //    }
      //  }
      }
    }
  }
}

// 返回
{
  "aggregations" : {
    "per" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 10781,
      "buckets" : [
        {
          "key" : "IT",
          "doc_count" : 2278,
          "doc_count_error_upper_bound": 0
        }
      ]
    }
  }
}
```

​		

**常用参数**

* **size**

  需要返回聚合统计数量, 最大值为65535. 

  > 因为集群设置`search.max_buckets`设置就是65535. 不推荐修改, 可以通过修改查询条件做多次聚合

* **shard_size**

  每个分片聚合的数量, 默认`shard_size=size*1.5+10`

* **collect_mode**

  选择词项分桶的模式. 默认`depth_first`

  `depth_first`: 深度优先. 优先用于分桶少的场景(即时子聚合)

  `breadth_first `: 广度优先. 擅长TopX和海量分桶和场景(延时子聚合)

  > 官网的例子: 查询10个最受欢迎的演员及其5个最常见的合作演员.
  >
  > 如果用`depth_first`, 一个演员就会生成n^2个桶. 在进行排序
  >
  > 如果采用`breadth_first`, 就会先找出10个最受欢迎的演员, 然后再找其合作者
  >
  > 简单先说就是`depth_first`先构建一个个完整的桶(最佳演员和合作演员), 再排序, 然后再剪枝(拿前n个)
  >
  > `breadth_first`会先构建一个个不完整的桶(最佳演员), 再排序, 然后再剪枝(拿前n个). 然后再进行下一步

* **missing**

  默认值. 默认情况缺少聚合字段的文档会被忽略, 加了之后会分配到一起

* **execution_hint**

  使用不同的机制执行聚合, 一般不需要配置

  `map`: 直接使用字段值来聚合 (script默认)

  `global_ordinals`: 使用一个全局序号来替换字段值聚合 (keyword默认)

  > 通常情况下`global_ordinals`比`map`快的多

* **min_doc_count**

  过滤最小文档数

* **show_term_doc_count_error**

  是否展示错误文档数(每个分片返回的错误上限).

* **shard_min_doc_count**

  过滤最小文档数(分片级别)

* **order**

  排序. 默认`_count` 倒序. 也可以用`_key`. 或者子对象

* **include**

  有2种用法

  1. 指定返回的数据, 可以一定程度的减少资源消耗

     ```json
     {
       "aggs": {
         "country": {
           "terms": {
             "field": "OriginCountry",
             "include": "IT"
           }
         }
       }
     }
     ```

  2. 使用分区过滤返回值和[delete_by_query](../数据篇/增删改.md#delete_by_query常用参数)的slices类似

     > 但不推荐使用, 因为使用到这个说明数据量已经很大了, 不如用async_search

     ```json
     {
       "aggs": {
         "country": {
           "terms": {
             "field": "OriginCountry",
             "include": {
               "partition": 0,
               "num_partitions": 2
             }
           }
         }
       }
     }
     ```

     

* **exclude**

  除外返回的数据





## Histogram

数据按照直方图的方式分桶聚合.

> es专门设计了histogram字段类型

下图就是基于类别分桶聚合的直方图

![image-20220515131550387](bucket%E5%88%86%E6%A1%B6%E8%81%9A%E5%90%882.assets/image-20220515131550387.png)



**示例**

```json
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "aggs": {
    "histogram": {
      "histogram": {
        "field": "AvgTicketPrice",
        "keyed": true, 
        "interval": 300
      }
    }
  }
}

// 返回
{
  "aggregations" : {
    "histogram" : {
      "buckets" : {
        "0.0" : {
          "key" : 0.0,
          "doc_count" : 1816
        },
        "300.0" : {
          "key" : 300.0,
          "doc_count" : 4115
        },
        "600.0" : {
          "key" : 600.0,
          "doc_count" : 4765
        },
        "900.0" : {
          "key" : 900.0,
          "doc_count" : 2363
        }
      }
    }
}
```



**常用参数**

* **interval**: (integer)

  直方图的分桶间隔

* **min_doc_count**: (integer)

  桶最小文档数, 少于则会被忽略

* **extended_bounds**: (object)

  给直方图填充默认数据. 和`min_doc_count`冲突

  `min`: 最小的数据

  `max`: 最大的数据

  > min: 600, max: 1000. 700的分桶不存在也会返回`doc_count`=0

* **hard_bounds**: (object)

  限制直方图统计的范围

  `min`: 最小的数据

  `max`: 最大的数据

  > min: 600, max: 1000. 直方图只会返回600-1000的数据

* **keyed**: (boolean)

  修改返回方式, 默认false

  ```json
  // true
  {
    "0.0" : {
        "key" : 0.0,
        "doc_count" : 0
      }
  }
  
  // false
  {
    "key" : 0.0,
    "doc_count" : 0
  }
  ```

* **missing**

  默认值.



**对于histogram字段**

直接使用就行

```json
// 创建
PUT metrics_index
{
  "mappings": {
    "properties": {
      "latency_histo": {
        "type": "histogram"
      }
    }
  }
}

PUT metrics_index/_doc/1
{
  "latency_histo" : {
      "values" : [1, 3, 8, 12, 15],
      "counts" : [3, 7, 23,12,  6]
   }
}

PUT metrics_index/_doc/2
{
  "latency_histo" : {
      "values" : [1, 6,  8, 12, 14],
      "counts" : [8, 17, 8, 7,   6]
   }
}

POST /metrics_index/_search?size=0
{
  "aggs": {
    "latency_buckets": {
      "histogram": {
        "field": "latency_histo",
        "interval": 5
      }
    }
  }
}
```



## Date Histogram

和Histogram差不多, 不过针对Date类型做了优化处理

​		

**常用参数**

* ~~interval~~

  不应该使用这个间隔

* **calendar_interval**

  日历间隔. 

  `minute`: 分钟

  `hour`: 小时

  `day`: 天

  `week`: 周. 需要注意的是week默认是周日为第一天

  `month`: 月

  `quarter`: 季度

  `year`: 年

* **fixed_interval**

  固定间隔, 在单位前面可以加数字

  `ms`: 毫秒

  `s`: 秒

  `m`: 分钟

  `d`: 天

* **format**: (string)

  格式化日期格式

* **missing**: (string)

  默认值

* **time_zone**: (string)

  如果入库时不指定时区则默认是UTC时间, 默认时也会以UTC时区进行分桶

  `time_zone: +08:00`



## Range

自定义分桶范围, 类似于直方图. 不过更加灵活

```json
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "aggs": {
    "rangeField": {
      "range": {
        "field": "AvgTicketPrice",
        "ranges": [
          {
            // 定义key, 默认为`500.0-600.0`
            "key": "key",
            // 定义范围
            "from": 500, 
            "to": 600
          },
          {
            "from": 600,
            "to": 800
          },
          { // 范围可以重复
            "from": 700,
            "to": 900
          }
        ]
      }
    }
  }
}
```



**常用参数**

* **keyed**: (boolean)

  修改返回方式, 默认false

  ```json
  // true
  {
    "key" : {
        "from" : 500.0,
        "to" : 600.0,
        "doc_count" : 1520
      }
  }
  
  // false
  {
    "key" : "key",
    "from" : 500.0,
    "to" : 600.0,
    "doc_count" : 1520
  },
  ```

* **script**

  可以使用脚本在统计前做一些操作. 

  当然也可以使用runtime_mappings做到同样的功能(这也是官网建议的)

​		

> Range也可以直接使用histogram字段



## Composite

组合聚合, 为文档的每个组合都创建一个桶

例子: 

```json
{
  "keyword": ["foo", "bar"],
  "number": [23, 65, 76]
}
// 使用keyword和number作为聚合的源字段会产生以下复合桶
{ "keyword": "foo", "number": 23 }
{ "keyword": "foo", "number": 65 }
{ "keyword": "foo", "number": 76 }
{ "keyword": "bar", "number": 23 }
{ "keyword": "bar", "number": 65 }
{ "keyword": "bar", "number": 76 }
```

因此Composite很消耗资源

​		

composite可以聚合以下类型

* term
* histogram
* date histogram
* geo

​		

**示例**

```json
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "track_total_hits": true,
  "aggs": {
    "compositeField": {
      "composite": {
        "size": 1000, 
        "sources": [
          {
            "origin": {
              "terms": {
                "field": "OriginCountry"
              }
            }
          },
          {
            "dest": {
              "terms": {
                "field": "DestCountry"
              }
            }
          }
        ]
      }
    }
  }
}

// 上面的composite等价于下面的多级terms
GET kibana_sample_data_flights/_search
{
  "size": 0,
  "aggs": {
    "origin": {
      "terms": {
        "field": "OriginCountry"
      },
      "aggs": {
        "dest": {
          "terms": {
            "field": "DestCountry"
          }
        }
      }
    }
  }
}
```

​		

**常用参数**

* **after**: (object)

  类似[search_after](../查询篇/简单查询2-分页.md#search_after查询).可以分页展示数据
  
  将查询返回的`after_key`填充就可以实现翻页
  
* **missing_bucket**: (boolean)

  忽略缺少的桶, 默认false(忽略)

* **missing_order**: (enum)

  null储存桶的位置控制

  `default`: 源order控制

  `last`: 放在最后

  `first`: 放在第一


