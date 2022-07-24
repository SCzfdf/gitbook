# 原生配置之mappers

[xml在resource文件夹中报错原因](https://www.cnblogs.com/JQloveJX/p/13455207.html)

[xml在java代码中报错解决方法](https://blog.csdn.net/qq_37186947/article/details/88601304)

​		

在学习时遇到个很奇怪的问题. 就是mappers如果使用package就会报`Invalid bound statement (not found)`

```xml
<mappers>
    <package name="com.sczfdf.mybatis.test.mapper"/> <!-- 这个不行 --> 
    <!-- <mapper resource="mapper/UserMapper.xml"/> 单独指定就可以 -->
</mappers>
```

找了几小时问题后发现出现`Invalid bound statement (not found)`是因为编译的xml不和mapper在同一文件夹...

把xml文件夹增加几个目录就好

![image-20220421151907900](%E5%8E%9F%E7%94%9F%E9%85%8D%E7%BD%AE%E4%B9%8Bmappers.assets/image-20220421151907900.png)

​			

还有一种是xml放在java代码中的. 这种大概率是没有把xml编译进去. 在pom文件添加插件即可

```xml
<build>
    <resources>
        <resource>
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.xml</include>
            </includes>
            <!--默认是true-->
            <!--<filtering>true</filtering>-->
        </resource>
    </resources>
</build>
```

