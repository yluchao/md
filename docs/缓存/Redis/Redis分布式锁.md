## Redis分布式锁的正确实现方式

#### 锁实现的注意点

1. 安全属性：互斥，不管任何时候，只有一个客户端能持有同一个锁。
2. 效率属性A：不会死锁，最终一定会得到锁，就算一个持有锁的客户端宕掉或者发生网络分区。
3. 效率属性B：容错，只要大多数Redis节点正常工作，客户端应该都能获取和释放锁。

如果考虑redis集群的分布式锁，参考 http://ifeve.com/redis-lock/



### 加锁

1. $key 对应的锁不存在, 进行加锁操作
2. $key 对应的锁已存在, 什么也不做

代码如下：

```php
$redis = new Redis();
$redis->pconnect("127.0.0.1", 6379);
$redis->auth("password");    // 密码验证
$redis->select(1);    // 选择所使用的数据库, 默认有16个

$key = "...";
$value = "...";
$expire = 3;

// 参数解释 ↓
// $value 加锁的客户端请求标识, 必须保证在所有获取锁清秋的客户端里保持唯一, 满足上面的第3个条件: 加锁/解锁的是同一客户端
// "NX" 仅在key不存在时加锁, 满足条件1: 互斥型
// "EX" 设置锁过期时间, 满足条件2: 避免死锁
$redis->set($key, $value, ["NX", "EX" => $expire]);
```

### 解锁

php解锁示例: 使用lua脚本

```php
$key = "...";
$identification = "...";
// KEYS 和 ARGV 是lua脚本中的全局变量
$script = <<< EOF
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
else
    return 0
end
EOF;
# $result = $redis->eval($script, [$key, $identification], 1);
// 返回结果 >0 表示解锁成功
// php中参数的传递顺序与标准不一样, 注意区分
// 第2个参数表示传入的 KEYS 和 ARGV, 通过第3个参数来区分, KEYS 在前, ARGV 在后
// 第3个参数表示传入的 KEYS 的个数
$result = $redis->evaluate($script, [$key, $identification], 1);    
```

使用lua脚本的原因:

- 避免误删其他客户端加的锁

    > eg. 某个客户端获取锁后做其他操作过久导致锁被自动释放, 这时候要避免这个客户端删除已经被其他客户端获取的锁, 这就用到了锁的标识.

- lua 脚本中执行 `get` 和 `del` 是原子性的, 整个lua脚本会被当做一条命令来执行

- 即使 `get` 后锁刚好过期, 此时也不会被其他客户端加锁

1. 用redis的setnx命令
2. key 使用uuid生成唯一的key，避免删除其他线程产生的key

保证所有的操作均为原子操作，在这里，可以使用lua脚本，保证原子性

```
redis 127.0.0.1:6379> EVAL "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}" 2 key1 key2 first second

1) "key1"
2) "key2"
3) "first"
4) "second"
```