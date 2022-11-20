# Term词项查询

整个字段分为一个词, 主要用于keyword类型, 不过部分非text类型也可以使用

> 尽管text也可以通过`.keyword`使用term查询. 但仍要避免. 
>
> 因为es会在分析text类型时改变字段的值. 这会使精确查找变得困难

term可以细分为4种

* **term**
* **terms**
* **terms lookup**
* **terms set**



## term

[官网Query DSL » Term-level queries » Term query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-term-query.html#query-dsl-term-query)

根据参数精确查找对应文档

```json
GET /_search
{
  "query": {
    "term": {
      "user.id": {
        "value": "kimchy",
        "boost": 1.0
      }
    }
  }
}
```

term接受参数比较少, 只有3个

* **value**: (string)

  精确查找的值

* **boost**: (float)

  搜索相关性得分

* **case_insensitive**: (boolean) 

  是否区分大小写. 默认false

  * `false`: 区分大小写



## terms

[官网Query DSL » Term-level queries » Terms query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-terms-query.html)

terms和term类似, 只不过会接受多个value(最多65536)



## terms lookup

terms lookup是terms的一个功能, 作用是通过其他索引的数据进行一个term查询

类似sql的子查询

```json
GET my-index-000001/_search?pretty
{
  "query": {
    "terms": {
        // 要搜索my-index-000001中的color2
        "color2" : {
            // my-index-000001中id=1的数据的color值作为搜索值
            "index" : "my-index-000001",
            "id" : "2",
            "path" : "color",
            "routing": 1 // 如果入库时指定了则也必须指定
        }
    }
  }
}
```



## terms set

[官网Query DSL » Term-level queries » Terms set query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-terms-set-query.html)

返回最少包含n个term的数据. 

```json
// 入库2条测试数据
PUT my-index-000001/_doc/1
{
  "color":   ["blue", "green"],
  "color2":   ["blue", "green"],
  "count": 2
}

PUT my-index-000001/_doc/2
{
  "color":   ["yellow", "red"],
  "color2":   ["green"],
  "count": 1
}

// terms_set
GET my-index-000001/_search
{
  "query": {
    "terms_set": {
      // color的目标值
      "color": {
        "terms": [
          "blue",
          "green",
          "yellow",
          "red"
        ],
        // 满足目标值的次数由文档的count字段决定
        // 第一条数据如果count=3或者color少一个就不满足条件
        "minimum_should_match_field": "count",
        
        // 也可以通过脚本动态计算 此处固定为3
        // "minimum_should_match_script": {"source": """3"""}         
      }
    }
  }
}
```

