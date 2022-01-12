### 查找重复记录

1、查找全部重复记录

```sql
select * from 表 where 重复字段 in (select 重复字段 from 表 group by 重复字段 having count(*)>1)
```

2、过滤重复记录(只显示一条)

```sql
select * from HZT Where ID In (select max(ID) from HZT group by Title)
```

**注：此处显示ID最大一条记录。**

### 删除重复记录

1、删除全部重复记录（慎用）

```sql
delete 表 where 重复字段 in (select 重复字段 from 表 group by 重复字段 having count(*)>1)
```

2、保留一条（这个应该是大多数人所需要的 ^_^）

```sql
delete HZT where ID not In (select max(ID) from HZT group by Title)
```

**注：此处保留ID最大一条记录。**

### 三、举例

1、查找表中多余的重复记录，重复记录是根据单个字段（peopleId）来判断

```sql
select * from people where peopleId in (select peopleId from people group by peopleId having count(peopleId) > 1)
```

2、删除表中多余的重复记录，重复记录是根据单个字段（peopleId）来判断，只留有rowid最小的记录

```sql
delete from people where peopleId in (select peopleId from people group by peopleId having count(peopleId) > 1) and rowid not in (select min(rowid) from people group by peopleId having count(peopleId )>1)
```

3、查找表中多余的重复记录（多个字段）

```sql
select * from vitae a where (a.peopleId,a.seq) in (select peopleId,seq from vitae group by peopleId,seq having count(*) > 1)
```

4、删除表中多余的重复记录（多个字段），只留有rowid最小的记录

```sql
delete from vitae a where (a.peopleId,a.seq) in (select peopleId,seq from vitae group by peopleId,seq having count(*) > 1) and rowid not in (select min(rowid) from vitae group by peopleId,seq having count(*)>1)
```

5、查找表中多余的重复记录（多个字段），不包含rowid最小的记录

```sql
select * from vitae a where (a.peopleId,a.seq) in (select peopleId,seq from vitae group by peopleId,seq having count(*) > 1) and rowid not in (select min(rowid) from vitae group by peopleId,seq having count(*)>1)
```

### 四、补充

有两个以上的重复记录，一是完全重复的记录，也即所有字段均重复的记录，二是部分关键字段重复的记录，比如Name字段重复，而其他字段不一定重复或都重复可以忽略。

1、对于第一种重复，比较容易解决，使用

```sql
select distinct * from tableName
```

就可以得到无重复记录的结果集。

如果该表需要删除重复的记录（重复记录保留1条），可以按以下方法删除

```sql
select distinct * into #Tmp from tableName
drop table tableName
select * into tableName from #Tmp
drop table #Tmp
```

发生这种重复的原因是表设计不周产生的，增加唯一索引列即可解决。

2、这类重复问题通常要求保留重复记录中的第一条记录，操作方法如下 。

假设有重复的字段为Name,Address，要求得到这两个字段唯一的结果集

```sql
select identity(int,1,1) as autoID, * into #Tmp from tableName
select min(autoID) as autoID into #Tmp2 from #Tmp group by Name,autoID
select * from #Tmp where autoID in(select autoID from #tmp2)
```