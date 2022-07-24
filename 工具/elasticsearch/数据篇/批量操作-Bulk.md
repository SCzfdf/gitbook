# 数据批量操作(Bulk API)

[官网REST APIs » Document APIs » Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/docs-bulk.html)

批量写入无事务保证! 可能会局部失败, 最好由客户端确保重试机制

**bulk最好控制在1000条, 10M(具体看集群资源)**

> es单条入库实际上也是走批量

​		

批量写入有2种方法

1. `POST /_bulk`
2. `POST /<target>/_bulk`

> 如果指定了`target`, 则bulk下所有未指定索引的操作都将指向该索引

Bulk具体语法

1. 按行接受数据(下面实例如果格式化则会报错)
2. 前一行指定操作, 后一行为具体源数据(`delete`除外)
3. 具体操作有`index`, `create`, `delete`和 `update`. 

```json
POST _bulk
{ "index" : { "_index" : "test", "_id" : "1" } }
{ "field1" : "value1" }
{ "delete" : { "_index" : "test", "_id" : "2" } }
{ "create" : { "_index" : "test", "_id" : "3" } }
{ "field1" : "value3" }
{ "update" : {"_id" : "1", "_index" : "test"} }
{ "doc" : {"field2" : "value2"} }

POST common-test/_bulk
{"index": {}}
{"status":3, "name":"张三"}
```



## 返回信息

```json
{
  "took": 31,
  // 如果存在错误则为true, 全部正确则为false
  "errors": true,
  "items": [
    {
      "create" : {
        "_index" : "common-test-001",
        "_type" : "_doc",
        "_id" : "d856jYAB9GYwKf8DnU5i",
        "_version" : 1,
        "result" : "created",
        "_shards" : {
          "total" : 2,
          "successful" : 2,
          "failed" : 0
        },
        "_seq_no" : 3,
        "_primary_term" : 1,
        "status" : 201
      }
    },
    {
      "create": {
        "_index": "common-test-001",
        "_type": "_doc",
        "_id": "ls52jYAB9GYwKf8DW0g8",
        "status": 409,
        // 找到error的做重试就可以
        "error": {
          "type": "version_conflict_engine_exception",
          "reason": "[ls52jYAB9GYwKf8DW0g8]: version conflict, document already exists (current version [1])",
          "index_uuid": "2hWq0ug-R6qjvsJxLAXWdQ",
          "shard": "0",
          "index": "common-test-001"
        }
      }
    }
  ]
}
```



## 常用参数

Bulk API的参数与[Index API](./增删改.md/#Index API常用参数)基本一致

有个`_source`的参数, 说是可以返回`_source`字段. 加了没反应....百度了也没有. 不知道什么情况

