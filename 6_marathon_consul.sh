# 下面是 marathon_consul.json的格式
# 可以直接通过 Marathon http/v2 API 导入
# 并且在界面上实现弹性扩容

# curl -H "Content-type:application/json" -X POST http://192.168.13.250:8080/v2/apps -d @/root/marathon_consul.json

{
  "id": "marathon-consul",
  "args": ["--registry=https://192.168.13.250:8500"],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "{{ marathon_consul_image }}:{{ marathon_consul_image_tag }}",
      "network": "BRIDGE",
      "portMappings": [{"containerPort": 4000, "hostPort": 4000, "protocol": "tcp"}]
    }
  },
  "constraints": [["hostname", "UNIQUE"]],
  "ports": [4000],
  "healthChecks": [{
    "protocol": "HTTP",
    "path": "/health",
    "portIndex": 0
  }],
  "instances": 1,
  "cpus": 0.1,
  "mem": 32
}
