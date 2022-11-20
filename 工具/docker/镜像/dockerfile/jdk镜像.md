# 自定义jdk镜像

```shell
# 基础镜像 使用这个是因为centos太大了 这个打完jre才200+m
FROM frolvlad/alpine-glibc
LABEL MAINTAINER xx <xxx@qq.com>

# 将JRE添加至镜像中，add 命令在源文件为压缩文件时，会自动解压的
ADD jre-8u221-linux-x64.tar.gz /opt/docker/java/jre8

# 设置JAVA环境变量
# 这里需要注意下，解压后有个目录的，为jre1.8.0_181,一开始没注意，启动时报了：exec: "java": executable file not found in $PATH: unknown 后才发现。
ENV JAVA_HOME /opt/docker/java/jre8/jre1.8.0_221
ENV CLASSPATH=$JAVA_HOME/bin
ENV PATH=.:$JAVA_HOME/bin:$PATH

# 这里无实际意义，只是在容器启动时，输出jre版本信息，验证是否安装成功
CMD ["java","-version"]

```

