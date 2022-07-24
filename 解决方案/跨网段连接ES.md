# 跨网段连接ES

背景: ES集群在192.168网段. 网络组将部分服务迁移至172.16网段. 导致不能访问es

大概能解决的方案:

1. 直接设置`network.host=0.0.0.0`

   肯定可以, 但是安全组会要求修改. 如果没有安全要求可以直接用

2. 通过nginx转发.

   因为因为es的java客户端底层也是通过http连接的. ng可以很好的跨网段转发, 因此大概可行. 不过要引用个中间件. 不太好

3. 修改`netword.host`



最终方案是通过修改`netword.host`解决的, 之前使用的是本地ip. 通过ip访问

查看es[官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html)发现

`netword.host`能接受以下枚举

* `_local_`

  本地回环地址

* `_site_`

  Any site-local addresses on the system, for example `192.168.0.1`

  系统上的本地站点地址

* `_global_`

  Any globally-scoped addresses on the system, for example `8.8.8.8`.

  系统上的任何全局范围的地址

* `_[networkInterface]_`

  Use the addresses of the network interface called `[networkInterface]`. For example if you wish to use the addresses of an interface called `en0` then set `network.host: _en0_`.

  感觉像是直接指定网卡

* `0.0.0.0`

  任何网络接口

​		

当时感觉可以在`_global_`上做文章, 开始查询源码

找到`NetworkUtils.getGlobalAddresses()`. 发现`_global_`=`0.0.0.0`+`_site_`+`link`

![image-20220520182222750](%E8%B7%A8%E7%BD%91%E6%AE%B5%E8%BF%9E%E6%8E%A5ES.assets/image-20220520182222750.png)

....思路错误

不过有点好奇`_site_`+`link`是什么东西. 于是去百度, 发现

[IPv6 tutorial – Part 6: Site-local addresses and link-local addresses](https://www.cnblogs.com/chucklu/p/4838288.html)

[理解链路本地址与站点本地地址](https://blog.csdn.net/tjhon/article/details/12436175)

`_site_`属于保留网段. `10.0.0.0/8`, `172.16.0.0/12`和`192.168.0.0/16`都可以访问到

`link`则是指dhcp失败时自动分配的ip 范围是`169.254.0.1 ~ 169.254.255.254`

​		

正好, 服务器的172.16网段可以被`_site_`访问!

​		

然后觉得site的三个网段有点熟悉. 就又去百度了下, 发现这3个网段就是局域网的网段....

平时大多都用192.168.x.x没反应过来....

> 后面咨询一些大佬, 说可以用`network.bind_host`和`network.publish_host`分别指定来达到相同的效果


