负载均衡可以分为静态负载均衡和动态负载均衡，接下来，我们就一起来分析下Nginx如何实现四层静态负载均衡和四层动态负载均衡。

## 静态负载均衡

Nginx的四层静态负载均衡需要启用ngx_stream_core_module模块，默认情况下，ngx_stream_core_module是没有启用的，需要在安装Nginx时，添加--with-stream配置参数启用，如下所示。

```
./configure --prefix=/usr/local/nginx-1.17.2 --with-openssl=/usr/local/src/openssl-1.0.2s --with-pcre=/usr/local/src/pcre-8.43 --with-zlib=/usr/local/src/zlib-1.2.11 --with-http_realip_module --with-http_stub_status_module --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --with-cc-opt=-O3 --with-stream  --with-http_ssl_module
```

### 配置四层负载均衡

配置HTTP负载均衡时，都是配置在http指令下，配置四层负载均衡，则是在stream指令下，结构如下所示.

```
stream {
 upstream mysql_backend {
  ......
 }
 server {
  ......
 }
}
```

### 配置upstream

```
upstream mysql_backend {
 server 192.168.175.201:3306 max_fails=2 fail_timeout=10s weight=1;
 server 192.168.175.202:3306 max_fails=2 fail_timeout=10s weight=1;
 least_conn;
}
```

### 配置server

```
server {
 #监听端口，默认使用的是tcp协议，如果需要UDP协议，则配置成listen 3307 udp;
 listen 3307;
 #失败重试
 proxy_next_upstream on;
 proxy_next_upstream_timeout 0;
 proxy_next_upstream_tries 0;
 #超时配置
 #配置与上游服务器连接超时时间，默认60s
 proxy_connect_timeout 1s;
 #配置与客户端上游服务器连接的两次成功读/写操作的超时时间，如果超时，将自动断开连接
 #即连接存活时间，通过它可以释放不活跃的连接，默认10分钟
 proxy_timeout 1m;
 #限速配置
 #从客户端读数据的速率，单位为每秒字节数，默认为0，不限速
 proxy_upload_rate 0;
 #从上游服务器读数据的速率，单位为每秒字节数，默认为0，不限速
 proxy_download_rate 0;
 #上游服务器
 proxy_pass mysql_backend;
}
```

配置完之后，就可以连接Nginx的3307端口，访问数据库了。

### Nginx完整配置

完整的Nginx配置如下：

```
user  hadoop hadoop;
worker_processes  auto;
 
error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
 
#pid        logs/nginx.pid;
 
 
events {
 use epoll;
    worker_connections  1024;
}
 
stream {
 upstream mysql_backend {
  server 192.168.175.100:3306 max_fails=2 fail_timeout=10s weight=1;
  least_conn;
 }
 server {
  #监听端口，默认使用的是tcp协议，如果需要UDP协议，则配置成listen 3307 udp;
  listen 3307;
  #失败重试
  proxy_next_upstream on;
  proxy_next_upstream_timeout 0;
  proxy_next_upstream_tries 0;
  #超时配置
  #配置与上游服务器连接超时时间，默认60s
  proxy_connect_timeout 1s;
  #配置与客户端上游服务器连接的两次成功读/写操作的超时时间，如果超时，将自动断开连接
  #即连接存活时间，通过它可以释放不活跃的连接，默认10分钟
  proxy_timeout 1m;
  #限速配置
  #从客户端读数据的速率，单位为每秒字节数，默认为0，不限速
  proxy_upload_rate 0;
  #从上游服务器读数据的速率，单位为每秒字节数，默认为0，不限速
  proxy_download_rate 0;
  #上游服务器
  proxy_pass mysql_backend;
 }
}
```

## 动态负载均衡

配置Nginx四层静态负载均衡后，重启Nginx时，Worker进程一直不退出，会报错，如下所示。

```
nginx: worker process is shutting down;
```

这是因为Worker进程维持的长连接一直在使用，所以无法退出，只能杀掉进程。可以使用Nginx的四层动态负载均衡解决这个问题。

使用Nginx的四层动态负载均衡有两种方案：使用商业版的Nginx和使用开源的nginx-stream-upsync-module模块。注意：四层动态负载均衡可以使用nginx-stream-upsync-module模块，七层动态负载均衡可以使用nginx-upsync-module模块。

使用如下命令为Nginx添加nginx-stream-upsync-module模块和nginx-upsync-module模块，此时，Nginx会同时支持四层动态负载均衡和HTTP七层动态负载均衡。

```
git clone https://github.com/xiaokai-wang/nginx-stream-upsync-module.git
git clone https://github.com/weibocom/nginx-upsync-module.git
git clone https://github.com/CallMeFoxie/nginx-upsync.git
cp -r nginx-stream-upsync-module/* nginx-upsync/nginx-stream-upsync-module/
cp -r nginx-upsync-module/* nginx-upsync/nginx-upsync-module/
 
./configure --prefix=/usr/local/nginx-1.17.2 --with-openssl=/usr/local/src/openssl-1.0.2s --with-pcre=/usr/local/src/pcre-8.43 --with-zlib=/usr/local/src/zlib-1.2.11 --with-http_realip_module --with-http_stub_status_module --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --with-cc-opt=-O3 --with-stream --add-module=/usr/local/src/nginx-upsync --with-http_ssl_module
```

