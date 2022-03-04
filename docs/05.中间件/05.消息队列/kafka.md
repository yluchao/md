https://www.jianshu.com/p/fad515985bcf?utm_campaign=maleskine&utm_content=note&utm_medium=seo_notes&utm_source=recommendation

# 基本概念

## 1. 主题（Topic）(数据逻辑存储单元)：
每条发送到broker的消息都有一个类别，这个类别称为topic，即 kafka 是面向 topic 的。
"一个topic就是一个queue, 一个队列"

## 2. 分区（Partition）(数据物理存储单元)：
[kafka-topics.sh 工具可以动态创建删除查看更新topic, 修改partition.
只能增加partition数量, 不能减少, 除非删除重建.]
partition 是物理上的概念，每个 topic 包含一个或多个 partition。
kafka 分配的单位是 partition。
一个Topic中的消息数据按照多个分区组织，分区是kafka消息队列组织的最小单位，
一个分区可以看作是一个FIFO（ First Input First Output的缩写，先入先出队列）的队列。
kafka分区是提高kafka性能的关键所在，当你发现你的集群性能不高时，
常用手段就是增加Topic的分区，分区里面的消息是按照从新到老的顺序进行组织，
消费者从队列头订阅消息，生产者从队列尾添加消息。
Partition在服务器上的表现形式就是一个一个的文件夹，
每个partition的文件夹下面会有多组segment文件，
每组segment文件又包含.index文件、.log文件、.timeindex文件（早期版本中没有）三个文件， 
log文件就实际是存储message的地方，而index和timeindex文件为索引文件，用于检索消息。
###"Message结构":
>> offset：offset是一个占8byte的有序id号，它可以唯一确定每条消息在parition内的位置！
>> kafka的存储文件都是按照offset.kafka来命名，用offset做名字的好处是方便查找。
>> 例如你想找位于2049的位置，只要找到2048.kafka的文件即可。
>> 当然the first offset就是00000000000.kafka。
>> 消息大小：消息大小占用4byte，用于描述消息的大小。
>> 消息体：消息体存放的是实际的消息数据（被压缩过），占用的空间根据具体的消息而不一样。

## 3、备份（Replication）(分为leader和follower)：
[kafka-reassign-partitions.sh工具可用来动态增加Replications数量.]
为了保证分布式可靠性，kafka0.8开始对每个分区的数据进行备份（不同的Broker上），
防止其中一个Broker宕机造成分区上的数据不可用。
Replication数量不能超过brokers数量, 否则创建topic时会报错.

## 4.偏移量(offset)
kafka为每条在分区的消息保存一个偏移量offset，这也是消费者在分区的位置。
比如一个偏移量是5的消费者，表示已经消费了从0-4偏移量的消息，下一个要消费的消息的偏移量是5

## 5.消费者：（Consumer）：
从消息队列中请求消息的客户端应用程序
一个消费者组中的消费者数量不要超过 topic 的 partition 的数量, 
否则多出的消费者将会被限制, 不去消费任何消息.

## 6.生产者：（Producer）  ：
向broker发布消息的应用程序

## 7.kafka实例(broker)：
Kafka支持水平扩展，一般broker数量越多，集群吞吐率越高。
Kafka中使用Broker来接受Producer和Consumer的请求，并把Message持久化到本地磁盘。
每个Cluster当中会选举出一个Broker来担任Controller，负责处理Partition的Leader选举，协调Partition迁移等工作。

## 8.Consumer group：
high-level consumer API 中，
每个 consumer 都属于一个 consumer group，每条消息只能被 consumer group 中的一个 Consumer 消费，但可以被多个 consumer group 消费。
kafka确保每个partition中的一条消息只能被某个consumer group中的一个consumer消费
kafka通过group coordinate管理consumer实例负责消费哪个partition, 默认支持range和round-robin消费
kafka在zk中保存了每个topic,每个partition在不同group的消费偏移量(offset), 通过更新偏移量, 保证每条消息都被消费
需要注意的是, 用多线程读消息时, 一个线程相当于一个consumer实例, 当consumer数量大于partition数量时, 有些线程读不到数据

## 9.leader：
Replication中的一个角色， producer 和 consumer 只跟 leader 交互。每个Replication集合中的Partition都会选出一个唯一的Leader，所有的读写请求都由Leader处理。其他Replicas从Leader处把数据更新同步到本地，过程类似大家熟悉的MySQL中的Binlog同步。

## 10.follower：
Replication中的一个角色，从 leader 中复制数据。

## 11.controller：
kafka 集群中的其中一个服务器，用来进行 leader election 以及 各种 failover。

## 12.zookeeper：
kafka 通过 zookeeper 来存储集群的 meta 信息。

## 13.ISR(In-Sync Replica)：
是Replicas的一个子集，表示目前Alive且与Leader能够“Catch-up”的Replicas集合。由于读写都是首先落到Leader上，所以一般来说通过同步机制从Leader上拉取数据的Replica都会和Leader有一些延迟(包括了延迟时间和延迟条数两个维度)，任意一个超过阈值都会把该Replica踢出ISR。每个Partition都有它自己独立的ISR。

## 14. Segment
每个Partition包含一个或多个Segment，每个Segment包含一个数据文件和一个与之对应的索引文件。

# 工作流程

应用程序A(producer)--将message按照topic分类-->push到kafka服务器集群(broker)中
应用程序B(consumer)--从kafka服务器集群(broker)中pull消息(message)

![img](https://img.yluchao.cn/typora/7eda80f59ffb949fc119bec3e7c5a282.webp)