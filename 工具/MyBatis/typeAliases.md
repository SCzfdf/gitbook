# typeAliases

[mybatis XML配置](https://mybatis.org/mybatis-3/zh/configuration.html#typeAliases)

​		

类型别名可为 Java 类型设置一个缩写名字. 它仅用于 XML 配置，意在降低冗余的全限定类名书写

​		

别名有3种方式

1. 默认

   在没有注解的情况下，会使用Bean的首字母小写的非限定类名来作为它的别名

2. xml配置

   ```xml
   <typeAliases>
       <!-- <typeAlias alias="user" type="com.test.User" /> 针对单个类 -->
       <package name="com.test"/> <!-- 针对一个包 -->
   </typeAliases>
   ```

3. 注解

   ```java
   @Alias("author")
   public class Author {}
   ```



​			

配置完成之后就可以再xml中使用

```xml
<resultMap id="BaseResultMap" type="user"></resultMap>
```

