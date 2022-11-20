# 在ES中使用SQL

[官网SQL](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/xpack-sql.html)

SQL拥有广大的受众基础, 语法简单. 并且众多大数据产品都支持sql

在ES中实际上是不支持SQL的, 而是通过转换成DSL

> 早期通过NLPChina转换. 现在推荐用官方的x-Pack-sql
>
> ES中基本的SQL查询都支持

![image-20220517121806585](%E5%9C%A8ES%E4%B8%AD%E4%BD%BF%E7%94%A8SQL.assets/image-20220517121806585.png)



## SQL概念映射

| SQL             | ElasticSearch           |
| --------------- | ----------------------- |
| 字段 column     | 字段 field              |
| 数据行 row      | 数据文档 document       |
| 数据表 table    | 索引 index              |
| 表结构 schema   | 映射 mapping            |
| 数据库 database | ES实例 cluster instance |



## SQL在ES查询中的优势与局限

**优势**

1. 语法简单
2. **返回数据报文比DSL少**(性能优化可以用上)(简单查询可以优先使用)
3. 能与DSL结合过滤数据集

局限

* 但复杂查询还是要使用DSL
* 不能支持特殊类型(integer_range之类的会自动忽略)
* 二次查询不支持



## SQL示例

在kibana控制台中建议使用`"""`的会自动转义`"`和`()` 并支持多行. 并且单行的不支持表名带`-`...

```json
GET _sql?format=json
{
  "query": """
  select * from "common-test-001"
  """
}
GET _sql?format=json
{
  "query": "select * from kibana_sample_data_flights"
}
```



## SQL返回格式

* `csv`

* `tsv`: 和csv差不多, 不过是制表符分割

* `json`: 

  ```txt
  {
    "columns": [
      {"name": "author",       "type": "text"},
      {"name": "name",         "type": "text"}
    ],
    "rows": [
      ["Peter F. Hamilton",  "Pandora's Star"]
    ]
  }
  ```

* `txt`: 返回类似sql shell查询的样式

  ```txt
       author      |        name        
  -----------------+--------------------
  Peter F. Hamilton|Pandora's Star      
  ```

* `yml`

  ```yml
  columns:
  - name: "author"
    type: "text"
  - name: "name"
    type: "text"
  rows:
  - - "Peter F. Hamilton"
    - "Pandora's Star"
  ```

* `cbor`: 返回简洁的二进制格式

* `smile`: 返回类似CBOR的二进制格式



## 分页

sql查询之后如果后续有数据会在response中附带一个`cursor`字段

要查询后续数据页只需要`cursor`即可. 类似`scroll`

> 也就是说不支持传统`limit 0, 10`分页

```json
POST /_sql/close
{
  "cursor": "sDXF1ZXJ5QW5kRmV0Y2gBAAAAAAAAAAEWYUpOYklQMHhRUEtld3RsNnFtYU1hQQ=="
}
```

和`scroll`不同的是在最后一页时就会清除游标. 因此再返回空页后再请求就会报`search_context_missing_exception`	

​		

如果已经请求到需要的数据, 那么久要及时清除`cursor`以便回收资源

```json
POST /_sql/close
{
  "cursor": "sDXF1ZXJ5QW5kRmV0Y2gBAAAAAAAAAAEWYUpOYklQMHhRUEtld3RsNnFtYU1hQQ=="
}
```



## 常用请求参数

* **fetch_size**: (integer)

  返回的数据条数. 和limit不同, 使用limit之后不会返回cursor也即是不能分页

* **filter**: (DSL)

  可以支持DSL辅助过滤数据集和指定路由等

  ```json
  POST /_sql?format=txt
  {
    "query": "SELECT * FROM library",
    "filter": {
      "terms": {
        "_routing": ["abc"]
      }
    }
  }
  ```

* **columnar**: (boolean)

  列转行, 默认false

  ```json
  [a1, b1], [a2, b2]
  // 转换后
  [a1, a2], [b1, b2]
  ```

* **params**: (array)

  提供了类似mybatis的占位符能力

  ```json
  POST /_sql?format=txt
  {
  	"query": "SELECT * FROM library WHERE page_count > ? AND author = ? GROUP BY year HAVING COUNT(*) > ?",
  	"params": [300, "Frank Herbert", 0]
  }
  ```

* **runtime_mappings**

  支持runtime字段, 会动态的加到结果集里

* **[wait_for_completion_timeout](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/sql-async.html)**: (time 2d之类的)

  类似async_search. 会把查询提交到一个线程中处理

  ```shell
  # 查询任务状态
  GET _sql/async/status/FnR0TDhyWUVmUmVtWXRWZER4MXZiNFEad2F5UDk2ZVdTVH
  # 获取任务结果
  GET _sql/async/FnR0TDhyWUVmUmVtWXRWZER4MXZiNFEad2F5UDk2ZVdTVH
  # 终止任务
  DELETE _sql/async/delete/FnR0TDhyWUVmUmVtWXRWZER4MXZiNFEad2F5UDk2ZVdTVH
  ```

* **keep_alive**: (time)

  异步查询结果保留的时间, 默认`5d`

  如果超时了就会删除结果, 即使任务仍在进行!

* **keep_on_completion**: (boolean)

  是否保留同步搜索的结果, 默认false. 此参数需要指定`wait_for_completion_timeout`





## SQL转DSL

```json
POST /_sql/translate
{
  "query": "SELECT * FROM library ORDER BY page_count DESC",
  "fetch_size": 10
}
```

转换后

```json
{
  "size": 10,
  "_source": false,
  "fields": [
    {
      "field": "author"
    },
    {
      "field": "name"
    },
    {
      "field": "page_count"
    },
    {
      "field": "release_date",
      "format": "strict_date_optional_time_nanos"
    }
  ],
  "sort": [
    {
      "page_count": {
        "order": "desc",
        "missing": "_first",
        "unmapped_type": "short"
      }
    }
  ]
}
```



## 常用函数和运算符

[官网SQL » Functions and Operators](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/sql-functions.html)

官网的函数非常多, 建议看. 这里列几个常用的

也可以使用下面语法查询(但没有注释....可以查看当前版本是否支持某函数)

```json
GET _sql?format=json
{
  "query": """
  show functions
  """
}
```

* **like**

  针对keyword. `%`匹配0-n位, `_`匹配1位

* **match**

  全文检索, 针对keyword.

  ```sql
  select * from "common-test-001" where match(nameText, 'is')
  ```

* **avg/sum/min/max等聚合函数**

  ```sql
  select avg(DistanceMiles) from kibana_sample_data_flights
  ```

  



## 使用JDBC连接ES

直接使用JDBC协议连接ES, 就可以不通过`POST /_sql`的方式传输sql了. 完全是sql的语法.

但是不支持的还是不支持. 而且这功能是收费的.... 并且不能通过JDBC对数据进行修改



## 使用外部引擎

可以使用一些外部的引擎如PrestoDB(PrestoDB不储存数据), 能更好的支持SQL语法

[PrestoDB简介](https://aws.amazon.com/cn/big-data/what-is-presto/)

