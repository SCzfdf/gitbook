# redis安装

[Linux 安装部署Redis](https://www.jianshu.com/p/67c672a53b2d)



## redis 启动关闭

```shell
# server启动：./redis-server --configurekey1 configurevalue1
./redis-server redis.conf
       
# server关闭 (这种方式是比较优雅的关闭Redis server)
./redis-cli shutdown [nosave|save]

# client启动
./redis-cli -h host -p port
```



## linux 

###下载安装包

从redis[官网](https://redis.io/download)获取最新的

```shell
wget http://download.redis.io/releases/redis-5.0.7.tar.gz
```



###解压编译

解压

```shell
tar -zxvf redis-5.0.7.tar.gz
rm redis-5.0.7.tar.gz
```

编译(进入解压的目录)

```shell
make
```

