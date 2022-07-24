# RDB

[redis之BGSAVE堵塞redis原因(fork)](https://www.jianshu.com/p/4425475fb596)

[redis阻塞bgsave与bsrewriteaof](https://www.cnblogs.com/xiaochina/p/6288717.html)

## 触发方式

1. `save` (同步)命令
2. `bgsave` (异步)命令
3. 自动触发

### save

直接在redis主线程执行创建RDB的动作, 在创建RDB文件期间redis是被 **阻塞** 住的

redis先会创建一个临时的RDB文件, 生产完毕就把老文件替换

### bgsave

redis会fork出一个子进程, 让子进程来执行创建RDB文件的操作. 对于Client来说会马上返回一个`backgroud saveing satrted` . 在子进程创建期间redis 一般不会被阻塞

> 子进程在触发RDB, 主进程在AOF. 然后主进程就会被子进程阻塞了

### 自动触发

在配置文件中配置`save {x秒} {y写次数}` , 表示每当x秒有y个写操作就触发一次更新



## 选择

当redis 只有几GB时使用快照来保存数据没有任何问题, redis会创建子进程并将数据保存在硬盘里, 生成快照比读这句话的时间还要短. 但随着redis 占用内存越来越多, 持久化也会越来越耗时. 

一般来说save比bgsave要快(因为没有子进程争抢资源, 并且创建子进程也需要时间, 而且内存占用比越大时间越长)

> Redis实战: 68GXen虚拟机上对一个50GB的Redis执行save命令需要3~5分钟, 而使用bgsave则需要15~20分钟

所以在数据量大的情况最好 **关闭自动触发** 用一个定时脚本在用户不活跃的时候在一个从节点执行save命令. 或者在从节点的从节点部署一台空闲机器自动保存RDB(前面是可靠的, 后面的大概也可行~)



