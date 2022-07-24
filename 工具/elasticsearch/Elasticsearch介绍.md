# Elasticsearch介绍



## ES目录

```properties
bin: 常用脚本
conf: 配置
jdk: 自带的jkd
lib/modules: 程序包
plugin: 自有插件和第三方插件
data: 默认数据
logs: 默认日志

conf.elasticsearch.yml: 核心配置文件, 节点实例属性参数
jvm.options: 配置堆栈参数等
log4j2.properties: 日志常规配置
其他: 账户安全/动态生成/keystore安全文件
```



## ES配置文件

### elasticsearch.yml

 ```properties
# 集群名称，默认可以不修改,此处
cluster.name: elkO1
# 节点名称，必须修改﹐默认修改为当前机器名称，若是多实例则需要区分
node.name: ${HOSTNAME}-9200
# IP地址，默认是local，仅限本机访问，外网不可访问，设置0.0.0.0通用做法
network.host:0.0.0.0
# http和tcp端口，默认9200，9300，建议明确指定
http.port: 9200
transport.port: 9300
# 数据目录与日志目录，默认在当前运行程序下，生产环境需要指定
path.data: /elk/9200/data
path.logs: /elk/9200/logs
# 内存交换锁定(内存不足时使用硬盘)，此处需要操作系统设置才生效
bootstrap.memory_lock: true
# 防止批量删除索引
action.destructive_requires_name: true
# 设置处理器数量，默认无需设置，单机器多实例需要设置
# 多实例的话核数/实例数. 或者一个是master节点一个是salve节点master可以多一点
node.processors: 4


# 默认单节点集群模式
discovery.type: single-node

# 集群发现配置
# 节点发现, 至少指向其中一个集群节点即可, 后续会自动发现
discovery.seed_hosts: ["192.168.86.106:9300"]
# 集群初始化时的引导节点节点, 只需要一个节点配置即可. 后续加入节点可以不配置
# 但是如果其他节点之前配置过自己为initial_master并且成功成为master, 那么需要加入其他节点时可能也不会成功, 需要删除data/node目录(作为master的原信息)
cluster.initial_master_nodes: ["192.168.86.106:9300"]


# 设置禁用机器学习功能部分电脑CPU不支持SSE4.2+，启动会出错，
xpack.ml.enabled: false




# 以下是没有暴露出来的高级设置. es默认情况下的默认设置已经足够
# ====================节点通讯=======================
# 节点通讯 间隔
discovery.find_peers_interval: 1s
# 节点探查 间隔
discovery.probe.connect_timeout: 3s
# 节点探查捂手确定 超时时间
discovery.probe.handshake_timeout: 1s
# 节点之间请求请求确认恢复的 超时时间
discovery.request_peers_timeout: 3s
# 节点域名解析 并发数
discovery.seed_resolver.max_concurrent_resolvers: 10
# 节点域名解析 超时时间
discovery.seed_resolver.timeout: 5s

# ====================集群节点选举投票=======================
# 集群投票节点移除后是否自动从集群中移除. 默认true(自动移除)
# false: 关闭集群节点后需要手动API操作进行移除
cluster.auto_shrink_voting_configuration: true
# 集群选举失败时回退补偿时间. 一般不用修改.慎重
cluster.election.back_off_time: 100ms
# 集群节点选举持续时间 一般不用修改.慎重
# 调大此值集群选举时间过长
# 调小此值集群过于敏感
cluster.election.duration: 100ms
# 集群选举初始化确认超时时间
cluster.election.initial_timeout: 1000ms
# 集群选举最大超时时间
cluster.election.max_timeout: 10s

# ====================集群容错设置=======================
# 集群主节点确认 非主节点是否已经与集群脱离. 间隔时间1s
1scluster.fault_detection.follower_check.interval: 1s 
# 集群主节点确认 非主节点已经与集群脱离 超时时间. 默认10s 
cluster.fault_detection.follower_check.timeout: 10s 
# 集群主节点与非主节点失去连接之后,尝试连接次数,默认3 
cluster.fault_detection.follower_check.retry_count: 3
# 非主节点与主节点确认检查校验间隔时间,默认1s
cluster.fault_detection.leader_check.interval: 1s 
# 默认10s 
cluster.fault_detection.leader_check.timeout: 10s
# 默认3 
cluster.fault_detection.leader_check.retry_count: 3
# 非主节点与主节点确认,延迟超时时间,默认90
scluster.follower_lag.timeout: 90s
# 集群新节点加入集群,确认失败,超时时间,默认30s
cluster.join.timeout: 30s
# 移除集群投票选举节点,最大数量,默认10
cluster.max_voting_config_exclusions: 10

# ====================集群状态发布=======================
# 主节点与非主节点之间,确认集群所有状态更新已经通知到所有节点,并得到响应,
# 记录某个节点是否响应慢,超时时间,默认10s
cluster.publish.info_timeout: 10s
# 主节点与非主节点之间,确认集群所有状态更新已经通知到所有节点,并得到响应,超时时间,默认60s
cluster.publish.timeout: 60s

# ====================集群主节点异常默认操作=======================
# 集群主节点异常,读写操作全部停止
cluster.no_master_block: all
# 集群主节点异常,写操作停止
cluster.no_master_block: write
 ```



