# FileVisitor

`java.nio.file.FileVisitor` 接口提供了递归遍历文件树的支持. 这个接口上的方法表示了遍历过程中的关键过程

简单来说就是JDK帮你遍历送进来的目录, 你需要针对遍历到文件/目录时的操作

其核心方法是`java.nio.file.FileTreeWalker#walk(java.nio.file.Path, int, java.util.List<java.nio.file.FileTreeWalker.AncestorDirectory>)`



## 参考

[fileVisitor接口详解](https://cucaracha.iteye.com/blog/2044114)

[fileVisitor简单示例](https://blog.csdn.net/qasrc6/article/details/51282185)

使用fileVisitor一般继承SimpleFileVisitor, 是一个空实现类



## 常量

*   **FileVisitResult.CONTINUE**：这个访问结果表示当前的遍历过程将会继续。 

*   **FileVisitResult.SKIP_SIBLINGS**：这个访问结果表示当前的遍历过程将会继续，但是要忽略当前文件/目录的兄弟节点。 

*   **FileVisitResult.SKIP_SUBTREE**：这个访问结果表示当前的遍历过程将会继续，但是要忽略当前目录下的所有节点。 

*   **FileVisitResult.TERMINATE**：这个访问结果表示当前的遍历过程将会停止。 



## FileVisitor接口方法

*   **visitFile()**

    当前对象为文件时需要的操作

    

*   **preVisitDirectory()**

    访问目录内容前调用

    如果返回**CONTINUE**则调用目录中的内容

    如果返回**SKIP_SIBLINGS**或者**SKIP_SUBTREE**都不会访问内容

    

*   **postVisitDirectory()**

    访问子项之后调用(包括迭代提前完成)

    访问异常接受一个IOException 参数, 如果没有异常那么这个值为null

    

*   **visitFileFailed()**

    不能访问文件时调用



## 使用示例

工作上用到的遍历日志文件, 然后截取日志文件的部分名称

代码没有给全~将就看. 使用的是内部类的方法. termNOList是外部类的属性

这里可以优化成使用preVisitDirectory() 

```java
/**
 * 读取日志文件
 */
private void readFiles() {
    UploadRecordFileVisitor visitor = new UploadRecordFileVisitor();
    visitor.dateStr = DateUtils.format(date, DateUtils.DATE_PATTERN_SIMPLE);
    visitor.prefix = visitor.dateStr + "_";

    try {
        Files.walkFileTree(path, visitor);
    } catch (IOException e) {
        log.error("TransactionUploadRecordStatistic 读取文件失败, path:{}, visitor:{}", path, visitor, e);
    }
}

class UploadRecordFileVisitor extends SimpleFileVisitor<Path> {
    /*
    文件夹名称(日期)
     */
    String dateStr;
    /**
     * 文件前缀
     */
    String prefix;

    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
        String fileSourceName = file.getFileName().toString();
        if (fileSourceName.startsWith(prefix)) {
            // 去前缀(YYYYMMDD_)并且按.切割去除后缀(zip), 如果后缀不存在现在也算是一个
            String[] split = fileSourceName.replace(prefix, "").split("\\.");
            termNOList.add(split[0]);
        }
        return FileVisitResult.SKIP_SUBTREE;
    }

    @Override
    public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
        if (dateStr.equals(dir.getFileName().toString()) || TRANSACTION_UPLOAD_PATH.equals(dir.toString())) {
            return FileVisitResult.SKIP_SIBLINGS;
        } else {
            return FileVisitResult.SKIP_SUBTREE;
        }
    }
}
```

