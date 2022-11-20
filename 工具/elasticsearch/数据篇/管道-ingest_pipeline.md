

# Ingest pipeline

[官网Ingest pipelines](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/ingest.html)

[官网REST APIs » Ingest APIs](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/ingest-apis.html)

数据写入(写入和更新)ES之前**预处理**原始数据. 类似于ETL

Ingest底层就是在创建或者更新前对操作的bulk进行一个修改. 因此对es的负担会很小



![摄取管道图](%E7%AE%A1%E9%81%93-ingest%20pipeline.assets/ingest-process.svg)





## 创建Ingest节点

[官网Set up Elasticsearch » Configuring Elasticsearch » Node](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/modules-node.html)

使用Ingest必须有一个具有ingest角色的节点(默认全部都是). 对于大批量处理的, 最好创建专用的ingest节点

​		

可以通过修改`config/elasticsearch.yml`配置节点角色. 如果不设置es会自动帮忙分配所需角色


如果设置`node.roles`，请确保指定集群所需的每个节点角色。每个集群都需要以下节点角色：

* `master`
* (``data_content`和`data_hot` )或`data`

```yaml
# 创建专门的Ingest节点
node.roles: [ ingest ]
```





## 创建/更新ingest pipeline

[官网REST APIs » Ingest APIs » Create or update pipeline API](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/put-pipeline-api.html)

* `PUT /_ingest/pipeline/<pipeline>`

  ```json
  PUT _ingest/pipeline/common-pipeline-001
  {
    "description": "测试ingesr-pipeline",
    "processors": [
      {
        "set": {
          "field": "ingest.field.{{name}}",
          "value": "(_id)" // 这里用双中括号
        }
      }
    ]
  }
  ```





## 模拟ingest pipeline

```json
POST _ingest/pipeline/common-pipeline-001/_simulate
{
  "docs": [
    // 模拟插入以下数据, 测试结果是否正常
    {
      "_source": {
        "status": "1",
        "name": "testField"
      }
    }
  ]
}
```



### 在Kibana中使用ingest pipeline

路径在Management > Stack Management > Ingest Node Pipelines. 能可视化的管理ingest pipeline



## ingest常用body参数

* `description`: (字符串) ingest的作用描述

* `version`: (整数) ingest的版本号

* `on_failure`: (pipeline对象数组) ingest失败时执行的处理

* `processors`: (pipeline对象数组) ingest正常时执行的处理

  处理器会按照顺序依次执行



## ingest常用处理器

[官网Ingest pipelines » Ingest processor reference(子文档)](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/processors.html)

**官网有很多内置的处理器. 可以做一些脚本很难做到的操作如split**

下面属性大部分处理器都有, 先写后面就不写了

* `description` : (string) 处理器说明
* `if`: 接受一个boolean返回值, 为true时执行处理器
* `ignore_failure`: (boolean) 默认false(处理器异常时停止). 
* `on_failure`: (pipeline对象数组), 处理器异常时执行
* `tag`: (string) 处理器标识符(不知道什么用...)

​		

---

* `set`: 设置一个字段, 如果字段存在就替换

  * `field`: (string) 要插入/更新的字段名称, 支持模板片段(1.`(xx)(双中括号)`, 2.`(xx)三中括号`, 3.`_source.xx`)

  * `value`: 插入的值, 支持模板片段(后续很多都支持, 需要用到在细看, 不另外了)

  * `copy_from`: 输入字段名称, 复制字段下的值

  * `ignore_empty_value`: 是否写入空值. 接受boolean值, 默认false

    `false`: 照常写入

    `true`: value为模板片段并且值为空时不写入

* `drop`: 拒绝本次操作. 

* `remove`: 移除一个字段

  * `field`: (string|array) 字段名称
  * `ignore_missing`: (boolean) 默认false. 测试了几遍没什么区别...

* [`script`](../Script脚本.md): 接受一个脚本进行操作

* `pipeline`: 引用其他pipeline进行处理

  * `name`: (string) 其他pipeline名称

  > 动态的, 引用的pipeline更新后会自动更新

* [`enrich`](#enrich): 能将一个索引的数据匹配到另一个索引中

* ......

> 模板片段可以支持访问元数据, 但如果是自动生产的id则访问不到



## 使用ingest

* 手动指定

  ```json
  // 在数据创建/更新时指定
  POST common-test-001/_doc/3?pipeline=common-pipeline-002
  {
    "status": "2"
  }
  ```

* 默认指定

  ```json
  // 在索引创建时指定default_pipeline参数
  // 也可以在索引模板时指定, 这样都会继承
  PUT common-test-001
  {
    "settings": {
      "default_pipeline": "common-pipeline-001"
    },
    "mappings": {
      "properties": {
        "status": {
          "type": "keyword"
        }
      }
    }
  }
  ```

> 手动指定的优先



## 其余ETL工具

ingest是比较轻量级的数据处理插件, 告警/异常都不能很好处理. 所以如果有需要可以引入其他外部处理平台

* Logstash
* Nifi
* Flink





# enrich

[官网REST APIs » Enrich APIs](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/enrich-apis.html)

能将一个索引的数据匹配到另一个索引中

* `geo_match`: 根据geo匹配
* `match`: 根据term查询匹配
* `range`: 根据range匹配(要对应的字段)
  * 下面子属性为共用属性
  * `indices`: 源索引, 能填多个. 如果填多个就要有相同的`match_field`字段
  * `match_field`: 匹配字段
  * `enrich_fields`: 丰富字段, 要传入另一个索引中的字段
  * `query`: 过滤源索引, 默认`match_all`



示例

```json
// 丰富源索引
POST /text_enrich_policy/_doc
{
    "field1": "001",
    "enrich": "零零壹"
}

// 创建丰富策略
PUT _enrich/policy/my_enrich_policy
{
  "match": {
    "indices": "text_enrich_policy", // 源索引
    "match_field": "field1", // 值将和field1匹配
    "enrich_fields": [ 
      "enrich" // 将enrich传输到其他索引
      ]
  }
}

// 执行丰富策略
POST /_enrich/policy/my_enrich_policy/_execute

// 创建管道引用丰富策略
PUT _ingest/pipeline/my_enrich_policy_pipeling
{
  "processors": [
    {
      "enrich": {
        "policy_name": "my_enrich_policy2",
        "field": "field2", // 将用field2作为匹配值和enrich的field1匹配
        "target_field": "field3" // 如果匹配上将enrich的enrich加入目标索引
      }
    }
  ]
}

// 测试
PUT /text_enrich_policy_001/_doc/1?pipeline=my_enrich_policy_pipeling
{
  "field2": "001"
}

// 查询结果
{
"_source" : {
    "field3" : {
      "field1" : "001", // 会自动加上匹配字段, 应该可以用管道删除掉
      "enrich" : "零零壹"
    },
    "field2" : "001"
  }
}
```

