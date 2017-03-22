# 模块语法测试：
# consul-template -consul-addr 192.168.13.169:8500 -template /root/test.ctmpl:/tmp/consul.result -dry -once
# 建议使用 supervisord 来托管服务！

#!/bin/sh
CONSUL="192.168.13.250:8500"
TEMPLATE_HTTP="/opt/nginx.http.ctmpl:/opt/nginx/conf/conf.d/http.conf"
TEMPLATE_MARATHON="/opt/marathon.kv.ctmpl:/opt/nginx/conf/conf.d/marathon.conf"
TEMPLATE_STREAM="/opt/nginx.stream.ctmpl:/opt/nginx/conf/conf.stream.d/stream.conf:/opt/nginx/sbin/nginx -s reload"
 
###docker run -p 88:80 -d --name nginx --volume /tmp/service.ctmpl:/templates/service.ctmpl --link consul:consul jlordiales/nginx-consul
 
if [ -z "`pidof /opt/nginx/sbin/nginx`" ];then
        /opt/nginx/sbin/nginx -c /opt/nginx/conf/nginx.conf
fi
 
if [ -z "`pidof /usr/local/bin/consul-template`" ];then
        /usr/local/bin/consul-template \
        -consul-addr $CONSUL \
        -template "$TEMPLATE_HTTP" \
        -template "$TEMPLATE_MARATHON" \
        -template "$TEMPLATE_STREAM"
fi
