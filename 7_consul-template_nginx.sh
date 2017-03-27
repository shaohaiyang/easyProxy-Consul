# 模板化配置Consul-template
# Consul-template API 功能语法
# datacenters：在consul目录中查询所有的datacenters，{{datacenters}}
# file：读取并输出本地磁盘上的文件，如果无法读取，则报错，{{file "/path/to/local/file"}}
# key：查询consul中该key的值，如果无法转换成一个类字符串的值，则会报错，{{key "service/redis/maxconns@east-aws"}} east-aws指定的是数据中心，{{key "service/redis/maxconns"}}
# key_or_default：查询consul中该key的值，如果key不存在，则使用指定的值代替，{{key_or_default "service/redis/maxconns@east-aws" "5"}}
# ls：在consul中查询给定前缀的key的顶级域值，{{range ls "service/redis@east-aws"}} {{.Key}} {{.Value}}{{end}}
# node：查询consul目录中的单个node，如果不指定node，则是当前agent的，{{node "node1"}}
# nodes：查询consul目录中的所有nodes，你也可以指定datacenter，{{nodes "@east-aws"}}
# service：查询consul中匹配的service组，{{service "release.web@east-aws"}}或者{{service "web"}}，也可以返回一组HealthService服务{{range service "web@datacenter"}}  server {{.Name}} {{.Address}}:{{.Port}}{{end}}，默认值返回健康的服务，如果你想返回所有服务，则{{service "web" "any"}}
# services：查询consul目录中的所有services，{{services}}，也可以指定datacenter：{{services "@east-aws"}}
# tree：查询consul中给定前缀的所有K/V值，{{range tree "service/redis@east-aws"}} {{.Key}} {{.Value}}{{end}}

# 使用Nginx作为反向代理主要是考虑到它支持 TCP/UDP/HTTP 多种协议
# nginx.conf Nginx的主要配置文件
# nginx.http.ctmpl Nginx 基于HTTP、ServerName的反向代理模板
# nginx.stream.ctmpl Nginx基于TCP/UDP的反向代理模板
# marathon.kv.ctmpl Nginx基于Marathon KV生成的反向代理模板

# nginx.conf
```
user  nobody;
worker_processes  auto;
#error_log  logs/error.log  info;
events {
    worker_connections  10240;
}
 
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    #tcp_nopush     on;
    lingering_close off;
    keepalive_timeout  30;
    send_timeout 60;
    proxy_read_timeout 100;
    proxy_send_timeout 60;
    proxy_connect_timeout 10;
    proxy_next_upstream_timeout 50;
    proxy_buffer_size 8k;
    proxy_buffers 4 8k;
    proxy_busy_buffers_size 16k;
    proxy_max_temp_file_size 0;
    proxy_temp_path /dev/shm/proxy_temp_nginx 1 2;
    client_body_temp_path /dev/shm/client_body_temp_nginx 1 2;
    client_header_buffer_size 4k;
    large_client_header_buffers 8 16k;
    client_max_body_size 1024m;
    port_in_redirect off;
    open_log_file_cache max=2048 inactive=60s min_uses=2 valid=15m;
    #gzip  on;
 
server {
    listen       81 default_server;
    server_name  _;
    location / {
        root   html;
        index  index.html index.htm;
    }
 
    location /stats {
            stub_status on;
            allow 192.168.0.0/16;
            deny all;
            auth_basic "upyun proxy status";
            access_log off;
            auth_basic_user_file .htpasswd;
    }
}
##################################################################
include  conf.d/*.conf;
}
##################################################################
stream {
include  conf.stream.d/*.conf;
}
```

# nginx.http.ctmpl
```
{{ range services }}
        {{ range service .Name }}
                {{ if in .Tags "upyun" }}
                        {{if .Tags | contains "http"}}
upstream {{.Name}} {
  least_conn;
  {{ .Address | plugin "/usr/local/bin/concatip.sh" }}
}

server {
        listen {{.Port}};
        server_name {{.ID}};
        error_log       /opt/nginx/logs/{{.ID}}.error.log;
        charset utf-8;
        location / {
                proxy_pass      http://{{.Name}};
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
}
                        {{end}}
                {{end}}
        {{end}}
{{end}}
```

