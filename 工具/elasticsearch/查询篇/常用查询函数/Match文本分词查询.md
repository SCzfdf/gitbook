# Match文本分词查询

能够搜索基于倒排索引后的文本(TEXT)字段. 全文文本查询是非精确的

match可以细分为4种

* **match**

  普通文本匹配

* **match_bool_prefix**

  查询结果最后一个分词为前缀匹配

* **match_phase**

  短语匹配

* **match_phase_prefix**

  短语匹配, 最后一个词为前缀匹配.

* **multi**

  能一次匹配多个字段, 并通过对字段加权(`field^2`)和选择算分方式(`type`)灵活控制得分



## 文档分值计算来源

```json
// 查看id为sJfNooABjfGFDBEgHpit的数据在这个查询语句中的得分来源
// 后面有需要再细看吧, 大概是通过计算TF-IDF算出来的
GET common-test-001/_explain/sJfNooABjfGFDBEgHpit
{
  "query": {
    "match_phrase": {
      "name" : {
        "query": "my name",
        "slop": 1
      }  
    }
  }
}
```





## 倒排索引

正排索引储存文档的结构

![img](%E6%96%87%E6%9C%AC%E5%88%86%E8%AF%8D%E6%9F%A5%E8%AF%A2.assets/v2-d50ffd4b3bc38e25e281fea9e07e14e6_720w.jpg)

倒排索引储存文档的结构

![img](%E6%96%87%E6%9C%AC%E5%88%86%E8%AF%8D%E6%9F%A5%E8%AF%A2.assets/v2-0e77a230cbce4cd3c8b8e121bb211518_720w.jpg)



## analyze API(测试分词)

```json
POST _analyze
{
  "text": [
    "hello word, 我知道你是谁"
  ],
  "analyzer": "standard"
}

{
  "tokens" : [
    // 下面的就是倒排索引需要入库的信息
    {
      "token" : "hello", // 分出来的词倒排索引的key
      "start_offset" : 0, // 文档的起始下标
      "end_offset" : 5,  // 文档的接受下标
      "type" : "<ALPHANUM>",
      "position" : 0 // 文档的第几个词
    }
    ....
}
```



## match文本匹配

match查询是执行全文搜索的标准查询, 包括模糊查询选项

接受文本, 数字, 日期, boolean值匹配的文档. 在匹配之前会分析提供的文本

​		

示例

```json
GET /_search
{
  "query": {
    "match": {
      "message.keyword": {
        "query": "this is a test"
      }
    }
  }
}
```

关于`message.keyword`. 可以让text字段不分词. 也即是`message`=`this is a test`才能匹配

​		

**match常用参数**

* **query**: (string | boolean | integer | date)

  需要进行检索的文本, 在检索前会进行语法分词.

  ```json
  GET kibana_sample_data_flights_match/_search
  {
    "query": {
      "match": {
        "Carrier": {
          // query会被分成`ES-Air`和`JetBeats`. 和用and单独查询2个词的结果时一样的
          "query": "ES-Air JetBeats"
        }
      }
    }
  }
  ```

* **analyzer**: (string)

  替换分词器, 默认分词器为`standard`. [内置分词器](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/analysis-analyzers.html)

* **auto_generate_synonyms_phrase_query**: (boolean)

  为同义词创建匹配短语查询, 默认true. 中文用的比较少. 官网例子如下

  `ny city`会被转换成`(ny OR (new AND york)) city`

  > ny ≈ new york

* **[fuzziness](./通用属性/fuzziness模糊.md)**: (string)

  纠错搜索

* **operator**: (boolean)

  解释query中的分词关系. 默认or

  `OR`: `capital of Hungary`被解释为`capital OR of OR Hungary`

  `AND`: 被解释为`capital AND of AND Hungary`

  > 测试的时候在query中直接加AND是没用的, 但OR有用. 很奇怪

