# StopWatch_spring

[Spring计时器StopWatch使用](https://blog.csdn.net/gxs1688/article/details/87185030)

​		

## 示例代码

```java
public static void main(String[] args) throws InterruptedException {
    StopWatch stopWatch = new StopWatch("test stop watch title");

    stopWatch.start("test stop watch1");
    Thread.sleep(100);
    stopWatch.stop();

    stopWatch.start("test stop watch2");
    Thread.sleep(100);
    stopWatch.stop();

    stopWatch.start("test stop watch3");
    Thread.sleep(100);
    stopWatch.stop();

    System.out.println("总耗时: " + stopWatch.getTotalTimeSeconds());
    for (StopWatch.TaskInfo taskInfo : stopWatch.getTaskInfo()) {
        System.out.println(taskInfo.getTaskName() + " : " + taskInfo.getTimeMillis());
    }
    System.out.println();System.out.println();

    System.out.println(stopWatch.prettyPrint());
}
```

输出

> 总耗时: 0.327
> test stop watch1 : 110
> test stop watch2 : 109
> test stop watch3 : 108
>
> 
>
> StopWatch 'test stop watch title': running time (millis) = 327
> 分隔符-----------------------------------------
> ms     %     Task name
> 分隔符-----------------------------------------
> 00110  034%  test stop watch1
> 00109  033%  test stop watch2
> 00108  033%  test stop watch3



​		

