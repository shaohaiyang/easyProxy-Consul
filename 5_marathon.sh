# Mesos HA Cluster 可以在多台机器上启动marathon
# KV存储以Zookeeper集群为基础
# 注意：--event_subscriber http_callback 启用http的回调

#!/bin/sh
ZK_IP="192.168.13.229:2181,192.168.13.230:2181,192.168.13.250:2181"
HOST_IP="192.168.13.250"
docker run -d -p 8080:8080 --restart=always --name marathon mesosphere/marathon \
  --zk zk://${ZK_IP}/marathon \
  --master zk://${ZK_IP}/mesos \
  --event_subscriber http_callback \
  --hostname ${HOST_IP} --http_port 8080
