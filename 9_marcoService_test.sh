# 启动和停止任务
# curl -H "Content-type:application/json" -X POST http://192.168.13.250:8080/v2/apps -d @/root/python-simplehttpserver.json
# curl -H "Content-type:application/json" -X DELETE http://192.168.13.250:8080/v2/apps/hello
{
    "id": "hello",
    "cpus": 0.1,
    "mem": 16.0,
    "instances": 3,
    "container": {
        "type": "DOCKER",
        "docker": {
            "image": "trinitronx/python-simplehttpserver",
            "network": "BRIDGE",
            "portMappings": [
                { "containerPort": 8080, "hostPort": 0, "servicePort": 8000, "protocol": "tcp" }
             ]
        },
        "volumes": [
                { "containerPath": "/var/www", "hostPath": "/root/", "mode": "RO" }
             ]
        },
    "healthChecks": [
    {
      "protocol": "HTTP",
      "portIndex": 0,
      "path": "/",
      "gracePeriodSeconds": 5,
      "intervalSeconds": 20,
      "maxConsecutiveFailures": 3
    }]
}
