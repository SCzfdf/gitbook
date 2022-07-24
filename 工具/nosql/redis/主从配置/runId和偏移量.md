# runId和偏移量

[runId和offset](https://www.jianshu.com/p/77090fdb4994)



## 概念

### runId

reids服务器的随机标识符,用来标识当前redis进程. 每次redis重启或其他操作都会改变

用 `info server` 查看

### 偏移量

复制偏移量。在master和slave中都会有这个量。master传输出去N个字节，master的offset增加N；slave收到N个字节，slave的offset增加N

用 `info replication` 查看(role:master | master_repl_offset:xxx)

### 复制积压缓冲区

维护在master中一个固定长度的FIFO（先进先出）队列。在master每次向外传输时，也会向该队列中传输。该队列中会有对应的偏移量和其对应的字节记录。

>   [!notice]
>
>   如果从服务器的偏移量不在复制缓冲区中(数据差太远) 则会进行完整的重同步

>   关于复制积压缓冲区大小
>
>   可以根据 second(平均断线秒数) * write_size_per_second(平均每秒读写数) 来估算
>
>   安全起见可以再 * 2



## 作用

用来判断是全量复制还是部分复制

大概就这样吧↓↓↓↓

```java
if (oldRunId == null || newRunId != oldRunId) {
    全量复制();
}else {
    if(masterOffset != slaveOffset) {
        if (复制积压缓冲区.size() > 0) {
            slaveOffset = 复制积压缓冲区.size() + slaveOffset;
            if(masterOffset != slaveOffset) {
                全量复制();
            }
        }else {
            全量复制();
        }
    }else {
        部分复制();
    }
}
```



如果网络抖动或者其他一些导致从节点不能同步主节点数据, 导致偏移量差距过大时也会导致全量复制. 如果在一定范围内, 主节点会把缓存内的数据给从节点一份让他同步

