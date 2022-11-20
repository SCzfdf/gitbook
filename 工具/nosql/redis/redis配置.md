# redis配置

[redis 配置文件详解](https://www.jianshu.com/p/41f393f594e8)

[redis 配置文件详解](https://yq.aliyun.com/articles/648226)

[redis最全配置讲解](https://www.cnblogs.com/metu/p/9609604.html)



[Redis的bind的误区](https://blog.csdn.net/cw_hello1/article/details/83444013)

[Redis的bind参数理解](https://blog.csdn.net/u012560213/article/details/90511265)

[redis连接超时原因 (tcp_backlog)](https://www.cnblogs.com/tinywan/p/9643022.html)

[Redis 优化之 tcp-backlog](https://my.oschina.net/TOW/blog/684914)



```shell
################### 引用 ###################
# 使用模板配置文件
# 模板配置文件不会被 config rewrite
# 模板文件放在前面会被后面的主配置覆盖, 放在最后面则不会
include /path/to/local.conf
include /path/to/other.conf

################### 网络 ###################
# 配置的是本机对应的监控网卡的ip地址
# 只要知道127.0.0.1和0.0.0.0(不配置)分别是本机和全部就基本足够了, 具体看参考
bind {ip}

# 是否开启保护模式(开启了如果没有配置bind或者密码则只允许本机访问)
# 不应该靠保护模式来控制访问redis的机器, 应该依赖防火墙和密码, 保护模式只是锦上添花
protected-mode {no/yes}

# redis占用的端口
port {port}

# 此参数确定了TCP连接中已完成队列(完成三次握手之后)的长度(高并发下要增大这个值)
# 此外还要调整linux的内核参数tcp_max_syn_backlog 和somaxconn
# 修改/etc/sysctl.conf文件(永久修改)
# echo 2048 > /proc/sys/net/core/somaxconn(重启恢复)
tcp-backlog {num}

#配置unix socket来让redis支持监听本地连接。
unixsocket /var/run/redis/redis.sock
#配置unix socket使用文件的权限
unixsocketperm 700

# 关闭空闲的客户端(0禁止关闭)
timeout {second:0}

# 检查空闲连接是否存活
# 如果值不为0 则设置SO_KEEPALIVE选项来向空闲连接的客户端发送ACK
# 作用: 1.检查已经中断的连接 2.从网络角度看,连接是处于中间的(...看原文吧)
# 要关闭这个连接需要两倍的这个时间值
tcp-keepalive {second:300}

################### 通用 ###################
# 是否在后台执行，yes：后台运行；no：不是后台运行
daemonize yes

# 是否通过upstart或systemd管理守护进程
supervised {no|upstart|systemd|auto}

# redis的进程文件
pidfile {filePath}

# 指定了服务端日志的级别notice(适当的日志级别,适合生产环境)
loglevel {debug|verbose|notice|warn}

# 日志文件路径空的话会输出到/dev/null
logfile {logPath}

# 是否把日志输出到系统日志(下面2个都是依赖项)
syslog-enabled no
# syslog的标识符。
syslog-ident redis
# 日志的来源, 必须是一个用户或者是local0 ~ local7之一
syslog-facility local0

#数据库的数量，默认使用的数据库是DB 0。可以通过”SELECT “命令选择一个db
databases 16

# 是否总是显示logo...
always-show-logo yes
```

