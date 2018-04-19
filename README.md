# easyProxy-Consul
nginx reverse proxy with tcp/udp/http by consul-template

## 微服务以：
#### 不可变基础镜像为本质；
#### 辅以暴露端口，配置加载，卷映射；
#### 配合秒起秒停，自动发现/注册，负载均衡;
#### 利用Mesos/K8s调度平台，角色转换，终成大法；

## 核心技术栈
#### 操作系统：Centos7 / Atomic / Ubuntu Core / CoreOS（可选）
#### 容器基础：Docker探秘
#### 代码管理/持续集成：Gitlab & Git-CI
#### 集群选举：Zookeeper / etcd / Consul
#### 服务发现/服务注册：Consul & Consul-template
#### 调度平台：Mesos / K8s / Openshift
#### 任务框架：Mesos API / Marathon / Chronos
