# 这是mesos master的部署，建议使用Zookeeper集群，设置MESOS_QUORUM=2

#!/bin/sh
ZK_IP="192.168.13.229:2181,192.168.13.230:2181,192.168.13.250:2181"
HOST_IP="192.168.13.250"
mkdir -p /disk/ssd1/mesos/log/mesos /disk/ssd1/mesos/tmp/mesos

docker run -d --net=host --restart=always --name mesos-master \
  -e MESOS_PORT=5050 \
  -e MESOS_ZK=zk://${ZK_IP}/mesos \
  -e MESOS_QUORUM=2 \
  -e MESOS_IP=${HOST_IP} \
  -e MESOS_REGISTRY=in_memory \
  -e MESOS_HOSTNAME_LOOKUP=false \
  -e MESOS_LOG_DIR=/var/log/mesos \
  -e MESOS_WORK_DIR=/var/tmp/mesos \
  -v "/disk/ssd1/mesos/log/mesos:/var/log/mesos" \
  -v "/disk/ssd1/mesos/tmp/mesos:/var/tmp/mesos" \
mesosphere/mesos-master:0.28.2-2.0.27.ubuntu1404
