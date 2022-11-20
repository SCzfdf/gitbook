# Suggesters启发式查询

依靠输入关键字引导用户输入完整的搜索词

> 但是有很大的局限, 而且做得再好也是基于机械分词, 对于一些电商网站或者强搜索网站很明显不够看. 后续发展还是要依赖一些公司提供的API或者机器学习乃至人工智能



## suggesters本质

普通search搜索的是文档内容本身

suggesters搜索的是分词词项本身(倒排索引的key)

![image-20220509094955161](Suggesters%E5%90%AF%E5%8F%91%E5%BC%8F%E6%9F%A5%E8%AF%A2.assets/image-20220509094955161.png)



## 倒排索引

正排索引储存文档的结构

![img](Suggesters%E5%90%AF%E5%8F%91%E5%BC%8F%E6%9F%A5%E8%AF%A2.assets/v2-d50ffd4b3bc38e25e281fea9e07e14e6_720w.jpg)

倒排索引储存文档的结构

![img](Suggesters%E5%90%AF%E5%8F%91%E5%BC%8F%E6%9F%A5%E8%AF%A2.assets/v2-0e77a230cbce4cd3c8b8e121bb211518_720w.jpg)



## suggesters分类

[官网REST APIs » Search APIs » Suggesters](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-suggesters.html#return-suggesters-type)

[elasticsearch拼写纠错之Term Suggester](https://www.1024sky.cn/blog/article/72762)

需要注意的是因为是针对倒排索引进行搜索的, 所以只能用在text类型上

* **term**

  单个词项

* **phrase**

  短语

  > term和phrase就是搜索栏下拉框的提示, 只会返回对应**词项**

* **completion**

  自动完成. 

  > 不是搜索栏上的下拉提示, 而是点击搜索栏时的搜索操作
  >
  > 如: 输入`new`. 用completion就会将`new`前缀的**文档数据**搜索出来

* **context**

  基于上下文来自动完成

> suggest下可以使用多个启发式查询. 不过不知道适合用在什么场景...
>
> ```json
> {
>   "suggest": { 
>     "one_suggest": { 
>       "term": {}
>     },
>  	"two_suggest": {
>       "phrase": {}
>     }
>   }
> }
> ```



### term suggest

基于单个词项进行查询

```json
GET common-test-001/_search
{
  "suggest": { // 能接受多个term suggest
    // "text": "spid", // 搜索的值也可以放在这里, 这样搜索多个字段的时候就是全局的
    "YOUR_SUGGESTION": { // term suggest的名称
      "text": "spid", // 搜索的值
      "term": {
        "field": "nameText" // 搜索的字段
      }
    }
  }
}

// 结果
{
  "suggest" : {
    "YOUR_SUGGESTION" : [
      {
        "text" : "spid",
        "offset" : 0,
        "length" : 4,
        "options" : [
          {
            "text" : "spider", // 完整的term
            "score" : 0.5, // 得分
            "freq" : 1 // 词频
          }
        ]
      }
    ]
  }
}

```



**常用参数**

* **analyzer**

  分词器

* **size** 

  返回的建议数

* **sort**: (enum)

  对返回的建议进行排序. 默认`score`

  `score`: 按分数排序

  `frequency`: 按词频排序

* **suggest_mode**: (enum)

  模式控制, 默认`missing`

  `missing`: 仅为不在索引中的词项生成建议. (如果单词存在则不进行建议)

  `popular`: 如果索引词存在, 则只返回比索引词词频更高的建议

  > `spidera`词频为3, `spiderb`词频为4, `spiderc`词频为5
  >
  > 搜索`spiderb`只会出来`spiderc`

  `always`: 尽可能的提供建议

  **missing, popular都是分片级别的.** 

  例如missing模式: `spider`在分片1中有, 在分片2中没有. 那么搜索`spider`, 可能会在分片2中返回建议

* **max_edits**: (integer)

  最大容错值. 默认2. 只能为1~2

* **prefix_length**: (integer)

  不进行启发查询的字符数, 默认1.

* **min_word_length**: (integer)

  搜索最小字符长度

* **shard_size**: (integer)

  要从各个分片检索的建议数, 默认size数量

  增大此值能提高建议的精确度(下降性能)

* **max_inspections**: (integer)

  相乘因子, 用于和`shard_size`相乘. 在分片级别检索更多建议. 默认5

* **min_doc_freq**: (integer)

  建议出现的最小文档数(小于设置数量则不出现). 默认0 (shard级别的配置)

* **max_term_freq**: (integer | float(百分比))

  主要控制建议词在文档中出现的最多的次数. (大概是找到max次就跳过当前文档)

* **string_distance**: (string)

  指定算法

  

### phrase suggest

基于短语进行搜索. 需要注意的是短语如果是一个完整正确的短语则不会出现结果

```json
{
  "suggest": {
    "phrase_suggestion": {
      // 模糊搜索的短语
      "text": "Gimpo International Airpo",
      // phrase关键字
      "phrase": {
        // 指定查询名称
        "field": "Dest",
        "highlight": {
          "pre_tag": "<h1>",
          "post_tag": "</h1>"
        },
        "real_word_error_likelihood": 0.95
      }
    }
  }
}
```



**常用参数**

* **real_word_error_likelihood**: (float)

  查询字段在索引中的正确率, 默认`0.95`. 即`5%`拼写错误

* **highlight**: (object)

  高亮补完结果. 需要定义2个标签`pre_tag`和`post_tag`

  > `"pre_tag": "<h1>", "post_tag": "</h1>"`
  >
  > 搜索结果: `gimpo international <h1>airport</h1>`

> 感觉用到比较少, api比较复杂, 后面用到再细看



### completion

自动完成/自动补全

基于另一个数据结构FST. 可以大大提高查询速度

深入的字符数据不能有拼写错误

需要一种新的数据类型`completion`

> 用到的场景可能比较少, 感觉用term+match搜索出来的结果可能还更符合预期

```json
PUT common-test-001
{
  "mappings": {
    "properties": {
      "Dest": {
        // 需要使用completion类型
        "type": "completion"
      }
    }
  }
}

// 搜索
GET kibana_sample_data_flights_suggest/_search
{
  "track_total_hits": true, 
  "suggest": {
    "dest_suggest": {
      "prefix": "Turin",
      "completion": {
        "field": "Dest",
        "skip_duplicates": false
      }
    }
  }
}
```

completion还能支持正则. 只要将`prefix`替换为`regex`即可

> 感觉会慢不少

​		

**常用参数**

* **field**: (string)

  需要完成的字段

* **size**: (integer)

  返回的建议数. 默认5

* **skip_duplicates**: (boolean)

  是否过滤重复建议, 默认false(不过滤). 

  在元数据中会多了一个`text`字段按照该字段过滤按照, 也即是`field`的值

* **fuzzy**: (fuzzy)

  还能接受一定的模糊查询, 和Fuzzy查询有一定差异
  
  * [fuzziness](./通用属性/fuzziness模糊.md): (string)
  
    纠错搜索, 默认auto
  
  * `prefix_length`: (integer)
  
    不进行模糊查询的字符数, 默认1
  
  * `transpositions`: (boolean)
  
    是否匹配换位(ab => ba)
  
  * `min_length`: (integer)
  
    模糊搜索启动的最小输入长度





### context

基于内容的上下文来限制自动补全返回的数据.

也是属于completion的功能

需要一种新的数据类型`completion`, 并且指定`context`

上下文可以指定为`category`和`geo`

```json
PUT place
{
  "mappings": {
    "properties": {
      "suggest": {
        // 指定completion类型
        "type": "completion",
        "contexts": [
          {
            "name": "place_type",
            // 指定上下文type为category. 可以理解为类别
            // 还有一种为地理上下文的, 需要在看官网
            "type": "category"
          }
        ]
      }
    }
  }
}

// 插入数据
PUT place/_doc/1
{
  "suggest": {
    "input": [ "timmy's", "starbucks", "dunkin donuts" ],
    "contexts": {
      "place_type": [ "cafe", "food" ]                    
    }
  }
}

// 搜索
POST place/_search?pretty
{
  "suggest": {
    "place_suggestion": {
      // 当suggest存在starbucks* 并且context包含"cafe", "restaurants"其中一个才会被检索出来
      "prefix": "starbucks",
      "completion": {
        "field": "suggest",
        "size": 10,
        "contexts": {
          "place_type": [ "cafe", "restaurants" ]
        }
      }
    }
  }
}

```