* **minimum_should_match**: (string)

  [官网Query DSL » minimum_should_match parameter](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-minimum-should-match.html)

  指定文档需要最少匹配几个分词

  * `正整数`: 必须满足n个分词

  * `负整数`: 最少满足`MIN(query分词数-minimum_should_match, 1)`个分词
  
    > `query = 'San Francisco International'` 
    >
    > -1的话需要满足任意2个.  -2的话需要满足任意1个. 但-3以上最少也要满足一个

  * `百分比`: 满足百分之几个分词. 向下取整. 用于查询不明确的情况

  * `负百分比`: 同负整数

  * `组合`/`多组合`: 按query的分词数量决定策略
  
    ```text
    minimum_should_match: "2<-25% 9<-3"
    9 < 分词数量		-> minimum_should_match: -3
    2 < 分词数量 < 9	-> minimum_should_match: -25
    分词数量 < 2		-> minimum_should_match: 2
    ```
  
    
  
  

## match_bool_prefix前缀匹配

集成了match和bool. 

match_bool_prefix中的message也会分词. 并且只有最后一个分词才有前缀的功能. 如下示例

```json
GET /_search
{
  "query": {
    "match_bool_prefix" : {
      // 只有f才有前缀匹配的功能
      "message" : "quick brown f"
    }
  }
}
```

示例等同于

```json
GET /_search
{
  "query": {
    "bool" : {
      "should": [
        { "term": { "message": "quick" }},
        { "term": { "message": "brown" }},
        // 只有f才有前缀匹配的功能
        { "prefix": { "message": "f"}}
      ]
    }
  }
}
```





## match_phase短语匹配

和match不同的是, match的分词是无序的, match_phase的必须是全匹配并且是有序的, 

```json
GET common-test-001/_search
{
  "query": {
    "match_phrase": {
      "name" : {
        // 注意顺序不能错
        "query": "my name",
        // 允许短语中少1个单词
        "slop": 1
      }
    }
  }
}

// 结果
{
  "_source" : {
    "@timestamp" : "2022-02-02",
    "name" : "my name Francisco",
    "pipelineField" : "fie",
    "status" : "2"
  }
}
```



**match_phase常用参数**

* **query**: (string)

  需要搜索的字符

* **analyzer**: (string)

  分词器

* **slop**: (integer)

  默认短语缺少个数, 默认0, 最大2

  > i love you => query:"i you", slop:1 => 一样可以被检索



## match_phase_prefix短语前缀匹配

集成了match_phase和bool. 只有最后一个分词才有前缀的功能. 如下示例

```json
GET /_search
{
  "query": {
    "match_phrase_prefix": {
      "message": {
        "query": "quick brown f"
      }
    }
  }
}
```

​		

**match_phase_prefix常用参数**

* **query**: (string)

  需要搜索的字符

* **analyzer**: (string)

  分词器

* **slop**: (integer)

  默认短语缺少个数, 默认0, 最大2

  > i love you => query:"i you", slop:1 => 一样可以被检索

* **max_expansions**(integer)

  指定query最大分词数, 默认50





## multi多字段匹配

允许一次查询多个字段

```json
GET /_search
{
  "query": {
    "multi_match" : {
      "query":    "this is a test", // 查询字符串
      "fields": [ "subject^3", "message", "*_name"], // 查询字段
      "type": "best_fields"
    }
  }
}
```

`multi_match.fields`支持多种玩法

1. 字符串和数组
2. 通配符`*`
3. 提高权重`^`("fields": [ "subject^3")] 权重提高3倍)

​		

**multi_match查询方式**

multi_match的查询方式取决于`type`参数, `type`接受如下几个类型

* **best_fields** (默认)

  多个字段进行匹配, 取单个最高分做结果

* **most_fields**

  多个字段进行匹配, 总分由所有fields决定

* **cross_fields**

  跨字段查询(不太清楚, 后面搞)

* **bool_prefix**

  类似于most_fields, 但使用的是match_bool_prefix, 而不是match.





## intervals 顺序间隔查询

