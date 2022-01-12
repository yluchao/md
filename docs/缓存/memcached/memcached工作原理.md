## memcached是怎么工作的

​		Memcached的神奇来自两阶段哈希（two-stage hash）。Memcached就像一个巨大的、存储了很多<key,value>对的哈希表。通过key，可以存储或查询任意的数据。 客户端可以把数据存储在多台memcached上。当查询数据时，客户端首先参考节点列表计算出key的哈希值（阶段一哈 希），进而选中一个节点；客户端将请求发送给选中的节点，然后memcached节点通过一个内部的哈希算法（阶段二哈希），查找真正的数据 （item）。 

​		memcached的分布式主要体现在client端，对于server端，仅仅是部署多个memcached server组成集群，每个server独自维护自己的数据（互相之间没有任何通信），通过daemon监听端口等待client端的请求。
而在client端，通过一致的hash算法，将要存储的数据分布到某个特定的server上进行存储，后续读取查询使用同样的hash算法即可定位。

https://blog.csdn.net/litchi_yang/article/details/80059875

https://zhuanlan.zhihu.com/p/225412300

