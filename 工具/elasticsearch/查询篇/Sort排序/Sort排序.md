# Sort排序

影响排序的几种方法

* boost调整
* script_score自定义
* sort自定义排序
* rescore重排序



## boost权重调整排序

在普通查询中指定`boost`参数, 为需要重要的字段进行加权

```json
{
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "nameText": {
              "query":  "spid",
              "boost": 2 // 加权
            }
          }
        },
        {
          "range": {
            "inte": {
              "gte": 10,
              "lte": 50,
              "boost": 3 // 加权
            }
          }
        }
      ]
    }
  }
}
```



## script_score自定义脚本分值

[官网Query DSL » Specialized queries » Script score query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-script-score-query.html#query-dsl-script-score-query)

使用script_score可以为返回的结果提供自定义的分数

并且可以从分值上过滤一部分文档**min_score**

```json
GET common-test-001/_search
{
  "track_total_hits": true,
  "query": {
    "script_score": {
      "query": {
        "match": {
          "nameText": {
            "query": "spid",
            "boost": 1
          }
        }
      },
      "script": {
        "source": """ 
        _score*100; // 在原先的score上乘100
        """
      }
    }
  }
}
```

​		

**常用参数**

* **script**: (script)

  得分脚本

* **boost**: (float)

  script_score最终得分为: script * boost. boost默认为1.0

* **min_score**: (float)

  得分低于此的文档将被排除在结果之外

> 还有个Function score的, 官网现在推荐使用script_score替换就不写了



## sort

[官网Search your data » Sort search results](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/sort-search-results.html#sort-search-results)

和boost. script_score不同的是这2者走分值计算逻辑. sort走列式排序

基于doc_value. 对于text需要开启fielddata属性(最好不要)

```json
GET common-test-001/_search
{
  "track_total_hits": true,
  "query": {
    "match_all": {}
  },
  "sort": [
    {
      "_id": {
        "order": "desc"
      }
    }
  ]
}
```



**常用参数**

* **mode**: (enum)

  es支持按数组或多值字段进行排序, 当选择多值时需要选择模式

  `min`: 最低值

  `max`: 最大值

  `sum`: 总值(仅数组数组)

  `avg`: 平均值(仅数组数组)

  `median`: 中位数(仅数组数组)

* **nested**: (object)

  es支持按一个或多个嵌套字段进行排序. 等于将nested转换为数组. 因此mode参数适用

  * **path**: (string) 

    嵌套对象的路径

  * **filter**: (query)

    嵌套对象内部过滤器

  * **max_childer**: (integer)

    需要考虑的最大子文档个数, 默认无限制

  * **nested**: (nested)

    再嵌套一层

* **missing**: (enum)

  当排序字段不存在时的操作,默认`_last`

  `_last`: 放在最后

  `_first`: 放在前面

* **unmapped_type**: (string)

  当索引字段不存在时的容错操作. 

  ```json
  GET /_search
  {
    "sort" : [
      // price不存在时赋予一个临时field类型为long
      { "price" : {"unmapped_type" : "long"} }
    ],
    "query" : {
      "term" : { "product" : "chocolate" }
    }
  }
  ```

* **_geo_distance**: (object)

  允许排序地理位置

  * **distance_type**: (enum)

    如何计算距离. 默认`arc`

    `arc`: 默认

    `plane`: 计算更快, 但长距离和看见两极时不准确

  * **mode**: (enum)

    一个字段有多个地理点时的处理. 升序排序时优先考虑最短距离

    `min`:

    `max`:

    `median`:

    `avg`:

  * `unit`: (string)

    排序时的单位, 默认m(米)

  * `ignore_unmapped`: (boolean)

    未映射字段是否视为默认值. 默认`false`

    `false`: 不视为默认(搜索会报错)

    `true`: 等效于unmapped_type在字段排序中指定一个

* **_script**

  `type`: 类型接受`number`和`string`

  `script`: 脚本

  ```json
  GET /_search
  {
    "query": {
      "term": { "user": "kimchy" }
    },
    "sort": {
      "_script": {
        "type": "number",
        "script": {
          "lang": "painless",
          "source": "doc['field_name'].value * params.factor",
          "params": {
            "factor": 1.1
          }
        },
        "order": "asc"
      }
    }
  }
  ```



## rescore重排序

[官网Search your data » Filter search results](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/filter-search-results.html#rescore)

在已经查询的数据集中通过重新排序二次筛选数据

仅适用于少部分数据, 优点是不需要进行全文检索(因为仅仅是对于查询出得部分数据进行排序)

**rescore和sort冲突**

```json
GET common-test-001/_search
{
  "query": {
    "match_all": {}
  },
  "rescore": {
    "query": {
      "score_mode": "total",
      "rescore_query": {
        "term": {
          "status": {
            "value": "2"
          }
        }
      }
    },
    // 只对前50个进行rescore
    "window_size": 50
  }
}
```

| score_mode | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| `total`    | 添加原始分数和重新评分查询分数。默认。                       |
| `multiply` | 将原始分数乘以重新评分查询分数。对重新评分很有用[`function query`](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-function-score-query.html)。 |
| `avg`      | 平均原始分数和重新评分查询分数。                             |
| `max`      | 取原始分数和重新分数查询分数的最大值。                       |
| `min`      | 取原始分数和重新评分查询分数的最小值。                       |

> 感觉用处有点少

