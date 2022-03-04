正式回答这个面试题时，我们先来看一个简单点的题目：如何实现向MySQL中插入数据时，存在则忽略，不存在就插入？其实，这个简单点的题目与标题的题目有相同的地方：都是MySQL中不存在待插入的数据时，就将待插入的数据插入到MySQL中。不同点是：标题中的题目是存在待插入的数据时执行更新操作，而这个简单点的题目是存在待插入的数据时直接忽略，不执行任何操作。

我们先来回答这个简单点的题目。其实，在面试过程中，我们需要揣测面试官的心理，很显然，这里，面试官是想问如何通过SQL语句来实现，并且这样的题目往往都会有一个前置条件：那就是数据表中必须存在唯一键，也就是唯一索引。如果你回答的是你写了一段Java代码或者C语言代码来实现，那你就基本被pass了。这没得说，因为你回答的方向与面试预期的方向不同！

关于这个简单点的题目，我们可以使用insert ignore语句实现。语法格式如下所示。

```sql
insert ignore into table(col1,col2) values ('value1','value2');
```

比如，我们执行如下SQL语句向MySQL中插入数据。

```sql
insert ignore into user_info (last_name,first_name) values ('binghe','binghe');
```

这样一来，如果表中已经存在last_name='binghe'且first_name='binghe'的数据，就不会插入，如果没有就会插入一条新数据。

上面的是一种用法，也可以用 INSERT .... SELECT 语句来实现，这里就不举例了。

## 分析标题题目

接下来，我们再来看标题中的题目，向MySQL中插入数据，存在就更新，不存在则插入。本质上数据表中还是需要存在唯一键，也就是唯一索引的。往往在面试中，面试官都会默许存在这些前置条件。

这里，有两种方法可以实现这个效果。一种方法是结合INSERT语句和ON DUPLICATE KEY UPDATE语句实现，另一种方法是通过REPLACE语句实现。

**INSERT语句和ON DUPLICATE KEY UPDATE语句实现**

如果指定了ON DUPLICATE KEY UPDATE，并且插入行后会导致在一个UNIQUE索引或PRIMARY KEY中出现重复值，则执行UPDATE。例如，如果列a被定义为UNIQUE，并且包含值1，则以下两个语句具有相同的效果：

```sql
INSERT INTO table (a,b,c) VALUES (1,2,3)  ON DUPLICATE KEY UPDATE c=c+1; 
UPDATE table SET c=c+1 WHERE a=1; 
```

如果行作为新记录被插入，则受影响行的值为1；如果原有的记录被更新，则受影响行的值为2。

**REPLACE语句实现**

使用REPLACE的最大好处就是可以将DELETE和INSERT合二为一，形成一个原子操作。这样就可以不必考虑在同时使用DELETE和INSERT时添加事务等复杂操作了。在使用REPLACE时，表中必须有唯一索引，而且这个索引所在的字段不能允许空值，否则REPLACE就和INSERT完全一样的。在执行REPLACE后，系统返回了所影响的行数，如果返回1，说明在表中并没有重复的记录，如果返回2，说明有一条重复记录，系统自动先调用了DELETE删除这条记录，然后再记录用INSERT来插入这条记录。

语法和INSERT非常的相似，如下面的REPLACE语句是插入或更新一条记录。

```sql
REPLACE INTO users (id,name,age) VALUES(1, 'binghe', 18); 
```