# StopWatch_lang3

StopWatch是用于代码执行时间的监控

常用的StopWatch有2个, 一个是apache lang3, 一个是spring framework

spring 的api更加易用. 但是不一定所有项目都会用到spring. 相比之下lang3比较通用

​		

[Java开发利器Commons Lang之计时器StopWatch](https://www.jianshu.com/p/9e13f3182de1)

​		

## 示例代码

```java
public static void main(String[] args) throws InterruptedException {
    // 计时测试
    StopWatch stopWatch = StopWatch.createStarted();
    Thread.sleep(2000);
    System.out.println(stopWatch.getTime()); // 2001

    // 重置测试，重置之后，不再计时
    stopWatch.reset();
    Thread.sleep(2000);
    System.out.println(stopWatch.getTime()); // 0

    // 重新启动重置之后的计时器
    stopWatch.start();
    Thread.sleep(2000);
    System.out.println(stopWatch.getTime()); // 2006

    // 暂停计时
    stopWatch.suspend();
    Thread.sleep(2000);
    System.out.println(stopWatch.getTime()); // 2006

    // 恢复计时
    stopWatch.resume();
    Thread.sleep(2000);
    System.out.println(stopWatch.getTime()); // 4006

    // 停止计时测试
    stopWatch.stop();
    Thread.sleep(2000);
    System.out.println(stopWatch.getTime()); // 4006
}
```



## 相关api

```java
// 启停API
start(); // 启动计时
    
createStarted(); // StopWatch的静态方法，创建和启动计时器二合一

stop(); // 停止计时

reset(); // 重置计时器. 若要启动计时需要重新调用start()


// 暂停,恢复API
suspend(); // 暂停计时

resume(); // 恢复计时

split(); // 标记. 可以通过getSplitTime()获取开始计时到最后一次调用split()的时间

unsplit(); // 清除标记


// 获取结果API
getTime(); // 获取总耗时

getSplitTime(); // 获取开始计时到最后一次调用split()的时间

getStartTime(); // 获取开始计时的时间戳
```

