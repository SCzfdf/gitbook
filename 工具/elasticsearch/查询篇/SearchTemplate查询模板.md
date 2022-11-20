# searchTemplate查询模板

[官网Search your data » Search templates](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-template.html)

类似于mysql的存储过程了mybatis的xml文件

可以先把查询的骨架储存起来. 通过修改参数来进行搜索

> gitbook 一些符号不能和{}配合打用(())替代



## 创建查询模板

使用查询模板有2种方法.  

* `POST <index>/_search/template`

  **直接使用模板**

  ```json
  POST common-test-001/_search/template
  {
    "source": {
      "query": {
        "range": {
          "((key))": {
            "gte": "((gte))",
            "lte": "((lte))"
          }
        }
      }
    },
    "params": {
      "key": "intRange",
      "gte": 11,
      "lte": 12
    }
  }
  ```

* `PUT _scripts/<target>`

  **预先创建模板**. (建议使用) 会储存在es内部无需重新编写, 仅提供参数即可

  要注意使用的是`_scripts API`

  ```json
  // 重复提交就是更新
  PUT _scripts/my-search-template
  {
    "script": {
      "lang": "mustache", 
      "source": {
        "query": {
          "range": {
            "intRange": {
              "gte": "((gte))",
              "lte": "((lte))"
            }
          }
        }
      },
      "params": {
        "gte": 11,
        "lte": 12
      }
    }
  }
  ```



## 验证模板

* `POST _render/template`

  ```json
  POST _render/template
  {
    "id": "my-search-template",
    "params": {
      "gte": 11,
      "lte": 12
    }
  }
  
  // 返回的是查询语句, 而不是结果
  {
    "template_output" : {
      "query" : {
        "range" : {
          "intRange" : {
            "gte" : "11",
            "lte" : "12"
          }
        }
      }
    }
  }
  ```

  也可以在创建前验证

  ```json
  POST _render/template
  {
    "source": {
      "query": {
        "range": {
          "intRange": {
            "gte": "((gte))",
            "lte": "((lte))"
          }
        }
      }
    },
    "params": {
      "gte": 11,
      "lte": 12
    }
  }
  ```

  



## 使用模板

[官网REST APIs » Search APIs » Search template API](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/search-template-api.html)

* `GET <target>/_search/template`
* `GET _search/template`
* `POST <target>/_search/template`

* `POST _search/template`

```json
GET my-index/_search/template
{
  // 指定id和params即可
  "id": "my-search-template",
  "params": {
    "query_string": "hello world",
    "from": 0,
    "size": 10
  }
}
```

​		

也可以指定多个模板

[官网REST APIs » Search APIs » Multi search template API](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/multi-search-template.html)

```json
GET common-test-001/_msearch/template
{ }
{ "id": "my-search-template", "params": { "gte": 11, "lte": 12))
{ }
{ "id": "my-search-template", "params": { "gte": 12, "lte": 13))


GET _msearch/template
{ "index": "common-test-001" }
{ "id": "my-search-template", "params": { "gte": 11, "lte": 12))
{ "index": "common-test-001" }
{ "id": "my-search-template", "params": { "gte": 12, "lte": 13))
```





## 获取模板信息

获取所有模板, 需要使用集群API

```shell
GET _cluster/state/metadata?pretty&filter_path=metadata.stored_scripts
```

​		

获取单个模板信息

```shell
GET _scripts/<templateName>
GET _scripts/my-search-template
```



## 删除模板

```shell
DELETE _scripts/<templateName>
DELETE _scripts/my-search-template
```



## 模板高级应用

* [脚本]()
* [默认值](#默认值)
* [url编码](#url编码)
* [数组拼接](#数组拼接)
* [转为json格式](#转为json格式)
* [if-else](#if-else)



### 默认值

如果params不存在会使用默认值值. 格式如下

![image-20220620173151368](SearchTemplate%E6%9F%A5%E8%AF%A2%E6%A8%A1%E6%9D%BF.assets/image-20220620173401653.png)

```json
POST _render/template
{
  "source": {
    "query": {
      "range": {
        "intRange": {
          "gte": "((gte))((gte))11((gte))",
          "lte": "((lte))"
        }
      }
    }
  },
  "params": {
    "lte": 12
  }
}
```





### url编码

将文本进行一次url编码. 格式如下

`((#url))  可以是参数(((host))),也可以直接是字符(/abc).反正在里面的都会被编码  ((/url))`

```json
POST _render/template
{
  "source": {
    "query": {
      "match": {
        "nameText": "((#url))((host))abc((~~~url))"
      }
    }
  },
  "params": {
    "host": "https://www.baidu.com"
  }
}
```



### 数组拼接

将数组格式内的字符进行拼接

`((#join delimiter='分隔符'))date.formats((/join delimiter='分隔符'))`

分隔符默认`,`

```json
POST _render/template
{
  "source": {
    "query": {
      "match": {
        "nameText": "((#join delimiter='|'))host((join delimiter='|'))"
      }
    }
  },
  "params": {
    "host": ["1","2","3","4"]
  }
}
```



### 转为json格式

将变量转为json格式

`((#toJson))tags((/toJson))`

> 感觉用的会比较少, 相当于直接写查询语句. source要经过编码, 还不如手写....
>
> 用在全文检索上也没必要转json....

```json
POST _render/template
{
  "source": "{ \"query\": { \"terms\": { \"tags\": ((#toJson))tags((/toJson)) ))}",
  "params": {
    "tags": [
      "prod",
      "es01"
    ]
  }
}

// 输出结果
// toJson将tags转换为: ["prod", "es01"]
{
  "template_output" : {
    "query" : {
      "terms" : {
        "tags" : [
          "prod",
          "es01"
        ]
      }
    }
  }
}
```



### if-else

条件语句. 满足才填充

![image-20220620180600478](SearchTemplate%E6%9F%A5%E8%AF%A2%E6%A8%A1%E6%9D%BF.assets/image-20220620180600478.png)

> 需要注意的是, 如果用if-else, 那么当`((#condition))if content((/condition))`结果为false时. 就会直接用`((^condition))else content((/condition))`的内容

```json
POST _render/template
{
  "source": {
    "query": {
      "range": {
        "intRange": {
          "lte": "((#bool))((lte))((~~~bool))((^bool))((lte2))((~~~bool))"
        }
      }
    }
  },
  "params": {
    "bool": true,
    "lte": 12,
    "lte2": 13
  }
}
```

这个也可以和`toJson`配合. 手撸查询语句

> 可是还是不建议, 太难看了

```json
POST _render/template
{
  "source": "{ \"query\": { \"bool\": { \"filter\": [ { \"range\": { \"@timestamp\": { \"gte\": ((#year_scope)) \"now-1y/d\" ((/year_scope)) ((^year_scope)) \"now-1d/d\" ((/year_scope)) , \"lt\": \"now/d\" ))}, { \"term\": { \"user.id\": \"((user_id))\" ))]))}",
  "params": {
    "year_scope": true,
    "user_id": "kimchy"
  }
}
```

