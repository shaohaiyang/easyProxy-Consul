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
    listen       81;
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
STRING3=

cat /tmp/.marathon_upstream | awk -F@ '{name[$1]=name[$1]"\n"$2} END{for(i in name) printf "upstream %s {%s\n}\n",i,name[i]}'
STRING2="server {\n\tlisten 88 default_server;\n\tserver_name _;\n\tlocation / {\n\t\troot html;\n\t\tindex index.html index.htm;\n\t}\n"
for name in `awk -F@ '{print $1}' /tmp/.marathon_upstream|sort -u`;do
        STRING3+="\tlocation /$name/ {\n\t\tproxy_pass http://$name/;\n\t}\n"
done
STRING3+="\n}"

echo -e $STRING2
echo -e $STRING3
rm -rf /tmp/.marathon_upstream
exit 0
```
