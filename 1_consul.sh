# 以docker容器为载体，构建Consul三节点集群
# 选举: 8300，LAN: 8301, WAN: 8302
# HTTP: 8500, HTTPS: -1, DNS: 8600, RPC: 8400

# 先独立启动各节点的consul，然后分别使用consul join/members 加入/查看成员
# http://192.168.13.168:8500/ui/

#!/bin/sh
#node1 192.168.13.167
#node2 192.168.13.168
#node3 192.168.13.169

IPADDR="192.168.13.167"
docker run -d --name consul -h node1 \
    -p $IPADDR:8300:8300 \
    -p $IPADDR:8301:8301 \
    -p $IPADDR:8301:8301/udp \
    -p $IPADDR:8302:8302 \
    -p $IPADDR:8302:8302/udp \
    -p $IPADDR:8400:8400 \
    -p $IPADDR:8500:8500 \
    -p $IPADDR:8600:53/udp \
    progrium/consul -server -advertise $IPADDR  -bootstrap-expect 3
