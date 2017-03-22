# 为了保证docker的质量，建议使用最新的docker版本映射到容器内
# -v /usr/local/sbin/docker:/usr/bin/docker

#!/bin/sh
ZK_IP="192.168.13.229:2181,192.168.13.230:2181,192.168.13.250:2181"
HOST_IP="192.168.13.167"  
mkdir -p /disk/ssd1/mesos_slave/log/mesos /disk/ssd1/mesos_slave/tmp/mesos

docker run -d --net=host --privileged  --restart=always --name mesos-slave \
 -e MESOS_PORT=5051 \
 -e MESOS_MASTER=zk://${ZK_IP}/mesos \
 -e MESOS_SWITCH_USER=0 \
 -e MESOS_CONTAINERIZERS=docker,mesos \
 -e MESOS_EXE_TIMEOUT=5mins \
 -e MESOS_LOG_DIR=/var/log/mesos \
 -e MESOS_WORK_DIR=/var/tmp/mesos \
 -e MESOS_IP=${HOST_IP} \
 -e MESOS_HOSTNAME_LOOKUP=false \
 -e MESOS_LAUNCHER=posix \
 -v "/disk/ssd1/mesos_slave/log/mesos:/var/log/mesos" \
 -v "/disk/ssd1/mesos_slave/tmp/mesos:/var/tmp/mesos" \
 -v /cgroup:/cgroup \
 -v /sys:/sys \
 -v /usr/local/sbin/docker:/usr/bin/docker \
 -v /var/run/docker.sock:/var/run/docker.sock \
mesosphere/mesos-slave:0.28.2-2.0.27.ubuntu1404
