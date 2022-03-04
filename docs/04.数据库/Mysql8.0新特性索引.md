MySQL 8.x中新增了三种索引方式，如下所示。

- 隐藏索引
- 降序索引
- 函数索引



## 一、隐藏索引

1.隐藏索引概述

- MySQL 8.0开始支持隐藏索引（invisible index），不可见索引。
- 隐藏索引不会被优化器使用，但仍然需要进行维护。
- 应用场景：软删除、灰度发布。

在之前MySQL的版本中，只能通过显式的方式删除索引，如果删除后发现索引删错了，又只能通过创建索引的方式将删除的索引添加回来，如果数据库中的数据量非常大，或者表比较大，这种操作的成本非常高。在MySQL 8.0中，只需要将这个索引先设置为隐藏索引，使查询优化器不再使用这个索引，但是，此时这个索引还是需要MySQL后台进行维护，当确认将这个索引设置为隐藏索引系统不会受到影响时，再将索引彻底删除。这就是软删除功能。

灰度发布，就是说创建索引时，首先将索引设置为隐藏索引，通过修改查询优化器的开关，使隐藏索引对查询优化器可见，通过explain对索引进行测试，确认这个索引有效，某些查询可以使用到这个索引，就可以将其设置为可见索引，完成灰度发布的效果。

2.隐藏索引操作



（1）登录MySQL，创建testdb数据库，并在数据库中创建一张测试表t1

```sql
mysql> create database if not exists testdb;
Query OK, 1 row affected (0.58 sec)
mysql> use testdb;
Database changed
mysql> create table if not exists t1(i int, j int);
Query OK, 0 rows affected (0.05 sec)
```

（2）在字段i上创建索引，如下所示。

```sql
mysql> create index i_idx on t1(i);
Query OK, 0 rows affected (0.34 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

（3）在字段j上创建隐藏索引，创建隐藏索引时，只需要在创建索引的语句后面加上invisible关键字，如下所示

```sql
mysql> create index j_idx on t1(j) invisible;
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

（4）查看t1表中的索引情况，如下所示

```sql
mysql> show index from t1 \G
*************************** 1. row ***************************
        Table: t1
   Non_unique: 1
     Key_name: i_idx
 Seq_in_index: 1
  Column_name: i
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: NULL
*************************** 2. row ***************************
        Table: t1
   Non_unique: 1
     Key_name: j_idx
 Seq_in_index: 1
  Column_name: j
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: NO
   Expression: NULL
2 rows in set (0.02 sec)
```

可以看到t1表中有两个索引，一个是i_idx，一个是j_idx，i_idx的Visible属性为YES，表示这个索引可见；j_idx的Visibles属性为NO,表示这个索引不可见。
（5）查看查询优化器对这两个索引的使用情况。
首先，使用字段i进行查询，如下所示。

```sql

mysql> explain select * from t1 where i = 1 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
   partitions: NULL
         type: ref
possible_keys: i_idx
          key: i_idx
      key_len: 5
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.02 sec)
可以看到，查询优化器会使用i字段的索引进行优化。
接下来，使用字段j进行查询，如下所示。
mysql> explain select * from t1 where j = 1 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

可以看到，查询优化器并没有使用j字段上的隐藏索引，会使用全表扫描的方式查询数据。
（6）使隐藏索引对优化器可见
在MySQL 8.x 中提供了一种新的测试方式，可以通过优化器的一个开关来打开某个设置，使隐藏索引对查询优化器可见。
查看查询优化器的开关，如下所示。

```sql
mysql> select @@optimizer_switch \G 
*************************** 1. row ***************************
@@optimizer_switch: index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_fanout_filter=on,derived_merge=on,use_invisible_indexes=off,skip_scan=on,hash_join=on
1 row in set (0.00 sec)
```

这里，可以看到如下一个属性值：

```sql
use_invisible_indexes=off
```

表示优化器是否使用不可见索引，默认为off不使用。
接下来，在MySQL的会话级别使查询优化器使用不可见索引，如下所示。

```sql
mysql> set session optimizer_switch="use_invisible_indexes=on";
Query OK, 0 rows affected (0.00 sec)
```

接下来，再次查看查询优化器的开关设置，如下所示

```sql
mysql> select @@optimizer_switch \G
*************************** 1. row ***************************
@@optimizer_switch: index_merge=on,index_merge_union=on,index_merge_sort_union=on,index_merge_intersection=on,engine_condition_pushdown=on,index_condition_pushdown=on,mrr=on,mrr_cost_based=on,block_nested_loop=on,batched_key_access=off,materialization=on,semijoin=on,loosescan=on,firstmatch=on,duplicateweedout=on,subquery_materialization_cost_based=on,use_index_extensions=on,condition_fanout_filter=on,derived_merge=on,use_invisible_indexes=on,skip_scan=on,hash_join=on
1 row in set (0.00 sec)
```

此时，可以看到use_invisible_indexes=on，说明隐藏索引对查询优化器可见了。

再次分析使用t1表的j字段查询数据，如下所示。

```sql
mysql> explain select * from t1 where j = 1 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
   partitions: NULL
         type: ref
