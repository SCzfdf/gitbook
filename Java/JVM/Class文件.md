# Class文件

Class文件是JVM能识别**16进制文件**, 由`javac`命令编译而成



## Javac编译过程

[JVM编译器种类](https://blog.csdn.net/qq_45662823/article/details/124949631)

[java前端编译和后端编译理解](https://blog.csdn.net/qq_35207086/article/details/123758442)

将java文件转换为class文件的操作也称之为**前端编译**, 前端指的是在JVM执行之前. 

前端编译仅仅是一个**翻译**的操作, 对代码执行效率几乎没有优化. 可以用于实现一些语法糖(泛型, 内部类等)

翻译过程如下:

![前端编译过程](Class%E6%96%87%E4%BB%B6.assets/6d1814aad3342c64f2ebc17214500891.png)



## 解析Class文件

[官网class format](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html)

从官方文档中可以找到下面的class文件格式说明. 

一个`class`文件由一个 8 位字节流组成。所有 16 位、32 位和 64 位量都是通过分别读取两个、四个和八个连续的 8 位字节来构造的

类型`u1`、`u2`和`u4`分别表示无符号的一、二或四字节数量

```class
ClassFile {
    u4             magic; // 标明class文件的解析格式, 为常量cafe babe
    u2             minor_version; // 编译器的主要版本
    u2             major_version; // 编译器的次要版本
    u2             constant_pool_count; // 常量池计数, constant_pool数-1
    cp_info        constant_pool[constant_pool_count-1]; // 常量池
    u2             access_flags; // 访问标识
    u2             this_class; // 该class文件定义的类或接口
    u2             super_class; // 父类
    u2             interfaces_count; // 接口数
    u2             interfaces[interfaces_count]; // 接口集合
    u2             fields_count; // 字段数
    field_info     fields[fields_count]; // 字段集合
    u2             methods_count; // 方法数
    method_info    methods[methods_count]; // 方法集合
    u2             attributes_count; // 常量数
    attribute_info attributes[attributes_count]; // 常量集合
}
```



### 尝试解析class文件

1. 在任意位置创建`User.java`文件, 内容如下:

   ```java
   public class User {
       private Integer age;
       private String name = "Jack";
       private Double salary = 100.0;
       private static String address;
   
       public void say() {
           System.out.println("Jack Say...");
       }
   
       public static Integer calc(Integer op1, Integer op2) {
           op1 = 3;
           Integer result = op1 + op2;
           return result;
       }
   
       public static void main(String[] args) {
           System.out.println(calc(1, 2));
       }
   }
   ```

2. 使用`javac User.java`编译文件

3. 使用16进制编译器打开`User.class`文件

   ```
   -------------------magic
   // 按照上面的ClassFile解析
   // u4 magic;
   CA FE BA BE 
   
   -------------------minor_version+major_version
   // u2 minor_version 编译器的主要版本
   // u2 major_version 编译器的次要版本
   // 主要版本+次要版本可以确定编译该class文件的JDK版本
   // 这里3D转10进制为61, 为JDK17
   00 00 00 3D
   
   -------------------constant_pool_count
   // u2 constant_pool_count 常量池计数(需要-1)
   // 这里43转10进制为67, -1后为66, 表示有66个常量
   // 这里的常量并不是JVM常量池的常量. 这里的常量为各种字符串常量、类和接口名称、字段名称和其他常量
   00 43
   
   -------------------constant_pool[constant_pool_count-1] 01
   // cp_info constant_pool[constant_pool_count-1]; 常量池
   // 这里的常量池长度时动态的(cp_info), 需要按照对应文档解析, 文档地址如下
   // https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html#jvms-4.4
   // 在文档中可以看到constant pool的格式为
   // cp_info {
   //     u1 tag; // 常量池标签/类型
   //     u1 info[]; // 常量池信息
   // }
   
   // cp_info u1 tag 
   // 这里0A转10进制为10. 对于tag为CONSTANT_Methodref
   // CONSTANT_Methodref有对应的结构. 结构如下
   // CONSTANT_Methodref_info {
   //    u1 tag; // 常量池标签/类型, 也即是cp_info的tag
   //    u2 class_index; // 类索引
   //    u2 name_and_type_index; // 名称和类型索引
   // }
   0A 
   // class_index 为02
   00 02 
   // name_and_type_index 为03
   00 03
   
   // cp_info u1 info[]
   
   -------------------constant_pool[constant_pool_count-1] 02
   // 07转10进制为7 表示CONSTANT_Class
   // 对应结构为
   // CONSTANT_Class_info { 
   //    u1 tag；
   //    u2 name_index；
   // }
   07 
   // name_index 为04
   00 04
   
   -------------------other
   0C 00 05 00 06 01 00 10 6A 61 76 61 2F 6C 
   61 6E 67 2F 4F 62 6A 65 63 74 01 00 06 3C 69 6E 69 74 3E 01 00 03 28 29 56 08 00 08 01 00 04 4A .....未完
   
   ```
   
   > constant_pool: 用于保存各种字符串常量、类和接口名称、字段名称和其他常量

​		

上面的步骤解析太麻烦了, java为我们提供了一个简单的命令`javap`, 执行一下命令导出

```shell
javap -c -p -v User.class > User.txt
```

导出文件如下

> 从截图中可以看到, 
>
> minor_version+major_version=61
>
> 常量池中第一个常量为Methodref类型, 对应class_index=2, name_and_type_index=3
>
> 常量池中第二个常量为Class类型, 对应name_index=4 和上面的解析结果一致

![image-20220627124936042](Class%E6%96%87%E4%BB%B6.assets/image-20220627124936042.png)



## 

