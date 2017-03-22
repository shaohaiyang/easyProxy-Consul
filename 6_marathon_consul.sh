# 下面是 marathon_consul.json的格式
# 可以直接通过 Marathon http/v2 API 导入
# 并且在界面上实现弹性扩容

# curl -H "Content-type:application/json" -X POST http://192.168.13.250:8080/v2/apps -d @/root/marathon_consul.json

{
  "id": "/marathon-consul",
  "cmd": null,
  "cpus": 0.1,
  "mem": 32,
  "disk": 0,
  "instances": 3,
  "args": [
    "--registry=http://192.168.13.250:8500",
    "--marathon-location=192.168.13.250:8080"
  ],
  "container": {
    "type": "DOCKER",
    "volumes": [],
    "docker": {
      "image": "ciscocloud/marathon-consul",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 4000,
          "hostPort": 31400,
          "servicePort": 10000,
          "protocol": "tcp",
          "labels": {}
        }
      ],
      "privileged": false,
      "parameters": [],
      "forcePullImage": false
    }
  },
  "portDefinitions": [
    {
      "port": 10000,
      "protocol": "tcp",
      "labels": {}
    }
  ]
}
