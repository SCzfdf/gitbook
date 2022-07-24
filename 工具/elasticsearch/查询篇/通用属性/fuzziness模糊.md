# Fuzziness

[官网](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/common-options.html#fuzziness)

一些查询和API允许使用参数进行不精确的模糊匹配. 属性值为`fuzziness`。

**fuzziness**: (string) 

默认`auto:3,6`

纠错搜索, 允许查询与文档的偏差度(打错单词之类的). 最大值2

`0, 1, 2`: 最大接受n次错误

`auto:<low>,<high>`: 当查询的字符数大于`<low>`时fuzziness=1. 大于`<high>`时fuzziness=2

```json
auto:3,6
查询字符数: 0-2 => 不允许出错
查询字符数: 3-5 => 允许一次
查询字符数: 6-∞ => 允许2次
```

> 模糊查询一般非常消耗CPU资源, 应该尽量避免或者缩减计算量

​		