possible_keys: j_idx
          key: j_idx
      key_len: 5
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

可以看到，此时查询优化器使用j字段上的隐藏索引来优化查询了。

（7）设置索引的可见与不可见
将字段j上的隐藏索引设置为可见，如下所示。

```sql
mysql> alter table t1 alter index j_idx visible;
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

将字段j上的索引设置为不可见，如下所示。

```sql
mysql> alter table t1 alter index j_idx invisible;
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

（8）MySQL中主键不能设置为不可见索引
值得注意的是：在MySQL中，主键是不可以设置为不可见的。
在testdb数据库中创建一张测试表t2，如下所示

```sql
mysql> create table t2(i int not null);
Query OK, 0 rows affected (0.01 sec)
```

接下来，在t2表中创建一个不可见主键，如下所示

```sql
mysql> alter table t2 add primary key pk_t2(i) invisible; 
ERROR 3522 (HY000): A primary key index cannot be invisible
```

可以看到，此时SQL语句报错，主键不能被设置为不可见索引。

## 二、降序索引

1. 降序索引概述

- MySQL 8.0开始真正支持降序索引（descending index）。
- 只有InnoDB存储引擎支持降序索引，只支持BTREE降序索引。
- MySQL 8.0不再对GROUP BY操作进行隐式排序

2. 降序索引操作

（1）MySQL 5.7中支持的语法

​	首先，在MySQL 5.7中创建测试数据库testdb，在数据库testdb中创建测试表t2,如下所示。

```sql
mysql> create database if not exists testdb;
Query OK, 0 rows affected (0.71 sec)
mysql> use testdb;Database changed
mysql> create table if not exists t2(c1 int, c2 int, index idx1(c1 asc, c2 desc));
Query OK, 0 rows affected (0.71 sec)
```

其中，在t2表中创建了名为idx1的索引，索引中c1字段升序排序，c2字段降序排序。

接下来，查看t2表的创建信息，如下所示

```sql
mysql> show create table t2 \G
*************************** 1. row ***************************
       Table: t2
Create Table: CREATE TABLE `t2` (
  `c1` int(11) DEFAULT NULL,
  `c2` int(11) DEFAULT NULL,
  KEY `idx1` (`c1`,`c2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
1 row in set (0.16 sec)
```

可以看到，MySQL 5.7版本在创建表的信息中，没有字段c1和c2的排序信息，默认都是升序。

（2）MySQL 8.0中支持的语法
在MySQL 8.x中同样创建t2表，如下所示

```sql
mysql> create table if not exists t2(c1 int, c2 int, index idx1(c1 asc, c2 desc));
Query OK, 0 rows affected, 1 warning (0.00 sec)
```

接下来，查看t2表的创建信息，如下所示

```sql
mysql> show create table t2 \G
*************************** 1. row ***************************
       Table: t2
