如何从MySQL一个数据表中查询一条随机的记录，同时要保证效率最高。

从这个题目来看，其实包含了两个要求，第一个要求就是：从MySQL数据表中查询一条随机的记录。第二个要求就是要保证效率最高。

接下来，我们就来尝试使用各种方式来从MySQL数据表中查询数据。

## 方法一

这是最原始最直观的语法，如下：

```sql
SELECT * FROM foo ORDER BY RAND() LIMIT 1
```

当数据表中数据量较小时，此方法可行。但当数据量到达一定程度，比如100万数据或以上，就有很大的性能问题。如果你通过EXPLAIN来分析这个  语句，会发现虽然MySQL通过建立一张临时表来排序，但由于ORDER  BY和LIMIT本身的特性，在排序未完成之前，我们还是无法通过LIMIT来获取需要的记录。亦即，你的记录有多少条，就必须首先对这些数据进行排序。

## 方法二

看来对于大数据量的随机数据抽取，性能的症结出在ORDER BY上，那么如何避免？方法二提供了一个方案。

首先，获取数据表的所有记录数：

```sql
SELECT count(*) AS num_rows FROM foo
```

然后，通过对应的后台程序记录下此记录总数（假定为num_rows）。

然后执行：

```sql
SELECT * FROM foo LIMIT [0到num_rows之间的一个随机数],1
```

上面这个随机数的获得可以通过后台程序来完成。此方法的前提是表的ID是连续的或者自增长的。

这个方法已经成功避免了ORDER BY的产生。

## 方法三

有没有可能不用ORDER BY，用一个SQL语句实现方法二？可以，那就是用JOIN。

```sql
SELECT * FROM Bar B JOIN (SELECT CEIL(MAX(ID)*RAND()) AS ID FROM Bar) AS m ON B.ID >= m.ID LIMIT 1;
```

此方法实现了我们的目的，同时，在数据量大的情况下，也避免了ORDER  BY所造成的所有记录的排序过程，因为通过JOIN里面的SELECT语句实际上只执行了一次，而不是N次（N等于方法二中的num_rows）。而且， 我们可以在筛选语句上加上“大于”符号，还可以避免因为ID好不连续所产生的记录为空的现象。

在MySQL中查询5条不重复的数据，使用以下：

```sql
SELECT * FROM `table` ORDER BY RAND() LIMIT 5
```

就可以了。但是真正测试一下才发现这样效率非常低。一个15万余条的库，查询5条数据，居然要8秒以上

搜索Google，网上基本上都是查询max(id) * rand()来随机获取数据。

```sql
SELECT * 
FROM `table` AS t1 JOIN (SELECT ROUND(RAND() * (SELECT MAX(id) FROM `table`)) AS id) AS t2 
WHERE t1.id >= t2.id 
ORDER BY t1.id ASC LIMIT 5;
```

但是这样会产生连续的5条记录。解决办法只能是每次查询一条，查询5次。即便如此也值得，因为15万条的表，查询只需要0.01秒不到。

上面的语句采用的是JOIN，mysql的论坛上有人使用

```sql
SELECT * 
FROM `table` 
WHERE id >= (SELECT FLOOR( MAX(id) * RAND()) FROM `table` ) 
ORDER BY id LIMIT 1;
```

我测试了一下，需要0.5秒，速度也不错，但是跟上面的语句还是有很大差距。总觉有什么地方不正常。

于是我把语句改写了一下。

```sql
SELECT * FROM `table` 
WHERE id >= (SELECT floor(RAND() * (SELECT MAX(id) FROM `table`))) 
ORDER BY id LIMIT 1;
```

这下，效率又提高了，查询时间只有0.01秒

最后，再把语句完善一下，加上MIN(id)的判断。我在最开始测试的时候，就是因为没有加上MIN(id)的判断，结果有一半的时间总是查询到表中的前面几行。

完整查询语句是：

```sql
SELECT * FROM `table` 
WHERE id >= (SELECT floor( RAND() * ((SELECT MAX(id) FROM  `table`)-(SELECT MIN(id) FROM `table`)) + (SELECT MIN(id) FROM  `table`))) 
ORDER BY id LIMIT 1;

SELECT * 
 FROM  `table` AS t1 JOIN (SELECT ROUND(RAND() * ((SELECT MAX(id) FROM  `table`)-(SELECT MIN(id) FROM `table`))+(SELECT MIN(id) FROM `table`))  AS id) AS t2 
WHERE t1.id >= t2.id 
ORDER BY t1.id LIMIT 1;
```

最后对这两个语句进行分别查询10次，

前者花费时间 0.147433 秒，后者花费时间 0.015130 秒

看来采用JOIN的语法比直接在WHERE中使用函数效率还要高很多。