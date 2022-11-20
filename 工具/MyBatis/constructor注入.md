# constructor注入

[Mybatis源码之美:3.5.5.配置构造方法的constructor元素](https://www.jianshu.com/p/90ae56493d38)

​		

使用`constructor`可以在创建对象时选用有参构造方法

`constructor`可以用在`resultMap`,`collection`,`association`,`case`这4个标签之下

使用`constructor`有2种方法

1. 在xml中使用(在那4个标签下)

   ```xml
   <resultMap id="DeptMap" type="dept">
       <constructor>
           <idArg column="did" javaType="int" name="dId"/> <!-- name可有可无, 如果没有则需要按顺序 -->
           <arg column="d_name" javaType="string" name="dName"/>
           <arg column="d_desc" javaType="string" name="dDesc"/>
       </constructor>
       <id property="dId" column="did" jdbcType="INTEGER"/>
       <result property="dName" column="d_name" jdbcType="VARCHAR"/>
       <result property="dDesc" column="d_desc" jdbcType="VARCHAR" />
   </resultMap>
   ```

2. 在Mapper文件的方法增加注解

   ```java
   @ConstructorArgs({
           @Arg(column = "dId", javaType = Integer.class),
           @Arg(column = "dName", javaType = String.class),
           @Arg(column = "dDesc", javaType = String.class)
   })
   Dept selectDeptById(@Param("did") String did);
   ```



如果需要指定name, 则还需要做开启name解析. 有2种方法可有开启

1. 在构造函数中添加`org.apache.ibatis.annotations.Param`注解
2. 在编译时增加`-parameters` 并启用 `useActualParamName` 选项（默认开启）来编译项目



