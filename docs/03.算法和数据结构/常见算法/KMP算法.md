## 三：KMP字符串匹配算法

### 3.1 算法流程

以下摘自阮一峰的[字符串匹配的KMP算法](http://www.ruanyifeng.com/blog/2013/05/Knuth–Morris–Pratt_algorithm.html)，并作稍微修改。

（1）

![img](https://img.yluchao.cn/typora/a10d3722874b02987b53d17fc5468c10.png)

首先，主串"BBC ABCDAB ABCDABCDABDE"的第一个字符与模式串"ABCDABD"的第一个字符，进行比较。因为 B 与 A 不匹配，所以模式串后移一位。

（2）

![img](https://img.yluchao.cn/typora/8fd9210ade9812a5f97cc42d56f5cf43.png)

因为 B 与 A 又不匹配，模式串再往后移。

（3）

![img](https://img.yluchao.cn/typora/675ea0c2dfd1ce9966348cab42ea5c18.png)

就这样，直到主串有一个字符，与模式串的第一个字符相同为止。

（4）

![img](https://img.yluchao.cn/typora/f4d3fcc0cab82dd908a82bfc222046d0.png)

接着比较主串和模式串的下一个字符，还是相同。

（5）

![img](https://img.yluchao.cn/typora/1e4c6de1fd43c0706a259bab23bb86a6.png)

直到主串有一个字符，与模式串对应的字符不相同为止。

（6）

![img](https://img.yluchao.cn/typora/4399675e2ddcfe6fa9363362d60d426b.png)

这时，最自然的反应是，将模式串整个后移一位，再从头逐个比较。这样做虽然可行，但是效率很差，因为你要把"搜索位置"移到已经比较过的位置，重比一遍。

（7）

![img](https://img.yluchao.cn/typora/75d40919cdd6514c2f0d69b32124a7f2.png)

一个基本事实是，当空格与 D 不匹配时，你其实是已经知道前面六个字符是"ABCDAB"。KMP 算法的想法是，设法利用这个已知信息，不要把"搜索位置"移回已经比较过的位置，而是继续把它向后移，这样就提高了效率。

（8）

|    i    |  0   |  1   |  2   |  3   |  4   |  5   |  6   |  7   |
| :-----: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| 模式串  |  A   |  B   |  C   |  D   |  A   |  B   |  D   | '\0' |
| next[i] |  -1  |  0   |  0   |  0   |  0   |  1   |  2   |  0   |

怎么做到这一点呢？可以针对模式串，设置一个跳转数组`int next[]`，这个数组是怎么计算出来的，后面再介绍，这里只要会用就可以了。

（9）

![img](https://img.yluchao.cn/typora/1e4c6de1fd43c0706a259bab23bb86a6.png)

已知空格与 D 不匹配时，前面六个字符"ABCDAB"是匹配的。根据跳转数组可知，不匹配处 D 的 next 值为 2，因此接下来**从模式串下标为 2 的位置开始匹配**。

（10）

![img](https://img.yluchao.cn/typora/3193cdd4e57f579306a24ab94111edcc.png)

因为空格与 Ｃ 不匹配，C 处的 next 值为 0，因此接下来模式串从下标为 0 处开始匹配。

（11）

![img](https://img.yluchao.cn/typora/f20d2ba6935be0bc1e1ce25c64606a27.png)

因为空格与 A 不匹配，此处 next 值为 -1，表示模式串的第一个字符就不匹配，那么直接往后移一位。

（12）

![img](https://img.yluchao.cn/typora/a614f2278cf6928504736068321b2a7f.png)

逐位比较，直到发现 C 与 D 不匹配。于是，下一步从下标为 2 的地方开始匹配。即子串向右移动`j - next[j]`位

（13）

![img](https://img.yluchao.cn/typora/e252995df5fb080bbe58653f9f8ad302.png)

逐位比较，直到模式串的最后一位，发现完全匹配，于是搜索完成。

### 3.2 next 数组是如何求出的

next 数组的求解基于“真前缀”和“真后缀”，即`next[i]`等于`P[0]...P[i - 1]`最长的相同真前后缀的长度（请暂时忽视 i 等于 0 时的情况，下面会有解释）。我们依旧以上述的表格为例，为了方便阅读，我复制在下方了。

|     i     |  0   |  1   |  2   |  3   |  4   |  5   |  6   |  7   |
| :-------: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
|  模式串   |  A   |  B   |  C   |  D   |  A   |  B   |  D   | '\0' |
| next[ i ] |  -1  |  0   |  0   |  0   |  0   |  1   |  2   |  0   |

1. i = 0，对于模式串的首字符，我们统一为`next[0] = -1`；
2. i = 1，前面的字符串为`A`，其最长相同真前后缀长度为 0，即`next[1] = 0`；
3. i = 2，前面的字符串为`AB`，其最长相同真前后缀长度为 0，即`next[2] = 0`；
4. i = 3，前面的字符串为`ABC`，其最长相同真前后缀长度为 0，即`next[3] = 0`；
5. i = 4，前面的字符串为`ABCD`，其最长相同真前后缀长度为 0，即`next[4] = 0`；
6. i = 5，前面的字符串为`ABCDA`，其最长相同真前后缀为`A`，即`next[5] = 1`；
7. i = 6，前面的字符串为`ABCDAB`，其最长相同真前后缀为`AB`，即`next[6] = 2`；
8. i = 7，前面的字符串为`ABCDABD`，其最长相同真前后缀长度为 0，即`next[7] = 0`。

那么，为什么根据最长相同真前后缀的长度就可以实现在不匹配情况下的跳转呢？举个代表性的例子：假如`i = 6`时不匹配，此时我们是知道其位置前的字符串为`ABCDAB`，仔细观察这个字符串，首尾都有一个`AB`，既然在`i = 6`处的 D 不匹配，我们为何不直接把`i = 2`处的 C 拿过来继续比较呢，因为都有一个`AB`啊，而这个`AB`就是`ABCDAB`的最长相同真前后缀，其长度 2 正好是跳转的下标位置。

有的读者可能存在疑问，若在`i = 5`时匹配失败，按照我讲解的思路，此时应该把`i = 1`处的字符拿过来继续比较，但是这两个位置的字符是一样的啊，都是`B`，既然一样，拿过来比较不就是无用功了么？其实不是我讲解的有问题，也不是这个算法有问题，而是这个算法还未优化，关于这个问题在下面会详细说明，不过建议读者不要在这里纠结，跳过这个，下面你自然会恍然大悟。

思路如此简单，接下来就是代码实现了，如下：

```
/* P 为模式串，下标从 0 开始 */
void GetNext(string P, int next[])
{
    int p_len = P.size();
    int i = 0;   // P 的下标
    int j = -1;  
    next[0] = -1;

    while (i < p_len)
    {
        if (j == -1 || P[i] == P[j])
        {
            i++;
            j++;
            next[i] = j;
        }
        else
            j = next[j];
    }
}
```

一脸懵逼，是不是。。。上述代码就是用来求解模式串中每个位置的`next[]`值。

下面具体分析，我把代码分为两部分来讲：

**（1）：i 和 j 的作用是什么？**

i 和 j 就像是两个”指针“，一前一后，通过移动它们来找到最长的相同真前后缀。

**（2）：if...else...语句里做了什么？**

![img](https://img.yluchao.cn/typora/e5ba806403c4d6df47bd0b1dfc5cd65f.png)

假设 i 和 j 的位置如上图，由`next[i] = j`得，也就是对于位置 i 来说，**区段 [0, i - 1] 的最长相同真前后缀分别是 [0, j - 1] 和 [i - j, i - 1]，即这两区段内容相同**。

按照算法流程，`if (P[i] == P[j])`，则`i++; j++; next[i] = j;`；若不等，则`j = next[j]`，见下图：

![img](https://img.yluchao.cn/typora/19655d7a50513dc5dd3b2887783abbfa.png)

`next[j]`代表 [0, j - 1] 区段中最长相同真前后缀的长度。如图，用左侧两个椭圆来表示这个最长相同真前后缀，即这两个椭圆代表的区段内容相同；同理，右侧也有相同的两个椭圆。所以 else 语句就是利用第一个椭圆和第四个椭圆内容相同来加快得到 [0, i - 1] 区段的相同真前后缀的长度。

细心的朋友会问 if 语句中`j == -1`存在的意义是何？第一，程序刚运行时，j 是被初始为 -1，直接进行`P[i] == P[j]`判断无疑会边界溢出；第二，else 语句中`j = next[j]`，j 是不断后退的，若 j 在后退中被赋值为 -1（也就是`j = next[0]`），在`P[i] == P[j]`判断也会边界溢出。综上两点，其意义就是为了特殊边界判断。

## 四：完整代码

```php
<?php

function getNext($pattern)
{
	$next = [];
	$i = 0;
	$j = -1;
	$next[0] = -1;

	while ($i < strlen($pattern)) {
		if ($j == -1 || $pattern[$i] == $pattern[$j]) {
			$i++;
			$j++;
			$next[$i] = $j;
		} else {
			$j = $next[$j];
		}
	}
	return $next;
}

function kmp($str, $pattern)
{
	$next = getNext($pattern);
	$i = $j = 0;
	$len_s = strlen($str);
	$len_p = strlen($pattern);
	while ($i < $len_s && $j < $len_p) {
		if ($j == -1 || $str[$i] == $pattern[$j]) {
			$i++;
			$j++;
		} else {
			$j = $next[$j];
		}
	}
	if ($j == $len_p) {
		return $i - $j;
	}
	return -1;
}


var_dump(kmp('abcdabe', 'abe'));
```

## 五：KMP优化

|    i    |  0   |  1   |  2   |  3   |  4   |  5   |  6   |  7   |
| :-----: | :--: | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| 模式串  |  A   |  B   |  C   |  D   |  A   |  B   |  D   | '\0' |
| next[i] |  -1  |  0   |  0   |  0   |  0   |  1   |  2   |  0   |

以 3.2 的表格为例（已复制在上方），若在`i = 5`时匹配失败，按照 3.2 的代码，此时应该把`i = 1`处的字符拿过来继续比较，但是这两个位置的字符是一样的，都是`B`，既然一样，拿过来比较不就是无用功了么？这我在 3.2 已经解释过，之所以会这样是因为 KMP 还未优化。那怎么改写就可以解决这个问题呢？很简单。

```
/* P 为模式串，下标从 0 开始 */
void GetNextval(string P, int nextval[])
{
    int p_len = P.size();
    int i = 0;   // P 的下标
    int j = -1;  
    nextval[0] = -1;

    while (i < p_len)
    {
        if (j == -1 || P[i] == P[j])
        {
            i++;
            j++;
          
            if (P[i] != P[j])
                nextval[i] = j;
            else
                nextval[i] = nextval[j];  // 既然相同就继续往前找真前缀
        }
        else
            j = nextval[j];
    }
}
```