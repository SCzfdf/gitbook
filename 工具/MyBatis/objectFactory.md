# objectFactory

[mybatis XML配置](https://mybatis.org/mybatis-3/zh/configuration.html#objectFactory)

​		

每次 MyBatis 创建结果对象的新实例时, 它都会使用一个对象工厂(ObjectFactory)实例来完成实例化工作

默认的对象工厂需要做的仅仅是实例化目标类, 要么通过默认无参构造方法, 要么通过存在的参数映射来调用带有参数的构造方法

如果想覆盖对象工厂的默认行为, 可以通过创建自己的对象工厂来实现

```java
public class ExampleObjectFactory extends DefaultObjectFactory {
  public Object create(Class type) {
    return super.create(type);
  }
  public Object create(Class type, List<Class> constructorArgTypes, List<Object> constructorArgs) {
    return super.create(type, constructorArgTypes, constructorArgs);
  }
  public void setProperties(Properties properties) {
    super.setProperties(properties);
  }
  public <T> boolean isCollection(Class<T> type) {
    return Collection.class.isAssignableFrom(type);
  }
}
```

随后在xml中指定

```xml
<objectFactory type="org.mybatis.example.ExampleObjectFactory">
  <property name="someProperty" value="100"/>
</objectFactory>
```



> 不过想不通什么场景需要去替换默认的....

