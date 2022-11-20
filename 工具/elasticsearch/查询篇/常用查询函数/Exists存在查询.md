# Exists存在查询

[官网Query DSL » Term-level queries » Exists query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-exists-query.html)

返回包含字段索引值的文档

文档可能不存在索引值的可能原因:

* 字段为null
* 字段长度超过`ignore_above`设置值
* 字段`index=false` (测试没用...)
* 字段在mapping中设置`ignore_malformed=true`, 并入库类型错误(int类型 入库 string)



```json
GET common-test-001/_search
{
  "query": {
    "exists": {
      "field": "nameKeyword"
    }
  }
}
```

