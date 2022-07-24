# Regexp正则查询

[官网Query DSL » Term-level queries » Regexp query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-regexp-query.html)

返回包含正则的文档

复杂正则可读性差, 扩展性差, 能不用还是不用吧...

```json
GET common-test-001/_search
{
  "query": {
    "regexp": {
      "user.id": {
        "value": "k.*y",
        "flags": "ALL",
        "case_insensitive": true,
        "max_determinized_states": 10000,
        "rewrite": "constant_score"
      }
    }
  }
}
```

**常用参数**

* **value**

  正则

* **flags**: (string)

  启用某些运算符, 默认`ALL`. 不细写[有空再看](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/regexp-syntax.html#regexp-optional-operators)一般都是`ALL`

* **case_insensitive**: (boolean)

  是否区分大小写. 默认false

  * `false`: 区分大小写


