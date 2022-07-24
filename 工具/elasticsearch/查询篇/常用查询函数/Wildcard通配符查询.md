# Wildcard通配符查询

[官网Query DSL » Term-level queries » Wildcard query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-wildcard-query.html)

关于通配符查询, 7.9之后推出了基于keyword的wildcard类型, 用于专门支持wildcard查询

如果直接使用keyword就会和预期的不符合

`?`: 匹配任意单个字符

`*`: 匹配0或多个任意字符

```json
GET common-test-001/_search
{
  "query": {
    "wildcard": {
      "nameWildcard": {
        "value": "I love *",
        "case_insensitive": true // 忽略大小写
        // "wildcard": "I love *" // value的别名, 如果都用了会优先使用后面的那个
      }
    }
  }
}
```



