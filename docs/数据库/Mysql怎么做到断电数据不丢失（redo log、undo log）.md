# InnoDB事务日志（redo log 和 undo log）

数据库通常借助日志来实现事务，常见的有undo log、redo log，undo/redo log都能保证事务特性，undolog实现事务原子性，redolog实现事务的持久性。

为了最大程度避免数据写入时io瓶颈带来的性能问题，MySQL采用了这样一种缓存机制：当query修改数据库内数据时，InnoDB先将该数据从磁盘读取到内存中，修改内存中的数据拷贝，并将该修改行为持久化到磁盘上的事务日志（先写redo log buffer，再定期批量写入），而不是每次都直接将修改过的数据记录到硬盘内，等事务日志持久化完成之后，内存中的脏数据可以慢慢刷回磁盘，称之为Write-Ahead Logging。事务日志采用的是追加写入，顺序io会带来更好的性能优势。

为了避免脏数据刷回磁盘过程中，掉电或系统故障带来的数据丢失问题，InnoDB采用事务日志（redo log）来解决该问题。

### 一、先简单了解几个概念

数据库数据存放的文件称为data file；

日志文件称为log file；

数据库数据是有缓存的，如果没有缓存，每次都写或者读物理disk，那性能就太低下了。数据库数据的缓存称为data buffer，日志（redo）缓存称为log buffer。

**内存缓冲池**

buffer pool如果mysql不用内存缓冲池，每次读写数据时，都需要访问磁盘，必定会大大增加I/O请求，导致效率低下。所以Innodb引擎在读写数据时，把相应的数据和索引载入到内存中的缓冲池(buffer pool)中，一定程度的提高了数据读写的速度。

buffer pool：占最大块内存，用来存放各种数据的缓存包括有索引页、数据页、undo页、插入缓冲、自适应哈希索引、innodb存储的锁信息、数据字典信息等。工作方式总是将数据库文件按页(每页16k)读取到缓冲池，然后按最近最少使用(lru)的算法来保留在缓冲池中的缓存数据。如果数据库文件需要修改，总是首先修改在缓存池中的页(发生修改后即为脏页dirty page)，然后再按照一定的频率将缓冲池的脏页刷新到文件。

**表空间**

 表空间可看做是InnoDB存储引擎逻辑结构的最高层。 表空间文件：InnoDB默认的表空间文件为ibdata1。 

- 段：表空间由各个段组成，常见的段有数据段、索引段、回滚段（undo log段）等。
- 区：由64个连续的页组成，每个页大小为16kb，即每个区大小为1MB。
- 页：每页16kb，且不能更改。常见的页类型有：数据页、Undo页、系统页、事务数据页、插入缓冲位图页、插入缓冲空闲列表页、未压缩的二进制大对象页、压缩的二进制大对象页。

 **redo log 和undo log**

　　为了满足事务的持久性，防止buffer pool数据丢失，innodb引入了redo log。为了满足事务的原子性，innodb引入了undo log。

### 二、undo log

Undo log 是为了实现事务的原子性。还用Undo Log来实现多版本并发控制(简称：MVCC)。

**delete/update操作的内部机制**

 当事务提交的时候，innodb不会立即删除undo log，因为后续还可能会用到undo log，如隔离级别为repeatable read时，事务读取的都是开启事务时的最新提交行版本，只要该事务不结束，该行版本就不能删除，即undo log不能删除。

 但是在事务提交的时候，会将该事务对应的undo log放入到删除列表中，未来通过purge来删除。并且提交事务时，还会判断undo log分配的页是否可以重用，如果可以重用，则会分配给后面来的事务，避免为每个独立的事务分配独立的undo log页而浪费存储空间和性能。

 通过undo log记录delete和update操作的结果发现：(insert操作无需分析，就是插入行而已) 

- delete操作实际上不会直接删除，而是将delete对象打上delete flag，标记为删除，最终的删除操作是purge线程完成的。
- update分为两种情况：update的列是否是主键列。
- 如果不是主键列，在undo log中直接反向记录是如何update的。即update是直接进行的。
- 如果是主键列，update分两部执行：先删除该行，再插入一行目标行。

①事务的原子性 

