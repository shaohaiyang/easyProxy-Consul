# 模块语法测试：
# consul-template -consul-addr 192.168.13.169:8500 -template /root/test.ctmpl:/tmp/consul.result -dry -once
# 建议使用 supervisord 来托管服务！

#!/bin/sh
CONSUL="192.168.145.250:8500"
HTTP_DIR="/opt/archer"
TEMPLATE_HTTP="/opt/nginx.http.ctmpl:$HTTP_DIR/conf/conf.d/http.conf:sed -r -i '/^ *$/d;/^$/d' $HTTP_DIR/conf/conf.d/http.conf && $HTTP_DIR/sbin/nginx -s reload"
TEMPLATE_MARATHON="/opt/marathon.kv.ctmpl:$HTTP_DIR/conf/conf.d/marathon.conf:sed -r -i '/^ *$/d;/^$/d' $HTTP_DIR/conf/conf.d/marathon.conf && $HTTP_DIR/sbin/nginx -s reload"
TEMPLATE_STREAM="/opt/nginx.stream.ctmpl:$HTTP_DIR/conf/conf.stream.d/stream.conf:sed -r -i '/^ *$/d;/^$/d' $HTTP_DIR/conf/conf.stream.d/stream.conf && $HTTP_DIR/sbin/nginx -s reload"

###docker run -p 88:80 -d --name nginx --volume /tmp/service.ctmpl:/templates/service.ctmpl --link consul:consul jlordiales/nginx-consul

if [ -z "`pidof $HTTP_DIR/sbin/nginx`" ];then
	$HTTP_DIR/sbin/nginx -c $HTTP_DIR/conf/nginx.conf
fi

if [ -z "`pidof /opt/bin/consul-template`" ];then
	/opt/bin/consul-template \
        -consul-addr $CONSUL \
        -template "$TEMPLATE_HTTP" \
        -template "$TEMPLATE_MARATHON" \
        -template "$TEMPLATE_STREAM"
fi
