# MaterializedView物化视图

将原始数据按照一定规则提前计算并储存起来. 达到高效查询分析的需求



## Rollup

[官网REST APIs » Rollup APIs](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/rollup-apis.html)

数据上卷

基于**时间维度**将原有细粒度的数据按照较粗一点的粒度汇总, 并移除(可以选择)原有数据.

达到节约储存空间加快查询的效果

例: 将网站点击秒级点击次数按照天数汇总

![image-20220517162347106](MaterializedView%E7%89%A9%E5%8C%96%E8%A7%86%E5%9B%BE.assets/image-20220517162347106.png)



### 创建删除Rollup Job

创建: `PUT _rollup/job/<job_id>`

删除: `DELETE _rollup/job/<job_id>` (必须要先停止才能关闭)

​		

#### 示例

```json
// 创建
PUT _rollup/job/my-rollup
{
  "index_pattern": "kibana_sample_data_ecommerce",
  "rollup_index": "kibana_sample_data_ecommerce_rollup",
  "page_size": 5,
  "cron": "* * * * * ? *",
  "groups": {
    "date_histogram": {
      "field": "order_date",
      "calendar_interval": "day"
    },
    "terms": {
      "fields": "geoip.continent_name"
    }
  },
  "metrics": {
    "field": "taxful_total_price",
    "metrics": ["sum"]
  }
}

// 等同于
GET kibana_sample_data_ecommerce/_search
{
  "track_total_hits": true, 
  "size": 0, 
  "aggs": {
    "time": {
      "date_histogram": {
        "field": "order_date",
        "calendar_interval": "day"
      },
      "aggs": {
        "city": {
          "terms": {
            "field": "geoip.continent_name"
          },
          "aggs": {
            "sum_taxful_total_price": {
              "sum": {
                "field": "taxful_total_price"
              }
            }
          }
        }
      }
    }
  }
}
```



#### 常用参数

* **index_pattern**: (string)

  源索引, 支持通配符模式. 但需要注意不能把`rollup_index`也匹配进去

* **rollup_index**: (string)

  上卷数据保存的索引

* **cron**: (corn)

  上卷的执行时间

* **page_size**: (integer)

  汇总索引器在迭代中处理桶储存的结果数. 越大往往越快. 但消耗内存也越多

* **groups**: (object)

  需要聚合的分组字段, 目前支持`date_histogram`、 `histogram`和`terms`

  groups必须有一个`date_histogram`!

  groups中所有的聚合都是同级的, 且不关心顺序

* **metrics**: (object)

  为每个分组收集的指标, 可以不填. 不填就是只关心聚合的文档数, 不关心数值

  `field`: (string)

  收集的字段名称. 必须为数字类型

  `metrics`: (enum array)

  收集字段的方法. 接受`min`、`max`、`sum`、`avg`和 `value_count`

  > 对于avg的二次聚合需要注意下, 应该是不能直接用的



### 获取/修改Rollup Job状态

启动: `POST _rollup/job/<job_id>/_start`

停止: `POST _rollup/job/<job_id>/_stop`

获取job状态: `GET _rollup/job/<job_id>`

获取job数据: `GET _rollup/data/<index>`(这个是源表名称)

> `GET _rollup/data/_all` 查询全部



### 获取数据

`GET <target>/_rollup_search`

直接聚合即可. 如果不清楚表结构可以用

`GET _rollup/data/<index>`查看

​		

`_rollup_search`仅支持部分`_search`. 

并`size`, `highlighter`, `suggestors`, `post_filter`, `profile`, `explain`等不可用

```json
GET kibana_sample_data_ecommerce_rollup/_rollup_search
{
  // 必须为0
  "size": 0, 
  "aggs": {
    "time": {
      "date_histogram": {
        "field": "order_date",
        "calendar_interval": "day"
      },
      "aggs": {
        "city": {
          "terms": {
            "field": "geoip.continent_name"
          },
          "aggs": {
            "sum_taxful_total_price": {
              "sum": {
                "field": "taxful_total_price"
              }
            }
          }
        }
      }
    }
  }
}
```



### 在Kibana中使用

`Stack Management/Rollups Jobs`





## Transform

[官网REST APIs » Transform APIs](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/transform-apis.html)

与Rollup类似, 将数据转换变化. 区别在于不受时间限制

> Rollup的数据会随着时间不断增加, Transform则是固定的

Transform自带Checkpoint机制, 可实时刷新

主要用于海量数据提前预聚合

也可以在Kibana中使用(es nb)

`Stack Management/Transforms`


