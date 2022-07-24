# prefix前缀查询

[官网Query DSL » Term-level queries » Prefix query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-prefix-query.html)

和fuzzy类似. 

需要使用专门的wildcard类型. 不然会有奇奇怪怪的问题

```json
GET common-test-001/_search
{
  "query": {
    "prefix": {
      "nameKeyword": {
        "value": "中"
        // "case_insensitive": true // 忽略大小写
      }
    }
  }
}
```


