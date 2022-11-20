# 借助Idea调试远程项目

[远程debug](https://blog.csdn.net/caoli201314/article/details/117914896)

​		

## 远程DEBUG的必要性

开发环境和生产环境的差异性, 一些bug很难在开发环境复现. 

日志比较多的情况要分析日志. 如果日志比较少就很难分析了.

​		

## 配置

1.   添加依赖, 需要spring-web 2.2.6.RELEASE以上

     ```xml
     <dependency>
     	<groupId>org.springframework.boot</groupId>
     	<artifactId>spring-boot-starter-web</artifactId>
         <version>2.2.6.RELEASE</version>
     </dependency>
     ```

2.   在idea中添加远程调试

     ![image-20220823142906527](%E5%80%9F%E5%8A%A9Idea%E8%B0%83%E8%AF%95%E8%BF%9C%E7%A8%8B%E9%A1%B9%E7%9B%AE.assets/image-20220823142906527.png)

3.   将生成的命令复制到启动命令里

     ```shell
     java -jar -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=8089 test.jar
     ```

4.   也可以通过插件打包将命令打进去(未测试..)

     ```xml
     <build>
     	<plugins>
     		<plugin>
     			<groupId>org.springframework.boot</groupId>
     			<artifactId>spring-boot-maven-plugin</artifactId>
     			<configuration>
     				<jvmArguments>-Xdebug -Xrunjdwp:transport=dt_socket,address=5005,server=y,suspend=n</jvmArguments>
     			</configuration>
     		</plugin>
     	</plugins>
     </build>
     ```

5.   启动服务并在idea中连接. 连接成功即可正常调试

