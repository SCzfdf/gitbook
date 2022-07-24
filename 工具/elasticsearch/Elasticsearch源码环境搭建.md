# Elasticsearch源码环境搭建



## 环境搭建

1. 去github下载源码和运行包(v7.10.2)

   https://github.com/elastic/elasticsearch/releases/tag/v7.10.2

2. 下载JDK15(v7.10.2基于15)并配置好. 在运行包中有个JDK目录, 是官方调优过的, 可以在那里用命令查看当前es使用的是哪个版本的JDK

3. 下载Gradle-6.6.1(源码包里也有指定的Gradle版本`.\gradle\wrapper\gradle-wrapper.properties`). 可能不需要, 因为我用idea他会自己下一个.....如果他那个下载不下来可以更改wrapper.properties里的包装地址

   > Gradle需要配置2个环境变量
   >
   > GRADLE_HOME Gradle的位置
   >
   > GRADLE_USER_HOME 下载包的地址

4. ![image-20220425202144048](Elasticsearch%E6%BA%90%E7%A0%81%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/image-20220425202144048.png)

   ![image-20220425205946497](Elasticsearch%E6%BA%90%E7%A0%81%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/image-20220425205946497.png)

> 感觉在idea里指定就行了...不用特定去下载和配置



## 源码启动

1. 增加启动参数

   ```shell
   # 运行包的路径
   -Des.path.conf=E:\Java\es\elasticsearch-7.10.2\config # 此时用的就是运行包的配置了
   -Des.path.home=E:\Java\es\elasticsearch-7.10.2\
   ```

2. 在IDEA中修改配置

   ![img](Elasticsearch%E6%BA%90%E7%A0%81%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/modb_20210809_06d0f87a-f910-11eb-8882-00163e068ecd.png)

3. 修改JDK/conf/security/java.policy

   ```txt
   # 在底部增加 跳过安全检查
       permission java.lang.RuntimePermission "createClassLoader";
       permission java.lang.RuntimePermission "setContextClassLoader";
   ```

   > 只要报access denied ("java.lang.RuntimePermission" "setContextClassLoader")就可以加

4. 启动server服务下org.elasticsearch.bootstrap.Elasticsearch就可以正常启动了. 可以访问http://localhost:9200/查看