　　事务的所有操作，要么全部完成，要不都不做，不能只做一半。如果在执行的过程中发生了错误，要回到事务开始时的状态，所有的操作都要回滚。

②原理 
　　Undo Log的原理很简单，为了满足事务的原子性，在操作任何数据之前，首先将数据备份到一个地方（这个存储数据备份的地方称为Undo Log）。然后进行数据的修改。如果出现了错误或者用户执行了ROLLBACK语句，系统可以利用Undo Log中的备份将数据恢复到事务开始之前的状态。

假设有A、B两个数据，值分别为1,2。 进行+2的事务操作。 
A.事务开始. 
B.记录A=1到undo log. 
C.修改A=3. 
D.记录B=2到undo log. 
E.修改B=4. 
F.将undo log写到磁盘。 
G.将数据写到磁盘。 
H.事务提交 
这里有一个隐含的前提条件：‘数据都是先读到内存中，然后修改内存中的数据，最后将数据写回磁盘’。

之所以能同时保证原子性和持久化，是因为以下特点： 
A. 更新数据前记录Undo log。 
B. 为了保证持久性，必须将数据在事务提交前写到磁盘。只要事务成功提交，数据必然已经持久化。 
C. Undo log必须先于数据持久化到磁盘。如果在G,H之间系统崩溃，undo log是完整的,可以用来回滚事务。 
D. 如果在A-F之间系统崩溃,因为数据没有持久化到磁盘。所以磁盘上的数据还是保持在事务开始前的状态。 
缺点：每个事务提交前将数据和Undo Log写入磁盘，这样会导致大量的磁盘IO，因此性能很低。

### 三、Redo Log

redo log就是保存执行的SQL语句到一个指定的Log文件，当mysql执行数据恢复时，重新执行redo log记录的SQL操作即可。引入buffer pool会导致更新的数据不会实时持久化到磁盘，当系统崩溃时，虽然buffer pool中的数据丢失，数据没有持久化，但是系统可以根据Redo Log的内容，将所有数据恢复到最新的状态。redo log在磁盘上作为一个独立的文件存在。默认情况下会有两个文件，名称分别为 ib_logfile0和ib_logfile1。

参数innodb_log_file_size指定了redo log的大小；innodb_log_file_in_group指定了redo log的数量，默认为2; innodb_log_group_home_dir指定了redo log所在路径。

```
innodb_additional_mem_pool_size = 100M
innodb_buffer_pool_size = 128M
innodb_data_home_dir = /home/mysql/local/mysql/var
innodb_data_file_path = ibdata1:1G：autoextend
innodb_file_io_threads = 4
innodb_thread_concurrency = 16
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 8M
innodb_log_file_size = 128M
innodb_log_file_in_group = 2
innodb_log_group_home_dir = /home/mysql/local/mysql/var
```

为了满足事务的原子性，在操作任何数据之前，首先将数据备份到Undo Log，然后进行数据的修改。如果出现了错误或者用户执行了ROLLBACK语句，系统可以利用Undo Log中的备份将数据恢复到事务开始之前的状态。与redo log不同的是，磁盘上不存在单独的undo log文件，它存放在数据库内部的一个特殊段(segment)中，这称为undo段(undo segment)，undo段位于共享表空间内。

Innodb为每行记录都实现了三个隐藏字段：

- 6字节的事务ID（DB_TRX_ID）
- 7字节的回滚指针（DB_ROLL_PTR）
- 隐藏的ID

#### redo log的记录内容

undo log和 redo log本身是分开的。innodb的undo log是记录在数据文件(ibd)中的，而且innodb将undo log的内容看作是数据，因此对undo log本身的操作(如向undo log中插入一条undo记录等)，都会记录redo log。undo log可以不必立即持久化到磁盘上。即便丢失了，也可以通过redo log将其恢复。因此当插入一条记录时：

1. 向undo log中插入一条undo log记录。
2. 向redo log中插入一条”插入undo log记录“的redo log记录。
3. 插入数据。
4. 向redo log中插入一条”insert”的redo log记录。

#### redo log的io性能

为了保证Redo Log能够有比较好的IO性能，InnoDB 的 Redo Log的设计有以下几个特点：

