## 主从复制原理

(1) Master 将数据改变记录到二进制日志(binary log)中，也就是配置文件 log-bin 指定的文件， 这些记录叫做二进制日志事件(binary log events)；

(2) Slave 通过 I/O 线程读取 Master 中的 binary log events 并写入到它的中继日志(relay log)；

(3) Slave 重做中继日志中的事件，把中继日志中的事件信息一条一条的在本地执行一次，完 成数据在本地的存储，从而实现将改变反映到它自己的数据(数据重放)。

![图片](http://img.yluchao.cn/typora/509fb1c06bf9b9e5cd3959abcc209ad9.png)

## 注意事项

(1)主从服务器操作系统版本和位数一致；

(2) Master 和 Slave 数据库的版本要一致；

(3) Master 和 Slave 数据库中的数据要一致；

(4) Master 开启二进制日志，Master 和 Slave 的 server_id 在局域网内必须唯一；

## 配置主从复制步骤

### Master数据库

(1) 安装数据库；

(2) 修改数据库配置文件，指明 server_id，开启二进制日志(log-bin)；

(3) 启动数据库，查看当前是哪个日志，position 号是多少；

(4) 登录数据库，授权数据复制用户（IP 地址为从机 IP 地址，如果是双向主从，这里的 还需要授权本机的 IP 地址，此时自己的 IP 地址就是从 IP 地址)；

(5) 备份数据库（记得加锁和解锁）；

(6) 传送备份数据到 Slave 上；

(7) 启动数据库；

以上步骤，为单向主从搭建成功，想搭建双向主从需要的步骤：

(1) 登录数据库，指定 Master 的地址、用户、密码等信息（此步仅双向主从时需要）；

(2) 开启同步，查看状态；

### Slave 上的配置

(1) 安装数据库；

(2) 修改数据库配置文件，指明 server_id（如果是搭建双向主从的话，也要开启二进制 日志 log-bin）；

(3) 启动数据库，还原备份；

(4) 查看当前是哪个日志，position 号是多少（单向主从此步不需要，双向主从需要）；

(5) 指定 Master 的地址、用户、密码等信息；

(6) 开启同步，查看状态。

## 单向主从环境搭建

### 安装数据库

