# RedoLog和UndoLog

为了防止BufferPool中在刷盘的时候由于异常导致刷盘失败和缓存丢失, 引入RedoLog和UndoLog

**Redo Log**

InnoDB对所有数据页的**修改操作**都记录到RedoLog中.

当数据库崩溃BufferPool为来得及持久化, 在数据库重启时就会从RedoLog中读取之前的操作并重新执行一遍. 从而实现数据恢复

**Undo Log**



**写入流程**

![image-20220611231309430](RedoLog%E5%92%8CUndoLog.assets/image-20220611231309430.png)



## LogBuffer

[官网LogBuffer](https://dev.mysql.com/doc/refman/8.0/en/innodb-redo-log-buffer.html)

[关于mysql中的innodb_flush_log_at_trx_commit配置](http://www.04007.cn/article/794.html)

但由于RedoLog和UndoLog是文件, 需要持久化到硬盘中. 频繁多次修改必然会导致IO暴涨

因此再引入一个LogBuffer, 避免频繁IO

> RedoLog和UndoLog不同于真正的数据文件, 属于顺序IO. 速度上比BufferPool的刷盘快得多
>
> LogBuffer默认16m, 可以通过`innodb_log_buffer_size`修改

LogBuffer有3中刷盘时机, 可以通过`innodb_flush_log_at_trx_commit`修改默认`1`

* `0`

  每秒将LogBuffer同步到文件系统缓存(OS Buffer)中, 同时会调用`fsync()`手动将OS Buffer的数据持久化. 

  **性能最佳但可能会丢失1秒的数据**

* `1`

  每次事务提交时将LogBuffer同步到文件系统缓存(OS Buffer)中, 同时会调用`fsync()`手动将OS Buffer的数据持久化. 

  **能保证强一致性, 能确保只要事务提交成功就不会丢数据. 默认策略**

* `2`

  每次事务提交时将LogBuffer同步到文件系统缓存(OS Buffer)中, 但`fsync()`只会每秒中调用一次

  **也可能会丢失1秒的数据**



