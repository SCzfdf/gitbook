# 重建索引-reindex

[官网REST APIs » Document APIs » Reindex API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)

重建索引是创建新索引, 原有索引会保留

原有索引`_source`必须开启, 否则找不到原始数据

需要注意的几点: 

1. `reindex`是用源索引的快照对目标索引进行一个类似`update_by_query`的操作, 目标表也可以使用Index API一样配置用来控制并发. (在数据可能会冲突时需要用`version_type`控制冲突策略)
2. 如果target表不存在. 在索引重建后, 索引大小可能会变化. 原因是es会对target表进行一个修改(推测目标表的结构, 而不是直接用source表的结构), 导致mapping不一致. 所以应该**手动创建targer表**

​		

## reindex使用场景

1. es集群版本升级

   跨版本升级必须重建, 不然无法写入

2. 数据迁移

3. 分片数量调整

4. 索引文档结构变更(字段类型, 字段属性, 文档结构)

   字段类型不可以修改(keyword, text, long...)

   字段属性可以修改, 但历史数据不会刷新(index, store...)

5. 清理索引碎片垃圾

   索引频繁更新, 产生了很多内存垃圾碎片(早期Lucene开发会存在)

6. 索引合并

7. 字段名称修改或数据大批量更新(用脚本)

   ```json
   "script": {
     "source": "ctx._source.status1 = ctx._source.remove('status')"
   }
   ```

   



### reindex语法

* `POST /_reindex`

  ```json
  {
    "source": {
      "index": "my-index-000001" // 源表
    },
    "dest": {
      "index": "my-new-index-000001" // 目标表
    }
  }
  ```

  如果多次执行那么除了第一次是`create`操作其余都是`update`操作. 如果导入多个表并且id存在冲突的话数据就会覆盖(update)



## reindex常用body参数

* **source**: (properties) 

  源数据配置

  * `index`: (string|array) 目标索引的名称

  * `_source`: 需要迁移的字段. `"_source": ["status"]`

  * `query`: 符合查询的信息才迁移

  * `size`: (integer) scroll的大小, 默认1000

  * `slice`: 手动切片

    需要指定id和max2个子参数(将任务手动分为`max`个, 本次执行的是第`id`+1个)

    和url参数中的**slices**不同的是手动切片需要手动执行多次

    ```json
    {
        "source": {
            "index": "kibana_sample_data_logs",
            "slice": {
              "id": 0, // id从0开始算
              "max": 2
            }
      }
    }
    ```

  * `remote`: 源数据所在的信息(子项: host, username, password, socket_timeout, connect_timeout)

    需要在dest集群中设置白名单

    ```properties
    # config/elasticsearch.yml
    reindex.remote.whitelist: "192.168.86.106:9201,127.0.0.1:9200"
    ```

  * ~~`sort`~~: 迁移的优先级, 弃用. 使用`query`来控制

* **dest**: (properties) 

  目标索引配置

  * `index`: 目标索引的名称

  * `routing`: 路由信息

    接受3个类型, 默认`keep`

    `keep`: 保持原有路由信息也即是id路由

    `discard`: 将路由信息设置为空

    `=<some text>`: =符号是必须的, 将所有路由信息设置为输入的值. 如:`=cat`路由信息就是cat字符

  * `op_type`: 和Index API一致

    接受`index`和`create`, 如果指定了<_id>则默认`index`, 否则默认`create`

    `create`: 不存在就创建, 如果指定<_id>存在则失败

    `index`: 不存在就创建, 存在则更新

  * `version_type`: 冲突控制, 和Index API一致

  * `pipeline`: (Ingest pipeline) 重建索引前将数据传入管道进行预处理

* **conflicts**: (enum) 

  版本冲突控制. 默认`abort`

  `abort`: 遇到版本冲突时终止

  `proceed`: 遇到版本冲突时继续

* **script**: (script)

  可以修改源数据后再写入到新索引

* **size**和**max_docs**(integer): 控制迁移的最大数量`size`弃用, 使用`max_docs`



## reindex常用url参数

reindex的参数与[delete_by_query](./增删改.md/#Index API常用参数)基本一致



## 跨集群reindex

1. 在elasticsearch.yml上配置`reindex.remote.whitelist`

   表示接受来自`127.0.10.*:9200`的数据

   ```yml
   reindex.remote.whitelist: "127.0.10.*:9200, localhost:*"
   ```

2. [建立集群链接](../集群篇/跨集群操作.md#建立集群链接)

   需要注意的是集群链接是用TCP接口, reindex用的是Http接口
   
   ```json
   PUT /_cluster/settings
   {
     "persistent" : {
       "cluster" : {
         "remote" : {
           "elk01" : {
             "seeds" : [
               "192.168.3.77:9300" 
             ]
           }
         }
       }
     }
   }
   ```
   
2. 进行reindex

   ```json
   POST _reindex
   {
     "source": {
       "remote": {
         "host": "http://192.168.3.77:9200" // http!
       },
       "index": "common-test-001"
     },
     "dest": {
       "index": "common-test-001"
     }
   }
   ```

   


