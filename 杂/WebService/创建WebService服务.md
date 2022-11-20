# 创建WebService 服务

[SpringBoot整合WebService服务](https://blog.csdn.net/sujin_/article/details/83865124)

[springboot整合webservice服务2](https://blog.csdn.net/qq_31451081/article/details/80783220)



cxf 默认服务在Host:port/services/***



## pom

```xml
<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web-services</artifactId>
        </dependency>

        <dependency>
            <groupId>org.apache.cxf</groupId>
            <artifactId>cxf-spring-boot-starter-jaxws</artifactId>
            <version>3.2.5</version>
        </dependency>

        <dependency>
            <groupId>org.apache.axis</groupId>
            <artifactId>axis</artifactId>
            <version>1.4</version>
        </dependency>

        <dependency>
            <groupId>wsdl4j</groupId>
            <artifactId>wsdl4j</artifactId>
            <version>1.6.3</version>
        </dependency>

        <dependency>
            <groupId>axis</groupId>
            <artifactId>axis-jaxrpc</artifactId>
            <version>1.4</version>
        </dependency>

        <dependency>
            <groupId>commons-discovery</groupId>
            <artifactId>commons-discovery</artifactId>
            <version>0.2</version>
        </dependency>
```



## Wbservice 接口

```java
import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebResult;
import javax.jws.WebService;

@WebService(name = "testService",
        targetNamespace = "http://service.webservicedemo.sxt.com")
public interface Wbservice {

    @WebMethod
    @WebResult()
    String helloService(@WebParam(name = "name") String name);

    @WebMethod
    String getAllBean();
}
```



##Wbservice 实现类

```java
/**
 * @author Created by 陈淦彬
 * @date 2020/2/17
 */
@WebService(name = "testService",
        targetNamespace = "http://service.webservicedemo.sxt.com",
        endpointInterface="com.cashway.cloud.manage.base.webservice.Wbservice"
)

@Component
public class WebserviceImpl implements Wbservice {
    @Override
    public String helloService(@WebParam(name = "name") String name) {
        return "hello "+name;
    }

    @Override
    public String getAllBean() {
        ArrayList<TestBean> list = new ArrayList<>();
        TestBean bean1 = new TestBean("zhangsan", "1");
        TestBean bean2 = new TestBean("lisi", "2");
        list.add(bean1);
        list.add(bean2);
        return JSONObject.toJSONString(list);
    }
}

---------------------------------
@Data
public class TestBean {
    private String name;
    private String id;

    public TestBean(String name, String id) {
        this.name = name;
        this.id = id;
    }
}
```



## WebConfig webService配置

```java
import com.cashway.cloud.manage.base.webservice.Wbservice;
import org.apache.cxf.Bus;
import org.apache.cxf.jaxws.EndpointImpl;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.annotation.Resource;

@Configuration
public class WebConfig {
    @Resource
    private Bus bus;

    @Resource
    private Wbservice service;

    @Bean
    public EndpointImpl endpoint() {
        EndpointImpl endpoint = new EndpointImpl(bus, service);
        // 和@WebService的name一样
        endpoint.publish("/testService");
        return endpoint;
    }
}
```



## WebConfig 调用方法

```java
public class T {
    public static void main(String[] args) throws Exception {
        t2();
    }
    
    // 调用无参WebService
	private static void t2() throws Exception {
        Call call = (Call) (new Service()).createCall();
        call.setTargetEndpointAddress(new URL("http://localhost:8303/services/testService/getAllBean"));
        call.setOperationName(new QName("http://service.webservicedemo.sxt.com", "getAllBean"));
        call.setTimeout(30000);
        Object invoke = call.invoke(new Object[]{});
        System.out.println(invoke);
    }

    // 调用有参且使用了注解命名属性的WebService
    private static void t3() throws Exception {
        Call call = (Call) (new Service()).createCall();
        call.setTargetEndpointAddress(new URL("http://localhost:8303/services/testService/helloService"));
        call.setOperationName(new QName("http://service.webservicedemo.sxt.com", "helloService"));
        call.addParameter("name", XMLType.XSD_STRING, ParameterMode.IN);
        call.setReturnType(XMLType.XSD_STRING);
        call.setTimeout(30000);
        String re = (String) call.invoke(new String[]{"周玉磊"});
        System.out.println(re);
    }

    // 动态调用
    private static void t4() throws Exception {
        //创建动态客户端
        JaxWsDynamicClientFactory factory = JaxWsDynamicClientFactory.newInstance();
        Client client = factory.createClient("http://localhost:8303/services/testService/helloService?wsdl");
        // 需要密码的情况需要加上用户名和密码
        //client.getOutInterceptors().add(new ClientLoginInterceptor(USER_NAME,PASS_WORD));
        HTTPConduit conduit = (HTTPConduit) client.getConduit();
        HTTPClientPolicy httpClientPolicy = new HTTPClientPolicy();
        //连接超时
        httpClientPolicy.setConnectionTimeout(2000);
        //取消块编码
        httpClientPolicy.setAllowChunking(false);
        //响应超时
        httpClientPolicy.setReceiveTimeout(120000);
        conduit.setClient(httpClientPolicy);
        //设置拦截器
        //client.getOutInterceptors().addAll(interceptors);
        try{
            Object[] objects = new Object[0];
            // invoke("方法名",参数1,参数2,参数3....);
//            objects = client.invoke("helloService", "sujin");
            objects = client.invoke("getAllBean");
            System.out.println("返回数据:" + objects[0]);
        }catch (Exception e){
            e.printStackTrace();
        }
    }
}
```