### 配置四层负载均衡

配置HTTP负载均衡时，都是配置在http指令下，配置四层负载均衡，则是在stream指令下，结构如下所示，

```
stream {
 upstream mysql_backend {
  ......
 }
 server {
  ......
 }
}
```

### 配置upstream

```
upstream mysql_backend {
 server 127.0.0.1:1111; #占位server
 upsync 192.168.175.100:8500/v1/kv/upstreams/mysql_backend upsync_timeout=6m upsync_interval=500ms upsync_type=consul strong_dependency=off;
 upsync_dump_path /usr/local/nginx-1.17.2/conf/mysql_backend.conf;
}
```

- upsync指令指定从consul哪个路径拉取上游服务器配置；
- upsync_timeout配置从consul拉取上游服务器配置的超时时间；
- upsync_interval配置从consul拉取上游服务器配置的间隔时间；
- upsync_type指定使用consul配置服务器；
- strong_dependency配置nginx在启动时是否强制依赖配置服务器，如果配置为on，则拉取配置失败时Nginx启动同样失败。
- upsync_dump_path指定从consul拉取的上游服务器后持久化到的位置，这样即使consul服务器出现问题，本地还有一个备份。

### 配置server

```
server {
 #监听端口，默认使用的是tcp协议，如果需要UDP协议，则配置成listen 3307 udp;
 listen 3307;
 #失败重试
 proxy_next_upstream on;
 proxy_next_upstream_timeout 0;
 proxy_next_upstream_tries 0;
 #超时配置
 #配置与上游服务器连接超时时间，默认60s
 proxy_connect_timeout 1s;
 #配置与客户端上游服务器连接的两次成功读/写操作的超时时间，如果超时，将自动断开连接
 #即连接存活时间，通过它可以释放不活跃的连接，默认10分钟
 proxy_timeout 1m;
 #限速配置
 #从客户端读数据的速率，单位为每秒字节数，默认为0，不限速
 proxy_upload_rate 0;
 #从上游服务器读数据的速率，单位为每秒字节数，默认为0，不限速
 proxy_download_rate 0;
 #上游服务器
 proxy_pass mysql_backend;
}
```

### 从Consul添加上游服务器

```
curl -X PUT -d "{\"weight\":1, \"max_fails\":2, \"fail_timeout\":10}" http://192.168.175.100:8500/v1/kv/upstreams/mysql_backend/192.168.175.201:3306
curl -X PUT -d "{\"weight\":1, \"max_fails\":2, \"fail_timeout\":10}" http://192.168.175.100:8500/v1/kv/upstreams/mysql_backend/192.168.175.202:3306
```

### 从Consul删除上游服务器

```
curl -X DELETE http://192.168.175.100:8500/v1/kv/upstreams/mysql_backend/192.168.175.202:3306
```

### 配置upstream_show

```
server {
 listen 13307;
 upstream_show;
}
```

配置upstream_show指令后，可以通过curl http://192.168.175.100:13307/upstream_show查看当前动态负载均衡上游服务器列表。

### Nginx完整配置

Nginx的完整配置如下：

```
user  hadoop hadoop;
worker_processes  auto;
 
error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
 
#pid        logs/nginx.pid;
 
 
events {
 use epoll;
    worker_connections  1024;
}
 
stream {
 upstream mysql_backend {
  server 127.0.0.1:1111; #占位server
  upsync 192.168.175.100:8500/v1/kv/upstreams/mysql_backend upsync_timeout=6m upsync_interval=500ms upsync_type=consul strong_dependency=off;
  upsync_dump_path /usr/local/nginx-1.17.2/conf/mysql_backend.conf;
 }
 server {
  #监听端口，默认使用的是tcp协议，如果需要UDP协议，则配置成listen 3307 udp;
  listen 3307;
  #失败重试
  proxy_next_upstream on;
  proxy_next_upstream_timeout 0;
  proxy_next_upstream_tries 0;
  #超时配置
  #配置与上游服务器连接超时时间，默认60s
  proxy_connect_timeout 1s;
  #配置与客户端上游服务器连接的两次成功读/写操作的超时时间，如果超时，将自动断开连接
  #即连接存活时间，通过它可以释放不活跃的连接，默认10分钟
  proxy_timeout 1m;
  #限速配置
  #从客户端读数据的速率，单位为每秒字节数，默认为0，不限速
  proxy_upload_rate 0;
  #从上游服务器读数据的速率，单位为每秒字节数，默认为0，不限速
  proxy_download_rate 0;
  #上游服务器
  proxy_pass mysql_backend;
 }
 server {
  listen 13307;
  upstream_show;
 }
}
```