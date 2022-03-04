## 事件背景

- MySQL数据库每日零点自动全备
- 某天上午9点，二狗子不小心drop了一个数据库
- 我们需要通过全备的数据文件，以及增量的binlog文件进行数据恢复

## 主要思想与原理

- 利用全备的sql文件中记录的CHANGE MASTER语句，binlog文件及其位置点信息，找出binlog文件增量的部分
- 用mysqlbinlog命令将上述的binlog文件导出为sql文件，并剔除其中的drop语句
- 通过全备文件和增量binlog文件的导出sql文件，就可以恢复到完整的数据

## 过程示意图

![图片](http://img.yluchao.cn/typora/ea90db2812416f7271aae0716e8dc6c9.webp)

## 操作过程

### 模拟数据

```
CREATE TABLE `student` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` char(20) NOT NULL,
  `age` tinyint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 
 
mysql> insert student values(1,'zhangsan',20); 
mysql> insert student values(2,'lisi',21); 
mysql> insert student values(3,'wangwu',22);
```

### 全备命令

```
# mysqldump -uroot -p -B -F -R -x --master-data=2 test|gzip >/server/backup/test_$(date +%F).sql.gz
```

参数说明：

- -B 指定数据库
- -F 刷新日志
- -R 备份存储过程等
- -x 锁表
- --master-data 在备份语句里添加CHANGE MASTER语句以及binlog文件及位置点信息

### 继续插入数据并删库

```
mysql> insert student values(4,'xiaoming',20);
mysql> insert student values(5,'xiaohong',20); 
```

在插入数据的时候我们模拟误操作，删除test数据库。

```
mysql> drop database test;
```

此时，全备之后到误操作时刻之间，用户写入的数据在binlog中，需要恢复出来。

### 查看全备之后新增的binlog文件

```
# cd /server/backup/
# ls
test_2020-08-19.sql.gz
# gzip -d test_2020-08-19.sql.gz 
# grep CHANGE test_2020-08-19.sql 
-- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000003', MASTER_LOG_POS=107;
```

这是全备时刻的binlog文件位置，即mysql-bin.000003的107行，因此在该文件之前的binlog文件中的数据都已经包含在这个全备的sql文件中了

### 移动binlog文件，并读取sql，剔除其中的drop语句

```
# cp /data/3306/mysql-bin.000003 /server/backup/
# mysqlbinlog -d test mysql-bin.000003 >mysql-bin.000003.sql
```

接下来，使用vim编辑mysql-bin.000003.sql文件，剔除drop语句

**注意：在恢复全备数据之前必须将该binlog文件移出，否则恢复过程中，会继续写入语句到binlog，最终导致增量恢复数据部分变得比较混乱**

### 恢复数据

```
# mysql -uroot -p < test_2020-08-19.sql 
# mysql -uroot -p -e "select * from test.student;"
+----+----------+-----+
| id | name     | age |
+----+----------+-----+
|  1 | zhangsan |  20 |
|  2 | lisi     |  21 |
|  3 | wangwu   |  22 |
+----+----------+-----+
```

此时恢复了全备时刻的数据，然后使用mysql-bin.000003.sql文件恢复全备时刻到删除数据库之间，新增的数据。

```
# mysql -uroot -p test < mysql-bin.000003.sql 
# mysql -uroot -p -e "select * from test.student;"
+----+----------+-----+
| id | name     | age |
+----+----------+-----+
|  1 | zhangsan |  20 |
|  2 | lisi     |  20 |
|  3 | wangwu   |  20 |
|  4 | xiaoming |  20 | 
|  5 | xiaohong |  20 |
+----+----------+-----+
```

此时，整个恢复过程结束，是不是很简单呢？没错，就是这么简单！！

## 总结

- 适合人为SQL语句造成的误操作或者没有主从复制等的热备情况宕机时的修复。
- 恢复条件要全备和增量的所有数据。
- 恢复时建议对外停止更新，即禁止更新数据库。
- 先恢复全量，然后把全备时刻点以后的增量日志，按顺序恢复成SQL文件，然后把文件中有问题的SQL语句删除（也可通过时间和位置点），再恢复到数据库。