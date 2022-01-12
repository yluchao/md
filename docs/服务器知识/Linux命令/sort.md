对文本文件中所有行进行排序 

#### 主要用途  

- 将所有输入文件的内容排序后并输出。  
- 当没有文件或文件为 - 时， 读取标准输入。

#### 选项

```sh
-b, --ignore-leading-blanks 忽略开头的空白。
-d, --dictionary-order 仅考虑空白、 字母、 数字。
-f, --ignore-case 将小写字母作为大写字母考虑。
-g, --general-numeric-sort 根据数字排序。
-i, --ignore-nonprinting 排除不可打印字符。
-M, --month-sort 按照非月份、 一月、 十二月的顺序排序。
-h, --human-numeric-sort 根据存储容量排序(注意使用大写字母， 例如： 2K 1G)。
-n, --numeric-sort 根据数字排序。
-R, --random-sort 随机排序， 但分组相同的行。
--random-source=FILE 从FILE中获取随机长度的字节。
-r, --reverse 将结果倒序排列。
--sort=WORD 根据WORD排序， 其中: general-numeric 等价于 -g， human-numeric 等价于 -h， month 等价于 -M， numeric 等价于 -n， random 等价于 -R， version 等价于 -V。
-V, --version-sort 文本中(版本)数字的自然排序
```

#### 其他选项

```sh
--batch-size=NMERGE 一次合并最多NMERGE个输入； 超过部分使用临时文件。
-c, --check, --check=diagnose-first 检查输入是否已排序， 该操作不会执行排序。
-C, --check=quiet, --check=silent 类似于 -c 选项， 但不输出第一个未排序的行。
--compress-program=PROG 使用PROG压缩临时文件； 使用PROG -d解压缩。
--debug 注释用于排序的行， 发送可疑用法的警报到stderr。
--files0-from=F 从文件F中读取以NUL结尾的所有文件名称； 如果F是- ， 那么从标准输入中读取名字。
-k, --key=KEYDEF 通过一个key排序； KEYDEF给出位置和类型。
-m, --merge 合并已排序文件， 之后不再排序。
-o, --output=FILE 将结果写入FILE而不是标准输出。
-s, --stable 通过禁用最后的比较来稳定排序。
-S, --buffer-size=SIZE 使用SIZE作为内存缓存大小。
-t, --field-separator=SEP 使用SEP作为列的分隔符。
-T, --temporary-directory=DIR 使用DIR作为临时目录， 而不是 $TMPDIR 或/tmp； 多次使用该选项指定多个临时目录。
--parallel=N 将并发运行的排序数更改为N。
-u, --unique 同时使用-c， 严格检查排序； 不同时使用-c， 输出排序后去重的结果。
-z, --zero-terminated 设置行终止符为NUL（空） ， 而不是换行符。
--help 显示帮助信息并退出。
--version 显示版本信息并退出。


KEYDEF的格式为： F[.C][OPTS][,F[.C][OPTS]] ， 表示开始到结束的位置。
F表示列的编号
C表示
OPTS为[bdfgiMhnRrV]中的一到多个字符， 用于覆盖当前排序选项。
使用--debug选项可诊断出错误的用法。
SIZE 可以有以下的乘法后缀:
% 内存的1%；
b 1；
K 1024（默认） ；
剩余的 M, G, T, P, E, Z, Y 可以类推出来。
```

