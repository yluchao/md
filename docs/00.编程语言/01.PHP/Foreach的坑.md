1. 两次循环如果不实用引用打印结果没有任何问题
```php
$array = ['a','b','c'];
foreach ($array as $value){}
foreach ($array as $value){}
var_dump("<pre>", $array);

//执行结果
array(3) {
  [0]=>
  string(1) "a"
  [1]=>
  string(1) "b"
  [2]=>
  string(1) "c"
}
```
2. 当第一次循环使用引用后会出现如下bug

代码如下：
```php
$array = ['a','b','c'];
foreach ($array as &$value){}
foreach ($array as $value){}
var_dump("<pre>", $array);
执行结果：

array(3) {
  [0]=>
  string(1) "a"
  [1]=>
  string(1) "b"
  [2]=>
  &string(1) "b"
}
```
分析原因：

![img](https://img.yluchao.cn/typora/526fc5ca4c694b6a99a6b83c32c9cae7.jpeg)

从官网的信息来看，foreach循环时，是通过移动数组内部指针来实现的。

大家可以通过在第二个数组中打印array来观察数组数据的变化，

通过下图可以跟直观的看到循环流程。

![img](https://img.yluchao.cn/typora/5b08f5464fc575c649252515c50a3a0b.png)