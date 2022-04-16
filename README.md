# Big data playground: Livy

[![Docker Build](https://img.shields.io/docker/cloud/build/panovvv/livy.svg)](https://cloud.docker.com/repository/docker/panovvv/livy/builds)
[![Docker Pulls](https://img.shields.io/docker/pulls/panovvv/livy.svg)](https://hub.docker.com/r/panovvv/livy)
[![Docker Stars](https://img.shields.io/docker/stars/panovvv/livy.svg)](https://hub.docker.com/r/panovvv/livy)

Livy Docker image built on top of Hadoop+Hive+Spark

## Software

* [Livy 0.8.0-incubating](https://livy.apache.org/docs/0.7.0-incubating/rest-api.html)

## Usage

Take a look [at this repo](https://github.com/panovvv/bigdata-docker-compose)
to see how I use it as a part of a Docker Compose cluster.

## Maintaining

* Docker file code linting:  `docker run --rm -i hadolint/hadolint < Dockerfile`
* [To trim the fat from Docker image](https://github.com/wagoodman/dive)



## update version to 8.0 and support Spark3 with scala 2.12

学习并使用了[斜杠代码日记](https://www.modb.pro/u/310149)的文章

一个Apache Spark的REST服务。REST服务我们已经不陌生了，例如：HDFS和YARN都提供了REST接口，通过该接口可以方便地和其他的外部系统交互对接。而且HDFS的httpdfs具备了HA功能。居然是REST接口，就表示，在客户端无需Hadoop环境就可以轻松使用HDFS和YARN集群的功能。

Apache Livy是用于快速、简单地和Spark交互的REST服务。它可以很方便地通过REST接口或者RPC客户端，提交Spark作业或者是代码片段，以同步或者异步的方式获取执行结果，就像使用Spark Context一样。

![img](README.assets/modb_20210908_6d543288-105d-11ec-b6f0-00163e068ecd.png)image-20210203123502123

还有其他的一些额外功能，例如：

- 长时间运行的Spark上下文可以被多个客户端、多个Spark作业使用。
- 在多个客户端、作业之间共享缓存的RDD或者DataFrame。
- 可以管理多个Spark上下文，而且Spark上下文在集群（YARN）中运行，而不是Livy server上运行，可以实现很好的容错性和并发性。
- 作业可以通过预编译的jar包提交，或者通过Java/Scala客户端API来提交。
- 确保安全性认证

编译Livy

为了支持Spark 3.x版本，需要基于当前（2021-3-26）的master版本编译，其实它对应的是livy 0.8的snapshot版本。

### 环境准备

注意==以下都需要在linux环境下进行==，在win环境执行会有回车符号和unix不一致情况，造成报错：

准备好：

（1）maven 环境

需要可以执行`mvn -v` 

（2）maven仓库

最好是有完备jar包的

```shell
# 去除仓库内的冗余文件
find /仓库路径 -name _maven.repositories  -type f -print -exec rm -rf {} \;
find /仓库路径 -name _remote.repositories  -type f -print -exec rm -rf {} \;
find /仓库路径 -name *.lastUpdated  -type f -print -exec rm -rf {} \;
```

（4）安装python3环境

可以直接下载anaconda包进行安装

（3）clone项目

```shell
git clone https://github.com/apache/incubator-livy.git
# 项目文件在incubator-livy下
```

### 编译

```shell
# 在incubator-livy下执行
# Spark 2.4.7、scala 2.11版本
mvn package -Pspark-2.4 -Dhadoop.version=3.2.1 -Dhive.version=3.1.2  -Dspark.scala-2.11.version=2.4.7 -DskipTests  -DskipRTests=true -DskipPySpark3Tests=true

# Spark 3.0.0、scala 2.12、hadoop 3.2.3、hive 3.1.2版本
mvn package --quiet -Pspark-3.0 -Pthriftserver -Dhadoop.version=3.2.3 -Dhive.version=3.1.2 -Dspark.scala-2.12.version=3.0.0 -Dspark.bin.download.url=https://archive.apache.org/dist/spark/spark-3.0.0/spark-3.0.0-bin-hadoop3.2.tgz -DskipTests -DskipRTests=true  -DskipPySpark3Tests=true
```

如果出现disclaimer相关的异常，可以手动找`apache-incubator-disclaimer-resource-bundle-1.2-SNAPSHOT.jar` 手动添加至maven

执行

```shell
mvn install:install-file -DgroupId=org.apache.apache.resources -DartifactId=apache-incubator-disclaimer-resource-bundle -Dversion=1.2-SNAPSHOT -Dpackaging=jar -Dfile=/root/Maven_Repository/org/apache/apache/resources/apache-incubator-disclaimer-resource-bundle/1.2-SNAPSHOT/apache-incubator-disclaimer-resource-bundle-1.2-SNAPSHOT.jar
```

### 重命名

```shell
cd /root/incubator-livy/assembly/target/
# 解压缩、重命名并压缩
unzip apache-livy-0.8.0-incubating-SNAPSHOT-bin.zip 
mv apache-livy-0.8.0-incubating-SNAPSHOT-bin apache-livy-0.8.0-incubating-bin
zip livy-0.8.0-spark3.1.1-hadoop-3.2.1
```

最终得到`livy-0.8.0-spark3.1.1-hadoop-3.2.1.zip`文件