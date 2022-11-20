# typeHandlers

[mybatis XML配置](https://mybatis.org/mybatis-3/zh/configuration.html#typeHandlers)

[Mybatis自定义TypeHandler](https://mybatis.org/mybatis-3/zh/configuration.html#typeHandlers)

​		

MyBatis在设置预处理语句中的参数或从结果集中取出一个值时, 都会用类型处理器将获取到的值以合适的方式转换成 Java 类型

​		

## 自定义Handler

1. 继承BaseTypeHandler实现

   ```java
   // 将Java中的List<Integer>转换为Sql中的String
   public class MyTypeHandler extends BaseTypeHandler<List<Integer>> {
       
       // 设置非空参数时的回调
       public void setNonNullParameter(PreparedStatement ps, int i, List<Integer> integers, JdbcType jdbcType) throws SQLException {
   
           StringBuilder sb = new StringBuilder();
           for (Integer num : integers) {
               sb.append(num).append(",");
           }
           ps.setString(i, sb.toString().substring(0, sb.toString().length() - 1));
   
       }
   
       // 获取到结果(可为空)时的回调
       public List<Integer> getNullableResult(ResultSet rs, String s) throws SQLException {
           String[] split = rs.getString(s).split(",");
   
           return Arrays.stream(split).map(str -> Integer.valueOf(str)).collect(Collectors.toList());
       }
   
       // 获取到结果(可为空)时的回调
       public List<Integer> getNullableResult(ResultSet rs, int i) throws SQLException {
           String[] split = rs.getString(i).split(",");
   
           return Arrays.stream(split).map(str -> Integer.valueOf(str)).collect(Collectors.toList());
       }
   
       // 获取到结果(可为空)时的回调
       public List<Integer> getNullableResult(CallableStatement cs, int i) throws SQLException {
           String[] split = cs.getString(i).split(",");
   
           return Arrays.stream(split).map(str -> Integer.valueOf(str)).collect(Collectors.toList());
       }
   }
   ```

2. 指定处理类型

   1. 注解方式

      在类中添加注解

      ```java
      @MappedJdbcTypes(JdbcType.VARCHAR) // JDBC类型
      @MappedTypes(String.class) // JAVA类型
      public class MyTypeHandler extends BaseTypeHandler<List<Integer>> {}
      ```

   2. xml方式

      在注册时一同绑定

      ```xml
      <typeHandlers>
        <typeHandler handler="com.test.MyTypeHandler" jdbcType="VARCHAR" javaType="String"/>
      </typeHandlers>
      ```

   3. 在使用时绑定

3. 注册

   1. 原生注册

      ```xml
      <typeHandlers>
        <typeHandler handler="org.test.MyTypeHandler"/>
      </typeHandlers>
      ```

   2. spring注册

      ```yml
      mybatis:
        type-handlers-package: com.git.hui.boot.mybatis.handler
      ```

      或者读取mybatis的配置文件

      ```yml
      mybatis:
        config-location: classpath:mybatis-config.xml
      ```

   3. 在使用时绑定(临时)

4. 使用

   如果是全局注册的话直接就可以用了. 如果需要只针对某个属性也有2种临时配置方法

   1. resultMap中指定

      ```xml
      <resultMap type="org.apache.ibatis.submitted.rounding.User" id="usermap2">
      	<id column="id" property="id"/>
      	<result column="name" property="name"/>
      	<result column="funkyNumber" property="funkyNumber"/>
      	<result column="roundingMode" property="roundingMode" 		           typeHandler="org.apache.ibatis.type.EnumTypeHandler"/>
      </resultMap>
      <select id="getUser2" resultMap="usermap2">
      	select * from users2
      </select>
      ```

   2. insert语句中指定

      ```xml
      <insert id="insert2">
          insert into users2 (id, name, funkyNumber, roundingMode) values (
          	#{id}, #{name}, #{funkyNumber}, #{roundingMode, typeHandler=org.apache.ibatis.type.EnumTypeHandler}
          )
      </insert>
      ```

   

   ## 枚举处理器

   若想映射枚举类型 `Enum`，则需要从 `EnumTypeHandler`或者 `EnumOrdinalTypeHandler`中选择一个来使用

   `EnumTypeHandler`会将枚举名与数据库中的VARCHAR 或任何兼容的字符串类型对应. 储存的是**枚举名**

   `EnumOrdinalTypeHandler`会将枚举下标与任何兼容的 `NUMERIC` 或 `DOUBLE`类型. 储存的是**枚举下标**

   