### jvm.options

```yml
# 内存堆栈大小，默认4GB
# 不能超过1/2系统内存，多实例要谨慎，
# 不能大于等于32G!
-xmslg
-Xmx1g
# 如果系统用的JDK是8-13 垃圾回收那么就是用CMS, 如果大于14就是用G1
8-13:-XX:+UseConcMarkSweepGC
8-13:-XX:CMSInitiatingOccupancyFraction=75
8-13:-XX:+UseCMSInitiatingOccupancyOnly
14-:-XX:+UseG1GC
14-:-XX:G1ReservePercent=25
14-:-XX:InitiatingHeapOccupancyPercent=30
```





## ES安装方式选择

直接购买云服务(ES云, 阿里云, 一般都有, 购买了就可以直接用)

官网下载离线gz包/rpm包等, 可以按自己熟悉的方式下载安装

Docker

直接丢给公司运维, 叫他装....



## ES必备系统环境配置

1. 关闭防火墙

   ```shell
   service firewalld stop
   ```

   es相关程序需要开启很多端口(http, tcp), 还有部分的监控beats. 如果是单机多实例就更多了

2. 设置虚拟内存大小(mmpfile内存需要)

3. 禁用内存交换(内存不够交换到磁盘. 内存锁定)

   ```properties
   # /etc/sysctl.conf
   # 设置虚拟内存大小
   vm.max_map_count=262144
   # 禁用内存与硬盘交换
   vm.swappiness=1
   ```

4. 设置文件句柄数量(es索引有很多文件组成, 打开文件数量多)

5. 设置进程线程数量

   ```properties
   # /etc/security/limits.conf
   # 进程线程数
   * soft nproc 131072
   * hard nproc 131072
   # 文件句柄数
   * soft nofile 131072
   * hard nofile 131072
   # 内存锁定交换
   * soft memlock unlimited
   * hard memlock unlimited
   ```

6. 创建专用账号

   ```shell
   useradd elastic
   chown -R elastic:elastic /elastic/*
   ```

7. 设置jvm临时目录

   ```shell
   # /ect/
   export ES_TMPDIR=/elastic/jvm_tmpdir
   
   # 这个在es/config/jvm.options里会用到, 主要用于保存脚本类的临时文件
   # 如果不设置就会放到系统的临时文件夹中硬盘不够就会自动删除启动可能会异常
   ```

8. 设置JNA(Java Native Access)临时目录

   ```shell
   # 在es/config/jvm.options中配置. 也可以在启动是加上
   -Djna.tmpdir=/elastic/jna_tmpdir
   
   # es启动的时候需要使用JNA执行系统层面的指令
   # 默认临时目录会挂载在/tmp目录下, 有部分系统会限制引用挂载此目录
   ```





## 三方辅助工具插件

### elastic-head

很旧的工具...不过可以很清晰的看到索引分片在节点的分布情况

### elasticvue

很直观的看到集群节点信息, 切换集群查询. 简单的说就是一个轻量级的kibana

![image-20220426163443038](Elasticsearch%E4%BB%8B%E7%BB%8D.assets/image-20220426163443038.png)

### Cerebro

和elasticvue类似. 不过需要自己搭建, 支持docker

