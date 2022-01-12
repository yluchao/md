使用lockf使脚本仅运行一个
1. 下载安装
https://stuffivelearned.org/doku.php?id=programming:c:lockf

2. 使用方法
	```sh
	lockf -s -t 0 /tmp/sleep.lock php sleep.php
	[root@5CG026B3DH default]# ll /tmp/ | grep lock
	-rw-r--r-- 1 root   root        0 Jun  9 11:27 sleep.lock
	
	lockf -s -t 0 /tmp/sleep.lock php sleep.php # 这个程序不会在次执行.
	```
	lockf 参数:
	-k: 一直等到程序结束才执行.
	-s: silent, 不要发出任何信息, 即使拿不到 lock.
	-t seconds: 要等多久 timeout, 如果 timout 程序不会执行.