参考《[MySQL之——源码编译MySQL8.x+升级gcc+升级cmake（亲测完整版）](https://mp.weixin.qq.com/s?__biz=Mzg3MzE1NTIzNA==&mid=2247483696&idx=1&sn=11b3a10e4a000a809b2e6ffa684968a3&chksm=cee51efdf99297eb496eef7789d8cf09633839d39d8240e0d7ca0a9920226894c68610bd7e35&token=899210164&lang=zh_CN&scene=21#wechat_redirect)》。

### 配置Master的my.cnf

```sh
[root@liuyazhuang131 ~]# vi /etc/my.cnf  
# 在 [mysqld] 中增加以下配置项 
# 设置 server_id，一般设置为 IP 
server_id=131
# 复制过滤：需要备份的数据库，输出 binlog
#binlog-do-db=liuyazhuang
# 复制过滤：不需要备份的数据库，不输出（mysql 库一般不同步） 
binlog-ignore-db=mysql 
# 开启二进制日志功能，可以随便取，最好有含义 
log-bin=lyz-mysql-bin 
## 为每个 session 分配的内存，在事务过程中用来存储二进制日志的缓存 
binlog_cache_size=1M 
## 主从复制的格式（mixed,statement,row，默认格式是 statement）
binlog_format=mixed
# 二进制日志自动删除/过期的天数。默认值为 0，表示不自动删除。 
expire_logs_days=7
# 跳过主从复制中遇到的所有错误或指定类型的错误，避免 slave 端复制中断。
# 如：1062 错误是指一些主键重复，1032 错误是因为主从数据库数据不一致
slave_skip_errors=1062
```

**复制过滤可以让你只复制服务器中的一部分数据，有两种复制过滤：**

(1) 在 Master 上过滤二进制日志中的事件；

(2) 在 Slave 上过滤中继日志中的事件。如下：

![图片](http://img.yluchao.cn/typora/b84d9f827bf55e9d030bce88892cc7d2.webp)

**MySQL 对于二进制日志 (binlog)的复制类型**

(1) 基于语句的复制：在 Master 上执行的 SQL 语句，在 Slave 上执行同样的语句。MySQL 默 认采用基于语句的复制，效率比较高。一旦发现没法精确复制时，会自动选着基于行的复制。

(2) 基于行的复制：把改变的内容复制到 Slave，而不是把命令在 Slave 上执行一遍。从MySQL5.0 开始支持。

(3) 混合类型的复制：默认采用基于语句的复制，一旦发现基于语句的无法精确的复制时，就会采用基于行的复制。

### 重启Master库

启动/重启 Master 数据库服务，登录数据库，创建数据同步用户，并授予相应的权限

```sh
[root@liuyazhuang131 ~]# service mysql restart 
[root@liuyazhuang131 ~]# mysql -uroot -proot
##创建数据同步用户，并授予相应的权限 
mysql> grant replication slave, replication client on *.* to 'repl'@'192.168.209.132' identified by '123456'; 
Query OK, 0 rows affected (0.00 sec) ## 刷新授权表信息 
mysql> flush privileges; 
Query OK, 0 rows affected (0.00 sec) 
## 查看 position 号，记下 position 号（从机上需要用到这个 position 号和现在的日志文件) 
mysql> show master status;
+----------------------+----------+--------------+------------------+-------------------+
| File                 | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+----------------------+----------+--------------+------------------+-------------------+
| lyz-mysql-bin.000001 |     1312 |              | mysql            |                   |
+----------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec) 
```

### 模拟业务数据库

创建 lyz 库、表，并写入一定量的数据，用于模拟现有的业务系统数据库

```sh
create database if not exists lyz default charset utf8 collate utf8_general_ci;
use lyz; 
DROP TABLE IF EXISTS `lyz_user`; CREATE TABLE `lyz_user` ( 
`Id` int(11) NOT NULL AUTO_INCREMENT, 
`userName` varchar(255) NOT NULL DEFAULT '' COMMENT '用户名', `pwd` varchar(255) NOT NULL DEFAULT '' COMMENT '密码',
 PRIMARY KEY (`Id`) 
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='用户信息表'; 
INSERT INTO `lyz_user` VALUES (1,'yixiaoqun','123456');
```

### 实现初始数据一致

为保证 Master 和 Slave 的数据一致，我们采用主备份，从还原来实现初始数据一致

```sh
## 先临时锁表
mysql> flush tables with read lock; Query OK, 0 rows affected (0.00 sec) 
## 这里我们实行全库备份，在实际中，我们可能只同步某一个库，那也可以只备份一个库
[root@liuyazhuang131 mysql]# mysqldump -u root -proot lyz > /tmp/lyz.sql 
[root@liuyazhuang131 mysql]# cd /tmp
[root@liuyazhuang131 tmp]# ll | grep lyz.sql
-rw-r--r--  1 root  root     2031 Apr 25 01:18 lyz.sql
# 注意：实际生产环境中大数据量（超 2G 数据）的备份，建议不要使用 mysqldump 进行 比分，因为会非常慢。此时推荐使用 XtraBackup 进行备份。
# 解锁表
mysql> unlock tables; 
Query OK, 0 rows affected (0.00 sec)
```

将 Master 上备份的数据远程传送到 Slave 上，以用于 Slave 配置时恢复数据

```sh
[root@liuyazhuang131 tmp]# scp /tmp/lyz.sql root@192.168.209.132:/tmp/lyz.sql
The authenticity of host '192.168.209.132 (192.168.209.132)' can't be established.
RSA key fingerprint is da:70:7b:d5:0c:16:b3:1a:53:b7:3d:9f:20:01:26:3e.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.209.132' (RSA) to the list of known hosts.
root@192.168.209.132's password: 
lyz.sql          
```

### 配置Slave库

接下来处理 Slave（192.168.209.132），配置文件只需修改一项，其余配置用命令来操作

```sh
[root@liuyazhuang132 ]# vi /etc/my.cnf
# 在 [mysqld] 中增加以下配置项 
# 设置 server_id，一般设置为 IP 
server_id=132
# 复制过滤：需要备份的数据库，输出 binlog #binlog-do-db=lyz
# 复制过滤：不需要备份的数据库，不输出（mysql 库一般不同步）
 binlog-ignore-db=mysql 
# 开启二进制日志，以备 Slave 作为其它 Slave 的 Master 时使用 
log-bin=lyz-mysql-slave1-bin 
## 为每个 session 分配的内存，在事务过程中用来存储二进制日志的缓存 binlog_cache_size = 1M 
# 主从复制的格式（mixed,statement,row，默认格式是 statement） 
binlog_format=mixed 
# 二进制日志自动删除/过期的天数。默认值为 0，表示不自动删除。 
expire_logs_days=7 
# 跳过主从复制中遇到的所有错误或指定类型的错误，避免 slave 端复制中断。 
# 如：1062 错误是指一些主键重复，1032 错误是因为主从数据库数据不一致 
slave_skip_errors=1062 
## relay_log 配置中继日志 
relay_log=lyz-mysql-relay-bin 
## log_slave_updates 表示 slave 将复制事件写进自己的二进制日志 
log_slave_updates=1
##防止改变数据(除了特殊的线程)
read_only=1
```

如果Slave为其它的Slave的Master时，必须设置bin_log,在这里，我开启了二进制日志，而且显式的命名(默认名称为hostname),但是如果hostname改变则会出现问题。

relay_log配置中继日志，log_slave_updates表示slave将复制事件 写进自己的二进制日志.当设置log_slave_updates时，你可以让slave扮演其它slave的master.此时，slave把sql线程执行的事件写进自己的二进制日志(binary log)然后，它的slave可以获取这些事件并执行它。如下图所示(发送复制事件到其它的Slave):

![图片](http://img.yluchao.cn/typora/b84d9f827bf55e9d030bce88892cc7d2.webp)

### 还原备份数据

保存后重启MySQL服务，还原备份数据

```sh
[root@liuyazhuang132 ~]# service mysql restart
Shutting down MySQL. SUCCESS! 
Starting MySQL.. SUCCESS! 
```

Slave上创建相同库

```sh
[root@liuyazhuang132 ~]# mysql -uroot -proot
 mysql> use lyz;
 Database changed
```

### 导入数据

```sh
[root@liuyazhuang132 ~]# mysql -uroot -proot lyz < /tmp/lyz.sql 
[root@liuyazhuang132 ~]# mysql -uroot -proot
mysql> use lyz;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A
Database changed
mysql> select * from lyz_user;
+----+-----------+--------+
| Id | userName  | pwd    |
+----+-----------+--------+
|  1 | yixiaoqun | 123456 |
+----+-----------+--------+
1 row in set (0.00 sec)
```

### Slave库添加参数

登录Slave数据库,添加相关参数：Master的IP、端口、同步用户、密码、position号、读取哪个日志文件

```sh
change master to master_host='192.168.209.131',master_user='repl',master_password='123456',master_port=3306,
master_log_file='lyz-mysql-bin.000001',master_log_pos=1312,master_connect_retry=30;
```

上面执行的命令的解释:

- master_host='192.168.209.131' ##Master的IP地址
- master_user='repl'      ##用于同步数据的用户(在Master中授权的用户)
- master_password='123456'  ##同步数据用户的密码
- master_port=3306      ##master数据库服务的端口
- master_log_file='lyz-mysql-bin.000001' ##指定Slave从哪个日志文件开始读取复制文件(可在Master上使用show master status查看到日志文件名)
- master_log_pos=429     ##从哪个POSITION号开始读
- master_connect_retry=30   #当重新建立主从连接时，如果连接建立失败，间隔多久后重试,单位为秒，默认设置为60秒，同步延迟调优参数。

查看主从同步状态

```sh
show slave status\G;
```

可看到Slave_IO_State为空，Slave_IO_Runngin和Slave_SQL_Running是No,表时Slave还是没有开始复制过程。

开启主从同步

```sh
mysql> start slave;
```

再次查看同步状态

```sh
#show slave status\G;
```

主要看以下两个参数,这两个参数如果是Yes，就表示数据同步正常

```sh
Slave_IO_Running:Yes
Slave_SQL_Running:Yes
```

可查看master和slave上线程的状态,在master上，可以看到slave的I/O线程创建的连接

```sh
Master:mysql>show processlist\G;
```

1.row为处理slave的I/O线程的连接。

2.row为处理MySQL客户连接线程。

3.row为处理本地命令行的线程

```sh
Slave:mysql>show processlist\G;
```

1.row为处理slave的I/O线程的连接。

2.row为处理MySQL客户连接线程。

3.row为处理本地命令行的线程

### 主从数据复制同步测试

```sh
Master:
mysql> insert into lyz_user values(2,'test1','123456');
Slave:
mysql> start slave;
```

经过以上配置，在192.168.209.131上对数据库/表进行增删改查，创建/删除数据库/表都会同步到192.168.209.132数据库上了。