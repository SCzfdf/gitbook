# WatchService

[watchService例子](http://www.zzvips.com/article/133390.html)

[对overflow的处理](https://stackoverflow.com/questions/39076626/how-to-handle-the-java-watchservice-overflow-event)

​		

WatchService是JDK内置的一个监控本地文件改变的类, 多用于配置文件热更新

值得注意的是

​		

## 示例代码

```java
public static void main(String[] args) throws IOException {
    WatchService watchService = FileSystems.getDefault().newWatchService();

    Path path = Paths.get("E:\\temp");
    // 将目录注册到监听服务中, 监听事件的创建/修改/删除
    path.register(watchService,
            StandardWatchEventKinds.ENTRY_CREATE,
            StandardWatchEventKinds.ENTRY_MODIFY,
            StandardWatchEventKinds.ENTRY_DELETE,
            StandardWatchEventKinds.OVERFLOW
    );

    Thread thread = new Thread(() -> {
        try {
            WatchKey watchKey;
            do {
                // take()是阻塞的
                watchKey = watchService.take();

                List<WatchEvent<?>> watchEvents = watchKey.pollEvents();
                for (WatchEvent<?> event : watchEvents) {
                    // 根据事件类型采取不同的操作。。。。。。。
                    System.out.printf("[%s]文件发生了[%s]事件%n",
                            (path + File.separator + event.context()), event.kind()
                    );
                }

            } while (watchKey.reset());

        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    });
    thread.setDaemon(false);
    thread.start();

    // 增加jvm关闭的钩子来关闭监听
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
        try {
           watchService.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }));
}
```

输出

> [E:\temp\zxczxc]文件发生了[ENTRY_CREATE]事件
> [E:\temp\新建 文本文档.txt]文件发生了[ENTRY_CREATE]事件
> [E:\temp\新建 文本文档.txt]文件发生了[ENTRY_MODIFY]事件

​		

## 监听事件枚举

> StandardWatchEventKinds.OVERFLOW: 事件丢失或失去(感觉应该不是, 应该是事件溢出)
> StandardWatchEventKinds.ENTRY_CREATE: 目录内实体创建或本目录重命名
> StandardWatchEventKinds.ENTRY_MODIFY: 目录内实体修改
> StandardWatchEventKinds.ENTRY_DELETE: 目录内实体删除或重命名



## 其他

1. 如果多个目录注册了同一个watchService, watchService是拿不到父级目录的. 需要注册多个watchService

2. `Paths.get("E:\\temp");`只能针对`E:\\temp`下的文件或文件夹. 对于子文件夹的修改都属于modify

   > 例如: 
   >
   > E:\\temp新建文件夹E:\\temp\temp1. 
   >
   > E:\\temp\temp1 再新建文件或者文件夹都是属于对E:\\temp\temp1的修改

3. 调用`watchService.take()`后必须调用`watchKey.reset()`. 作用是标识watchKey上一批的事件已经处理完成

