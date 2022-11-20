# Script脚本

能用在**各个地方**. 自定义一些规则满足日益复杂的表达式



## 脚本类型

* **painless**

  最丰富强大的脚本语言, 专门为ES构建

* **expression**

  简洁高效的原生Lucene脚本, 速度最快

* **mustache**

  简洁高效的template脚本(查询模板)
  
* [**java**](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/modules-scripting-engine.html)

  专家级的API, 使用的是插件原理需要重新编译打包并放到es的插件目录下. 相当于重新定义一个脚本语言

```txt
// 通过这个可以查看脚本能在哪个地方使用. 当然无脑用painless也是可以的...
// java自定义的经过注册之后也可以在这里找到
GET _script_language
```





## Script格式

es中script都有相同的格式

> scrpit中`"`和`"""`的区别. `"""`会转义其中的`"`

接受参数:

* **lang**: (enum)

  指定脚本的语言. `painless`(默认), `expression`, `mustache`

* **source**: (object)

  脚本语言的实体, 和id二选一

* **id**

  脚本的储存id, 和source二选一

* **params**: (map)

  脚本的参数

```json
{
  "script": {
    "lang":   "...",
    "source" | "id": "...",
    "params": { ... }
  }
}
```



## Script上下文

[官网Scripting » Accessing document fields and special variables](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/modules-scripting-fields.html#_update_scripts)

[官网Painless contexts](https://www.elastic.co/guide/en/elasticsearch/painless/8.2/painless-contexts.html)

每个操作的都不一样, 如果发现报错就看官网看具体的



### 在查询时获取上下文

总所周知. es在3个地方储存数据. 他们的获取方法如下

1. 行式存储(**_source**) (默认都会存)

   ```lua
   params._source.field

2. 列式储存(**doc_value**) (注意text类型默认不存)

   ```lua
   doc['field'].value    -- 不加.value是一个数组
   ```

   > 除了`.value`外支持其他操作如`.empty`, `.max()`之类的, 具体看[官网](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/modules-scripting-expression.html)

3. Lucene底层储存(**_store**) (默认都不存)

   ```lua
   params._fields['field']
   ```

​		

需要注意以下几点

1. **优先使用`doc_value`, 比`_source`快得多**
2. `doc_value`访问不存在字段会引发错误, 所以最好`doc.containsKey('field')`先查询一下(感觉注意点就好)
3. `doc_value`默认不存储text类型, 如果非要存储则要设置`"fielddata": true`
4. 只有当`_source`非常大, 且只需要访问几个字段时才使用`store`



### 在function_score查询中访问上下文

function_score是特殊的查询. 他能控制`_score`的分数

因此, 在支持上面3种的情况下还支持访问`_score`(直接用就行)

```lua
_score * doc['popularity']
```



### 在更新时获取上下文

更新包括: update, updateByQuery, reindex

只能访问列式存储(**_source**)和一些其他信息. 需要通过`ctx`参数

1. 访问列式存储(**_source**)

   ```lua
   ctx._source
   ```

2. 应用于文档的操作

   ```lua
   ctx.op -- index或者delete
   ```

3. 访问文档中的[元数据](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/mapping-fields.html)

   ```lua
   ctx._index | ctx._id -- 这2个比较有用, 具体还能访问什么看官网
   ```



## 创建/更新脚本

- `PUT _scripts/<script-id>`
- `POST _scripts/<script-id>`

- `PUT _scripts/<script-id>/<context>`
- `POST _scripts/<script-id>/<context>`

```json
// 之后就在script指定id=my-stored-script就可以使用了
PUT _scripts/my-stored-script
{
  "script": {
    "lang": "painless",
    "source": "Math.log(_score * 2) + params['my_modifier']"
  }
}
```





## 测试脚本

1. 可以在kibanapainless lab中测试复杂脚本

2. [使用API](https://www.elastic.co/guide/en/elasticsearch/painless/8.2/painless-execute-api.html#painless-runtime-keyword)

   ```json
   // 相当于一个mock
   POST /_scripts/painless/_execute
   {
     "script": {
       "source": """
         return doc['nameInteger'].value > 2;
           """
     },
     // 8.0之后支持返回很多字段, 并且还会持续更新
     "context": "filter",
     "context_setup": { // 设置上下文
       "index": "common-test-001",
       "document": {
         "nameInteger": 1
       }
     },
     "params":{}
     "query":{}
   }
   ```

   