# nginx.stream.ctmpl
```
{{ range services }}
        {{ range service .Name }}
                {{ if in .Tags "upyun" }}
{{ if in .Tags "tcp" }}
upstream {{.Name}} {
  least_conn;
  {{ .Address | plugin "/usr/local/bin/concatip.sh" }}
}

server {
        listen {{.Port}};
        proxy_pass      {{.Name}};
        proxy_timeout   3s;
        proxy_connect_timeout   1s;
}
{{end}}

{{ if in .Tags "udp" }}
upstream {{.Name}} {
  least_conn;
  {{ .Address | plugin "/usr/local/bin/concatip.sh" }}
}

server {
        listen {{.Port}} udp;
        proxy_pass      {{.Name}};
        proxy_timeout   3s;
        proxy_connect_timeout   1s;
}
{{end}}
                {{end}}
        {{end}}
{{end}}
```

# /usr/local/bin/concatip.sh
```
#!/bin/sh
for ip in `echo $1|sed -r 's^[;@#]^ ^g'`;do
        echo "server $ip max_fails=3 fail_timeout=60 weight=1;"
done
exit 0
```

# 通过curl注册服务脚本
# 删除服务: curl -v -X PUT http://192.168.13.250:8500/v1/agent/service/deregister/{{.ID}} (repo.upyun.com)
```
curl -X PUT \
192.168.13.250:8500/v1/agent/service/register \
-d '{
 "ID": "repo.upyun.com",
 "Name":"hongbo-dockerepo",
 "Port": 5043,
 "Address": "192.168.13.250:5043",
 "Tags": ["http","upyun"]
}'

curl -X PUT \
192.168.13.250:8500/v1/agent/service/register \
-d '{
 "ID": "oneoo-tcp-acs",
 "Name":"oneoo-tcp-acs",
 "Port": 1234,
 "Address": "192.168.1.42:1234 ",
 "Tags": ["tcp","upyun"]
}'

curl -X PUT \
192.168.13.250:8500/v1/agent/service/register \
-d '{
 "ID": "oneoo-udp-acs",
 "Name":"oneoo-udp-acs",
 "Port": 1234,
 "Address": "192.168.1.42:1234 ",
 "Tags": ["udp","upyun"]
}'
```

# marathon.kv.ctmpl
```
{{range tree "/marathon/"}}
{{if .Value|regexMatch "slave.*TASK_RUNNING"}}
{{.Value | plugin "/usr/local/bin/parse_json.sh" }}
{{end}}
{{end}}
{{ plugin "/usr/local/bin/marathon.sh" }}
```

# /usr/local/bin/parse_json.sh
```
#!/bin/sh
parse_json(){
        echo "${1//\"/}" | sed -r -n "s^.*appId:/(.*),host:(.*),ports:\[(.*)\].*^\1@server \2:\3 max_fails=3 fail_timeout=60 weight=1;^p"
}
parse_json $1 >> /tmp/.marathon_upstream
exit 0
```

# /usr/local/bin/marathon.sh
```
#!/bin/sh
STRING2=

cat /tmp/.marathon_upstream | awk -F@ '{name[$1]=name[$1]"\n"$2} END{for(i in name) printf "upstream %s {\nleast_conn;%s\n}\n\n",i,name[i]}'
for name in `awk -F@ '{print $1}' /tmp/.marathon_upstream|sort -u`;do
        STRING2+="server {\n\tlisten 88;\n\tserver_name $name;\n\terror_log /opt/nginx/logs/$name.error.log;\n\tcharset utf-8;\n\tlocation / {\n\t\tproxy_pass http://$name;\n\t\tproxy_set_header Host \$host;\n\t\tproxy_set_header X-Real-IP \$remote_addr;\n\t\tproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n\t}\n}\n\n"
done

echo -e $STRING2
rm -rf /tmp/.marathon_upstream
exit 0
```
