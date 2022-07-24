# Range范围查询

[官网Query DSL » Term-level queries » Range query](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/query-dsl-range-query.html)

返回包含给定范围的文档

```json
GET common-test-001/_search
{
  "query": {
    "range": {
      "age": {
        "gte": 10,
        "lte": 20,
      }
    }
  }
}
```

​		

**常用参数**

* **gt**

  大于

* **gte**

  大于等于

* **lt**

  小于

* **lte**

  小于等于

* **format**: (字符串)

  用于转换date查询中的值的日期格式

* **time_zone**: (字符串)

  时区偏移量

* **relation**: (enum)

  如何匹配字段值, 默认`INTERSECTS`

  `INTERSECTS`: 交集

  `CONTAINS`: target包含search

  `WITHIN`: search包含target

  ```json
  {
    "query": {
      "range": {
        "rangeInt": {
          // rangeInt: {gte:100, lte:200} 可以被查询出来
          "gte": 9,
          "lte": 222,
          "relation": "WITHIN"
        }
      }
    }
  }
  ```

  

  

  


