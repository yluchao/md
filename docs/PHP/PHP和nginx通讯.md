一、Nginx与PHP交互过程的7步走(用户对动态PHP网页访问过程)

step1：用户将http请求发送给nginx服务器(用户和nginx服务器进行三次握手进行TCP连接)
step2：nginx会根据用户访问的URI和后缀对请求进行判断
step3：通过第二步可以看出，用户请求的是动态内容，nginx会将请求交给fastcgi客户端，通过fastcgi_pass将用户的请求发送给php-fpm
如果用户访问的是静态资源呢，那就简单了，nginx直接将用户请求的静态资源返回给用户。
step4：wrapper收到php-fpm转过来的请求后，wrapper会生成一个新的线程调用php动态程序解析服务器
step5：php会将查询到的结果返回给nginx
step6：nginx构造一个响应报文将结果返回给用户
这只是nginx的其中一种，用户请求的和返回用户请求结果是异步进行，即为用户请求的资源在nginx中做了一次中转，nginx可以同步，即为解析出来的资源，服务器直接将资源返回给用户，不用在nginx中做一次中转。第四步：fastcgi_pass将动态资源交给php-fpm后，php-fpm会将资源转给php脚本解析服务器的wrapper

![img](https://img.yluchao.cn/typora/a050f6ef89e14171d621e78947b58237.png)

即：Nginx -> FastCGI -> php-fpm -> FastCGI Wrapper -> php解析器

![img](https://img.yluchao.cn/typora/c987c3b9855bf9bb99333fccb8996b8e.png)

CGI是通用网关协议，FastCGI则是一种常驻进程的CGI模式程序。我们所熟知的PHP-FPM的全称是PHP FastCGI Process Manager，即PHP-FPM会通过用户配置来管理一批FastCGI进程，例如在PHP-FPM管理下的某个FastCGI进程挂了，PHP-FPM会根据用户配置来看是否要重启补全，PHP-FPM更像是管理器，而真正衔接Nginx与PHP的则是FastCGI进程。

图中，FastCGI的下游CGI-APP就是PHP程序。而FastCGI的上游是Nginx，他们之间有一个通信载体，即图中的socket。在我们上文图3的配置文件中，fastcgi_pass所配置的内容，便是告诉Nginx你接收到用户请求以后，你该往哪里转发，在我们图3中是转发到本机的一个socket文件，这里fastcgi_pass也常配置为一个http接口地址（这个可以在php-fpm.conf中配置）。而上图5中的Pre-fork，则对应着我们PHP-FPM的启动，也就是在我们启动PHP-FPM时便会根据用户配置启动诸多FastCGI触发器（FastCGI Wrapper）

PHP提供SAPI面向Webserver来提供扩展编程。但是这样的方式意味着你要是自主研发一套Webserver，你就需要学习SAPI，并且在你的Webserver程序中实现它。这意味着你的Webserver与PHP产生了耦合。解决耦合的办法:CGI协议，比较好的方式是有一套通用的规范，上下游都兼容它。那么CGI协议便成了Nginx、PHP都愿意接受的一种方式，而FastCGI常住进程的模式又让上下游程序有了高并发的可能。

二、Nginx与PHP的两种通信方式-unix socket和tcp socket

1、两者Nginx配置

unix socket

需要在nginx配置文件中填写php-fpm运行的pid文件地址。

```
location ~ \.php$ {



    include fastcgi_params;



    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;;



    fastcgi_pass unix:/var/run/php5-fpm.sock;



    fastcgi_index index.php;



}
```

tcp socket

需要在nginx配置文件中填写php-fpm运行的ip地址和端口号。

```
location ~ \.php$ {



    include fastcgi_params;



    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;;



    fastcgi_pass 127.0.0.1:9000;



    fastcgi_index index.php;



}
```

2、两者比较

![img](https://img-blog.csdn.net/20181012210023229?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3d1aHVhZ3Vfd3VodWFndW8=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

从上面的图片可以看，**unix socket**减少了不必要的tcp开销，而tcp需要经过loopback，还要申请临时端口和tcp相关资源。但是，unix socket高并发时候不稳定，连接数爆发时，会产生大量的长时缓存，在没有面向连接协议的支撑下，大数据包可能会直接出错不返回异常。tcp这样的面向连接的协议，多少可以保证通信的正确性和完整性。

3、选择建议：如果是在同一台服务器上运行的nginx和php-fpm，并发量不超过1000，选择unix socket，因为是本地，可以避免一些检查操作(路由等)，因此更快，更轻。 如果面临高并发业务，我会选择使用更可靠的tcp socket，以负载均衡、内核优化等运维手段维持效率。