Create Table: CREATE TABLE `t2` (
  `c1` int(11) DEFAULT NULL,
  `c2` int(11) DEFAULT NULL,
  KEY `idx1` (`c1`,`c2` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
1 row in set (0.00 sec)
```

可以看到，在MySQL 8.x中，创建的索引中存在字段的排序信息。

（3）MySQL 5.7中查询优化器对索引的使用情况
首先，在表t2中插入一些数据，如下所示。

```sql
mysql> insert into t2(c1, c2) values(1, 100), (2, 200), (3, 150), (4, 50);
Query OK, 4 rows affected (0.19 sec)
Records: 4  Duplicates: 0  Warnings: 0
```

接下来，查询t2表中的数据，如下所示

```sql
mysql> select * from t2;
+------+------+
| c1   | c2   |
+------+------+
|    1 |  100 |
|    2 |  200 |
|    3 |  150 |
|    4 |   50 |
+------+------+
4 rows in set (0.00 sec)
```

可以看到，t2表中的数据插入成功。

接下来，查看查询优化器对索引的使用情况，这里，查询语句按照c1字段升序，按照c2字段降序，如下所示。

```sql
mysql> explain select * from t2 order by c1, c2 desc \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t2
   partitions: NULL
         type: index
possible_keys: NULL
          key: idx1
      key_len: 10
          ref: NULL
         rows: 4
     filtered: 100.00
        Extra: Using index; Using filesort
1 row in set, 1 warning (0.12 sec)
```

可以看到，在MySQL 5.7中，按照c2字段进行降序排序，并没有使用索引。

（4）MySQL 8.x中查询优化器对降序索引的使用情况。
查看查询优化器对降序索引的使用情况。
首先，在表t2中插入一些数据，如下所示。

```sql
mysql> insert into t2(c1, c2) values(1, 100), (2, 200), (3, 150), (4, 50);
Query OK, 4 rows affected (0.00 sec)
Records: 4  Duplicates: 0  Warnings: 0
```

可以看到，t2表中的数据插入成功。

在MySQL中如果创建的是升序索引，则指定查询的时候，只能按照升序索引的方式指定查询，这样才能使用升序索引。

接下来，查看查询优化器对索引的使用情况，这里，查询语句按照c1字段升序，按照c2字段降序，如下所示。

```sql
mysql> explain select * from t2 order by c1, c2 desc \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t2
   partitions: NULL
         type: index
possible_keys: NULL
          key: idx1
      key_len: 10
          ref: NULL
         rows: 4
     filtered: 100.00
        Extra: Using index
1 row in set, 1 warning (0.00 sec)
```

可以看到，在MySQL 8.x中，按照c2字段进行降序排序，使用了索引。

使用c1字段降序，c2字段升序排序，如下所示。

```sql
mysql> explain select * from t2 order by c1 desc, c2 \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t2
   partitions: NULL
         type: index
possible_keys: NULL
          key: idx1
      key_len: 10
          ref: NULL
         rows: 4
     filtered: 100.00
        Extra: Backward index scan; Using index
1 row in set, 1 warning (0.00 sec)
```

可以看到，在MySQL 8.x中仍然可以使用索引，并使用了索引的反向扫描。

（5）MySQL 8.x中不再对GROUP BY进行隐式排序

在MySQL 5.7中执行如下命令，按照c2字段进行分组，查询每组中数据的记录条数。

```sql
mysql> select count(*), c2 from t2 group by c2;
+----------+------+
| count(*) | c2   |
+----------+------+
|        1 |   50 |
|        1 |  100 |
|        1 |  150 |
|        1 |  200 |
+----------+------+
4 rows in set (0.18 sec)
```

可以看到，在MySQL 5.7中，在c2字段上进行了排序操作。

在MySQL 8.x中执行如下命令，按照c2字段进行分组，查询每组中数据的记录条数。

```sql
mysql> select count(*), c2 from t2 group by c2;
+----------+------+
| count(*) | c2   |
+----------+------+
|        1 |  100 |
|        1 |  200 |
|        1 |  150 |
|        1 |   50 |
+----------+------+
4 rows in set (0.00 sec)
```

可以看到，在MySQL 8.x中，在c2字段上并没有进行排序操作。

在MySQL 8.x中如果需要对c2字段进行排序，则需要使用order by语句明确指定排序规则，如下所示。

```sql
mysql> select count(*), c2 from t2 group by c2 order by c2;
+----------+------+
| count(*) | c2   |
+----------+------+
|        1 |   50 |
|        1 |  100 |
|        1 |  150 |
|        1 |  200 |
+----------+------+
4 rows in set (0.00 sec)
```



# 三、函数索引

## 1.函数索引概述

- ## MySQL 8.0.13开始支持在索引中使用函数（表达式）的值。

- 支持降序索引，支持JSON数据的索引

- 函数索引基于虚拟列功能实现

## 2.函数索引操作

（1）创建测试表t3
在testdb数据库中创建一张测试表t3，如下所示。

```sql
mysql> create table if not exists t3(c1 varchar(10), c2 varchar(10));
Query OK, 0 rows affected (0.01 sec)
```

（2）创建普通索引
在c1字段上创建普通索引

```sql
mysql> create index idx1 on t3(c1);
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

（3）创建函数索引
在c2字段上创建一个将字段值转化为大写的函数索引，如下所示。

```sql
mysql> create index func_index on t3 ((UPPER(c2)));
Query OK, 0 rows affected (0.02 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

（4）查看t3表上的索引信息，如下所示。

```sql

mysql> show index from t3 \G
*************************** 1. row ***************************
        Table: t3
   Non_unique: 1
     Key_name: idx1
 Seq_in_index: 1
  Column_name: c1
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: NULL
*************************** 2. row ***************************
        Table: t3
   Non_unique: 1
     Key_name: func_index
 Seq_in_index: 1
  Column_name: NULL
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: upper(`c2`)
2 rows in set (0.01 sec)
```

（5）查看查询优化器对两个索引的使用情况
首先，查看c1字段的大写值是否等于某个特定的值，如下所示。

```sql
mysql> explain select * from t3 where upper(c1) = 'ABC' \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t3
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

可以看到，没有使用索引，进行了全表扫描操作。

接下来，查看c2字段的大写值是否等于某个特定的值，如下所示。

```sql
mysql> explain select * from t3 where upper(c2) = 'ABC' \G 
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t3
   partitions: NULL
         type: ref
possible_keys: func_index
          key: func_index
      key_len: 43
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

可以看到，使用了函数索引。

（6）函数索引对JSON数据的索引
首先，创建测试表emp，并对JSON数据进行索引，如下所示。

```sql
mysql> create table if not exists emp(data json, index((CAST(data->>'$.name' as char(30)))));
Query OK, 0 rows affected (0.02 sec)
```

上述SQL语句的解释如下：

- JSON数据长度不固定，如果直接对JSON数据进行索引，可能会超出索引长度，通常，会只截取JSON数据的一部分进行索引。
- CAST()类型转换函数，把数据转化为char(30)类型。使用方式为CAST(数据 as 数据类型)。
- data ->> '$.name'表示JSON的运算符

简单的理解为，就是取name节点的值，将其转化为char(30)类型。

接下来，查看emp表中的索引情况，如下所示。

```sql
mysql> show index from emp \G
*************************** 1. row ***************************
        Table: emp
   Non_unique: 1
     Key_name: functional_index
 Seq_in_index: 1
  Column_name: NULL
    Collation: A
  Cardinality: 0
     Sub_part: NULL
       Packed: NULL
         Null: YES
   Index_type: BTREE
      Comment: 
Index_comment: 
      Visible: YES
   Expression: cast(json_unquote(json_extract(`data`,_utf8mb4\'$.name\')) as char(30) charset utf8mb4)
1 row in set (0.00 sec)
```

（7）函数索引基于虚拟列实现
首先，查看t3表的信息，如下所示。

```sql
mysql> desc t3;
+-------+-------------+------+-----+---------+-------+
| Field | Type        | Null | Key | Default | Extra |
+-------+-------------+------+-----+---------+-------+
| c1    | varchar(10) | YES  | MUL | NULL    |       |
| c2    | varchar(10) | YES  |     | NULL    |       |
+-------+-------------+------+-----+---------+-------+
2 rows in set (0.00 sec)
```

在c1上建立了普通索引，在c2上建立了函数索引。

接下来，在t3表中添加一列c3，模拟c2上的函数索引，如下所示。

```sql
mysql> alter table t3 add column c3 varchar(10) generated always as (upper(c1));
Query OK, 0 rows affected (0.03 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

c3列是一个计算列，c3字段的值总是使用c1字段转化为大写的结果。

接下来，向t3表中插入一条数据，其中，c3列是一个计算列，c3字段的值总是使用c1字段转化为大写的结果，在插入数据的时候，不需要为c3列插入数据，如下所示。

```sql
mysql> insert into t3(c1, c2) values ('abc', 'def');
Query OK, 1 row affected (0.00 sec)
```

查询t3表中的数据，如下所示。

```sql
mysql> select * from t3;
+------+------+------+
| c1   | c2   | c3   |
+------+------+------+
| abc  | def  | ABC  |
+------+------+------+
1 row in set (0.00 sec)
```

可以看到，并不需要向c3列中插入数据，c3列的数据为c1字段的大写结果数据。

如果想模拟函数索引的效果，则可以使用如下方式。
首先，在c3列上添加索引，如下所示。

```sql
mysql> create index idx3 on t3(c3);
Query OK, 0 rows affected (0.11 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

接下来，再次查看c1字段的大写值是否等于某个特定的值，如下所示。

```sql
mysql> explain select * from t3 where upper(c1) = 'ABC' \G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t3
   partitions: NULL
         type: ref
possible_keys: idx3
          key: idx3
      key_len: 43
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

此时，就使用了idx3索引。