1. 尽量保持Redo Log存储在一段连续的空间上。因此在系统第一次启动时就会将日志文件的空间完全分配。以顺序追加的方式记录Redo Log。
2. 批量写入日志。日志并不是直接写入文件，而是先写入redo log buffer,然后每秒钟将buffer中数据一并写入磁盘
3. 并发的事务共享Redo Log的存储空间，它们的Redo Log按语句的执行顺序，依次交替的记录在一起，以减少日志占用的空间。
4. Redo Log上只进行顺序追加的操作，当一个事务需要回滚时，它的Redo Log记录也不会从Redo Log中删除掉。

①原理

　　和Undo Log相反，Redo Log记录的是新数据的备份。在事务提交前，只要将Redo Log持久化即可，不需要将数据持久化。当系统崩溃时，虽然数据没有持久化，但是Redo Log已经持久化。系统可以根据Redo Log的内容，将所有数据恢复到最新的状态。

②Undo + Redo事务的简化过程 

A.事务开始. 
B.记录A=1到undo log. 
C.修改A=3. 
D.记录A=3到redo log. 
E.记录B=2到undo log. 
F.修改B=4. 
G.记录B=4到redo log. 
H.将redo log写入磁盘。 
I.事务提交

### 四、小结

A-G的过程是在内存中进行的，相应的操作记录在redo log buffer（B&E），redo log buffer（E&G）中，事务执行结果（此时未提交）也存在db buffer中（C&F），buffer满了就写入磁盘当中，如果buffer存储的事务数量都是1个，也就意味着是将日志立即刷入磁盘，那么数据的一致性很好保证。如果存储多个的话，是一次事务完成就会先将redo log同步到磁盘当中并有一个状态位来记录是否提交，再去真正的提交事务，将db buffer 中的数据同步到DB的磁盘当中去。要保证在db buffer中的内容写入磁盘数据库文件之前，应当把log buffer的内容写入磁盘日志文件。这种方式可以减少磁盘IO，增加吞吐量。 不过，这种方式适用于一致性要求不高的情景。因为如果出现断电等系统故障，log buffer、db buffer中的完成的事务还没同步到磁盘会丢失。 像银行这种要求事务较高的一致性，就一定要保证每次事务都要记录到磁盘中，如果服务器down了的时候去redo log中恢复，重做一次已经提交的事务。

### 五、redo & undo log的作用

- 数据持久化

    buffer pool中维护一个按脏页修改先后顺序排列的链表，叫flush_list。根据flush_list中页的顺序刷数据到持久存储。按页面最早一次被修改的顺序排列。正常情况下，dirty page什么时候flush到磁盘上呢？

    1. 当redo空间占满时，将会将部分dirty page flush到disk上，然后释放部分redo log。
    2. 当需要在Buffer pool分配一个page，但是已经满了，这时候必须 flush dirty pages to disk。一般地，可以通过启动参数 innodb_max_dirty_pages_pct控制这种情况，当buffer pool中的dirty page到达这个比例的时候，把dirty page flush到disk中。
    3. 检测到系统空闲的时候，会flush。

- 数据恢复

    随着时间的积累，Redo Log会变的很大。如果每次都从第一条记录开始恢复，恢复的过程就会很慢，从而无法被容忍。为了减少恢复的时间，就引入了Checkpoint机制。假设在某个时间点，所有的脏页都被刷新到了磁盘上。这个时间点之前的所有Redo Log就不需要重做了。系统记录下这个时间点时redo log的结尾位置作为checkpoint。在进行恢复时，从这个checkpoint的位置开始即可。Checkpoint点之前的日志也就不再需要了，可以被删除掉。

### 六、恢复(Recovery)

恢复策略 
　　前面说到未提交的事务和回滚了的事务也会记录Redo Log，因此在进行恢复时,这些事务要进行特殊的处理.有2种不同的恢复策略：

A. 进行恢复时，只重做已经提交了的事务。（返回给客户端的是已经提交一定保证数据的可恢复持久性） 
B. 进行恢复时，重做所有事务包括未提交的事务和回滚了的事务。然后通过Undo Log回滚那些未提交的事务。比如在B-E过程中down机了，那么恢复时根据undo log去重新模拟当时的情景（但是如果log buffer的空间很大，log没有同步到磁盘这个过程就没有办法来进行，同时由于事务没有提交，返回给客户端的值是未提交成功，所以也没有关系）