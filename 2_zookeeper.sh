# 值得重点注意的一点是，所有三个机器都应该打开端口 2181、2888 和 3888。
# 端口 2181 由 ZooKeeper 客户端使用，用于连接到 ZooKeeper 服务器；
# 端口 2888 由对等 ZooKeeper 服务器使用，用于互相通信；
# 端口 3888 用于领导者选举。
# 您可以选择自己喜欢的任何端口。通常建议在所有 ZooKeeper 服务器上使用相同的端口。

#!/bin/sh
IP1="192.168.13.250"
IP2="192.168.13.229"
IP3="192.168.13.230"
 
docker run -d --name=zk1 -p 2181:2181 -p 2888:2888 -p 3888:3888 \
  -e ZOOKEEPER_ID=1 \
  -e ZOOKEEPER_SERVER_1=$IP1 \
  -e ZOOKEEPER_SERVER_2=$IP2 \
  -e ZOOKEEPER_SERVER_3=$IP3 \
digitalwonderland/zookeeper
