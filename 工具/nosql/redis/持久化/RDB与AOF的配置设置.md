# RDB与AOF的配置

[Redis配置文件详解](https://www.cnblogs.com/cxd4321/archive/2012/12/14/2817669.html)

## RDB

客户端执行`save` 触发主进程RDB操作

客户端执行`bgsave` 触发主进程创建子进程进行RDB操作

```shell
# 自动触发RDB的设置
# save {x秒} {y写次数}
save 900 1
save 300 10
save 60 10000

# 保存的RDB文件名
dbfilename {文件名}.rdb

# 指定保存rdb文件的路径 和AOF共用
dir {uri}

# 在bgsave发生错误的时候是否停止写入 默认yes
stop-writes-on-bgsave-error {boolean}

# rdb是否压缩, 会耗费CPU资源, 默认yes
rdbcomperssion {boolean}

# 是否对rdb数据进行校验, 会耗费CPU资源, 默认为yes
rdbchecksum {boolean}
```



## AOF

客户端执行`bgrewriteaof` 命令触发主进程创建子进程进行AOF重写操作

```shell
# 开启AOF
appendonly {boolean}

# 保存AOF文件的文件名
appendfilename {文件名}

# 设置AOF的同步策略
appendsync {always|everysec|no}

# 指定保存rdb文件的路径 和RDB共用
dir {uri}

# 在AOF重写的时候不进行AOF操作(不开这个可能会阻塞主线程, 开了可能会丢数据(重写的时候缓冲区的数据没冲刷到AOF文件))
no-appendfsync-on-rewrite {boolean}



# 自动触发AOF重写配置
# 当AOF文件多大的时候才开启重写
auto-aof-rewrite-min-size {size}mb
# 当AOF文件比上次大多大时重写(百分比), 默认100(没有百分号) (看下面计算值默认是一倍)
auto-aof-rewrite-percentage {百分比}

# 是否忽略最后一条可能错误的命令
aof-load-truncated {boolean}
```



自动触发时机

    当前 AOF 文件大小超过最小重写尺寸
    当前 AOF 文件大小超过上次重写完的 AOF 尺寸的百分之多少（auto-aof-rewrite-percentage）
auto-aof-rewrite-percentage 的数字计算

(aof_current_size - aof_base_size) / aof_base_size > auto-aof-rewrite-percentage 

|      统计名      |                 含义                  |
| :--------------: | :-----------------------------------: |
| aof_current_size |       AOF当前尺寸（单位：字节）       |
|  aof_base_size   | AOF上次启动和重写的尺寸（单位：字节） |



## info中的AOF和RDB

redis info 命令中的RDB和AOF信息

### RDB

| loading                     | 服务器是否正在载入持久化文件                                 |
| --------------------------- | ------------------------------------------------------------ |
| rdb_changes_since_last_save | 离最近一次成功生成rdb文件，写入命令的个数，即有多少个写入命令没有持久化 |
| rdb_bgsave_in_progress      | 服务器是否正在创建rdb文件                                    |
| rdb_last_save_time          | 离最近一次成功创建rdb文件的时间戳。当前时间戳 - rdb_last_save_time=多少秒未成功生成rdb文件 |
| rdb_last_bgsave_status      | 最近一次rdb持久化是否成功                                    |
| rdb_last_bgsave_time_sec    | 最近一次成功生成rdb文件耗时秒数                              |
| rdb_current_bgsave_time_sec | 如果服务器正在创建rdb文件，那么这个域记录的就是当前的创建操作已经耗费的秒数 |
| rdb_last_cow_size           | RDB过程中父进程与子进程相比执行了多少修改(包括读缓冲区，写缓冲区，数据修改等)。 |



### INFO

| aof_enabled                  | 是否开启了aof                                                |
| ---------------------------- | ------------------------------------------------------------ |
| aof_rewrite_in_progress      | 标识aof的rewrite操作是否在进行中                             |
| aof_rewrite_scheduled        | rewrite任务计划，当客户端发送bgrewriteaof指令，如果当前rewrite子进程正在执行，那么将客户端请求的bgrewriteaof变为计划任务，待aof子进程结束后执行rewrite |
| aof_last_rewrite_time_sec    | 最近一次aof rewrite耗费的时长                                |
| aof_current_rewrite_time_sec | 如果rewrite操作正在进行，则记录所使用的时间，单位秒          |
| aof_last_bgrewrite_status    | 上次bgrewriteaof操作的状态                                   |
| aof_last_write_status        | 上次aof写入状态                                              |
| aof_last_cow_size            | AOF过程中父进程与子进程相比执行了多少修改(包括读缓冲区，写缓冲区，数据修改等)。 |



