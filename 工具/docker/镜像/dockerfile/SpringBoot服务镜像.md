# 自定义SpringBoot服务镜像

```shell
FROM alpine-jre:jre8
LABEL MAINTAINER="cashway-gd-chen <chengb@cashwaytech.com>"

# 项目名称
ARG PROJECT_NAME_ARG
# 暴露端口
ARG PORT
# 选用的配置文件
ARG PROFILES=sit
ENV PROJECT_NAME=${PROJECT_NAME_ARG} \
  JAVA_OPTS=-server \
  JAVA_PARAM=--spring.profiles.active=${PROFILES}

# 创建日志文件和外部文件的存放路径
RUN mkdir -p /home/project/${PROJECT_NAME}/logs \
  && mkdir -p /home/project/${PROJECT_NAME}/file \
  && echo ${PROJECT_NAME} \
  && echo ${JAVA_PARAM}
# 复制jar包到工作目录
COPY ${PROJECT_NAME}.jar /home/project/${PROJECT_NAME}/
# 复制默认配置文件
# COPY application.* /home/project/${PROJECT_NAME}/

# 暴露日志文件和外部文件的存放路径
VOLUME /home/project/${PROJECT_NAME}/logs
VOLUME /home/project/${PROJECT_NAME}/file
# 开放端口
EXPOSE ${PORT}
# 选定工作目录
WORKDIR /home/project/${PROJECT_NAME}

# 运行
ENTRYPOINT ["/bin/sh","-c","java ${JAVA_OPTS} -jar ${PROJECT_NAME}.jar ${JAVA_PARAM}"]
```



```shell
docker build \
 --build-arg PROJECT_NAME_ARG=cashwaycloud-eureka\
 --build-arg PROFILES=sit \
 --build-arg PORT=8081 \
 -f /home/project/docker-project/dockerfile/cashway/dockerfile \
 -t cashwaycloud-eureka:v191030 \
 /home/project/cashwaycloud-eureka 
 
# docker build 以eureka为例
docker build \
# 指定arg 参数, 改变arg参数来改变打包的服务和其他配置
--build-arg PROJECT_NAME_ARG=cashwaycloud-eureka\
--build-arg PROFILES=sit \
--build-arg PORT=8081 \
# 指定dockerfile 文件路径
-f /home/project/docker-project/dockerfile/cashway/dockerfile \
# 指定镜像名称和tag
-t cashwaycloud-eureka:v191030 \
# 指定上下文(jar包路径和配置文件路径)
/home/project/cashwaycloud-eureka 
```



```shell
docker run --name erueka \
 -v cashway_log:/home/project/cashwaycloud-eureka/logs \
 -v cashway_file:/home/project/cashwaycloud-eureka/file \
  --network=host \
 -p 8091:8081  --restart on-failure:3 cashwaycloud-eureka:v191030
 
# docker run 以eureka为例
docker run --name erueka \
 # 指定卷
 -v cashway_log:/home/project/cashwaycloud-eureka/logs \
 -v cashway_file:/home/project/cashwaycloud-eureka/file \
 # 和宿主机公用网络
 --network=host \
 # 这个可以去掉
 -p 8091:8081  \ 
 # 故障重试3次
 --restart on-failure:3 cashwaycloud-eureka:v191030
```

