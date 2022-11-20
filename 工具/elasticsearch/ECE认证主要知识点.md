# ECE认证主要知识点

[Mapping](../../索引篇/Mapping.md)

[字段类型属性](../../索引篇/字段类型属性.md)(**fields**重点)

[分词器](../../查询篇/深入分词.md)

[update_by_query](../../数据篇/增删改.md)

[批量操作Bulk](../../数据篇/批量操作-Bulk.md)

[reindex](../../数据篇/重建索引-reindex.md)

[ingest pipeline](../../数据篇/管道-ingest_pipeline.md)

[script](../../Script脚本.md)





评分

bool中**must_not**和**filter**中的查询时不参与评分的

**indices_boost** 多索引查询时自定义索引权重

索引创建阶段通过指定**boost**修改相关性(应该不考, 8.0要移除)

查询时指定**boost**修改权重(要注意语法, 有部分写法不支持boost. 看官方文档即可)

查询时指定**negative_boost**降低权重. 仅针对部分查询方法(**boosting**), 支持范围0-1.0

**multi_match**查询中针对fields可以使用`^boost(^3)`的方式提权. 对于fields字段的评分用type控制

* best_fields

  使用最高的field得分做整体评分

* most_fields

  使用全部fields评分做整体评分

* cross_fields

  将所有字段结合打分, 需要配合analyzer使用

* phrase

  使用match_phrase对每个字段进行查询并取最高分

* phrase_prefix

  使用match_phrase_prefix对每个字段进行查询并取最高分

* bool_prefix

  使用match_bool_prefix对每个字段进行查询. 使用全部fields评分做整体评分

使用**function_score**通过脚本来自定义评分查询

查询后使用**rescore_query**二次打分





检索 高亮, 分页, 排序, 异步

别名

索引模板

跨集群检索, 复制



给定条件简单检索(精准匹配, 全文检索)

给定条件复杂检索(bool, join)

bool

​	使用minimun_should_match控制should符合的个数



给定条件Metric指标, bucket分桶, 子聚合





default_pipeline



索引模板, IML



[ingest pipeline](../../数据篇/管道-ingest_pipeline.md)

[nested](../../索引篇/常用字段类型.md)

[join](../../索引篇/常用字段类型.md)(Join聚合xxx#yyy)

painless

​	runtime_field mapping时定义

​	script_field 查询时定义





[排除, 诊断, 修复 集群健康问题](#排除, 诊断, 修复 集群健康问题)

[备份, 恢复 集群或索引(snapshot-restore)](#备份, 恢复 集群或索引(snapshot-restore))

[配置可搜索快照](#配置可搜索快照)

基于角色控制elastic安全策略





## 排除, 诊断, 修复 集群健康问题

黄色: 有副本分片没有分配成功

红色: 有主分片没有分配成功

诊断

`GET /_cluster/health/<target>?level=indices`

`GET /_cat/health`

`GET /_cat/indices?v&index=xx`

排查

```json
GET /_cluster/allocation/explain
{ // 三个参数都要有
  "index": "text_001_01", // 指定索引 
  "shard": 0, // 指定分片
  "primary": false // true主分片 false副本分片
}
```

> 就是改变settings的主分片分配和副本分片分配



## 备份, 恢复 集群或索引(snapshot-restore)

1. 在elasticsearch.yml中配置快照库路径

   ```yml
   ## 要重启
   path:
     repo:
       - /mount/backups
       - /mount/long_term_backups
   ```

2. 注册快照库

   ```json
   PUT /_snapshot/my_backup
   {
     "type": "fs",
     "settings": {
       "location": "/mount/backups"
     }
   }
   ```

3. 创建快照

   ```json
   PUT /_snapshot/<快照库名称>/<快照名称>
   PUT /_snapshot/my_backup/snapshot_2?wait_for_completion=true
   {
     // 默认全局快照
     "indices": "data_stream_1,index_1,index_2",
     "ignore_unavailable": true,
     "include_global_state": false,
     "metadata": { // 源信息
       "taken_by": "kimchy",
       "taken_because": "backup before upgrading"
     }
   }
   ```

4. 恢复快照

   ```json
   POST /_snapshot/my_backup/snapshot_1/_restore
   {
     // 指定索引恢复
     "indices": "index_1",
     "ignore_unavailable": true,
     "index_settings": {
       "index.number_of_replicas": 0
     },
     "ignore_index_settings": [
       "index.refresh_interval"
     ]
   }
   ```



## 配置可搜索快照

收费功能...

前3步和上面一致. 只需要挂载到索引就可以了

```json
POST /_snapshot/<repository>/<snapshot>/_mount

POST /_snapshot/my_repository/my_snapshot/_mount?wait_for_completion=true
{
  "index": "my_docs", 
  "renamed_index": "docs", 
  "index_settings": { 
    "index.number_of_replicas": 0
  },
  "ignore_index_settings": [ "index.refresh_interval" ] 
}
```



IML生命周期自动挂载





## 基于角色控制elastic安全策略

