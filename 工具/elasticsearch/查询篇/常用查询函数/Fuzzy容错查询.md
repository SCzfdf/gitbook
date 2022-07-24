# Fuzzy容错查询

[官网Query DSL » Term-level queries » Fuzzy query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-fuzzy-query.html)

fuzzy, 英文翻译纠错模糊, 中文俗称夫子查询. 即对查询的分词允许一定的误差存在

fuzzy依然属于term查询的一种. 

非常消耗CPU资源, 应该尽量避免或者缩减计算量

纠错包括:

* 改变一个字符
* 删除一个字符
* 插入一个字符
* 转换2个相邻字符

```json
GET common-test-001/_search
{
  "query": {
    "fuzzy": {
      "nameKeyword": {
        "value": "keyword",
        "fuzziness": 1,
        "prefix_length": 2
      }
    }
  }
}
```

​		

使用专门的wildcard类型. 就不会有问题

~~**Fuzzy的局限**~~

~~Fuzzy对于英文短语和中文短语的支持很奇怪. 不是说查不出,~~ 

```json
// 有`i love you`的数据, 对于下面查询查不出.
// 如果`i love` 则可以. 但`i love `则不行
GET common-test-001/_search
{
  "query": {
    "fuzzy": {
      "nameKeyword": {
        "value": "i love yo",
        "fuzziness": 2
      }
    }
  }
}

// 有`一二三十五六`的数据
// `一二三`可以查出来. `一二三十五`不行....
{
  "query": {
    "fuzzy": {
      "nameKeyword": {
        "value": "中国",
        "fuzziness": 1
      }
    }
  }
}
```

~~中文猜测可能和分词有关系. 使用`中国`和`"fuzziness": 1`可以查出对于文档~~

~~英文的不太清楚为什么~~



**常用参数**

* **value**: (string)

  查询值

* **[fuzziness](./通用属性/fuzziness模糊.md)**: (string)

  纠错搜索, 默认auto

* **max_expansions**: (integer)

  [max_expansions 该怎么用?](https://segmentfault.com/q/1010000017179306)

  最大计算数. 默认50. (大概意思就是越大越容易匹配的上, 不过需要资源也越多)

* **prefix_length**: (integer)

  不进行模糊查询的前缀字符数, 默认0

* **transpositions**: (boolean)

  是否匹配换位(ab => ba)

