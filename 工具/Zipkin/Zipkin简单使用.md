# Zipkin简单使用

[Zipkin Server下载与搭建](http://www.imooc.com/article/291572)

[分布式链路追踪](https://www.jianshu.com/p/07cf4093536a?from=singlemessage)



## 分布式链路追踪

作用:

1.  可以快速在多个服务找到依赖的接口出了问题
2.  在性能测试中, 可以快速获取接口所依赖的一系列服务中的调用性能



## 使用Zipkin

1.  安装Zipkin服务

    ```shell
    curl -sSL https://zipkin.io/quickstart.sh | bash -s
    ```

2.  安装依赖(SpringBoot)

    ```xml
    <dependency>
    	<groupId>org.springframework.cloud</groupId>
    	<artifactId>spring-cloud-starter-zipkin</artifactId>
    </dependency>
    ```

    >   Zipkin 完美整合SpringBoot, 只需要在各个服务中加入依赖即可

3.  访问Zipkin

    http://127.0.0.1:9411



