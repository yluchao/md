## 进程状态

一个进程的生命周期可以划分为一组状态，这些状态刻画了整个进程。进程状态即体现一个进程的生命状态

一般来说，进程有五种状态：

- 创建状态：进程在创建时需要申请一个空白PCB，向其中填写控制和管理进程的信息，完成资源分配。如果创建工作无法完成，比如资源无法满足，就无法被调度运行，把此时进程所处状态称为创建状态
- 就绪状态：进程已经准备好，已分配到所需资源，只要分配到CPU就能够立即运行
- 执行状态：进程处于就绪状态被调度后，进程进入执行状态
- 阻塞状态：正在执行的进程由于某些事件（I/O请求，申请缓存区失败）而暂时无法运行，进程受到阻塞。在满足请求时进入就绪状态等待系统调用
- 终止状态：进程结束，或出现错误，或被系统终止，进入终止状态。无法再执行

![img](https://img.yluchao.cn/typora/c15aeee59bfe54e95f9fce860fded29f.jpeg)

```c
/*
* The task state array is a strange "bitmap" of
* reasons to sleep. Thus "running" is zero, and
* you can test for combinations of others with
* simple bit tests.
*/
static const char * const task_state_array[] = {
"R (running)", /* 0 */
"S (sleeping)", /* 1 */
"D (disk sleep)", /* 2 */
"T (stopped)", /* 4 */
"t (tracing stop)", /* 8 */
"X (dead)", /* 16 */
"Z (zombie)", /* 32 */
};
```

这些状态的具体含义是：

- R运行状态（running）: 并不意味着进程一定在运行中，它表明进程要么是在运行中要么在运行队列 里。
- S睡眠状态（sleeping): 意味着进程在等待事件完成（这里的睡眠有时候也叫做可中断睡眠 （interruptible sleep））。
- D磁盘休眠状态（Disk sleep）有时候也叫不可中断睡眠状态（uninterruptible sleep），在这个状态的 进程通常会等待IO的结束。
- T停止状态（stopped）： 可以通过发送 SIGSTOP 信号给进程来停止（T）进程。这个被暂停的进程可 以通过发送 SIGCONT 信号让进程继续运行。
- X死亡状态（dead）：这个状态只是一个返回状态，你不会在任务列表里看到这个状态。
- Z僵死状态（zombie）：下文具体了解

### 父进程与子进程

在学习接下来的内容之前，需要对父进程和子进程有一个清晰的认识

在Linux里，除了进程0（即PID=0的进程）以外的所有进程都是由其他进程使用系统调用fork创建的，这里调用fork创建新进程的进程即为父进程，而相对应的为其创建出的进程则为子进程，因而除了进程0以外的进程都只有一个父进程，但一个进程可以有多个子进程。

fork函数包含在unistd.h库中，其最主要的特点是，调用一次，返回两次，当父进程fork()创建子进程失败时，fork()返回-1，当父进程fork()创建子进程成功时，此时，父进程会返回子进程的pid，而子进程返回的是0。所以可以根据返回值的不同让父进程和子进程执行不同的代码



![img](https://img.yluchao.cn/typora/43770c7fe0c96d3cf11031ce33c420da.jpeg)



如上图所示，当fork()函数调用后，父进程中的变量pid赋值成子进程的pid(pid>0)，所以父进程会执行else里的代码，打印出"This is the parent"，而子进程的变量pid赋值成0，所以子进程执行if(pid == 0)里的代码，打印出"This is the child"

现在我们知道，在Linux中，正常情况下，子进程是通过父进程创建的，子进程再创建新的子进程。但是子进程的结束和父进程的运行是一个异步过程，即父进程永远无法预测子进程到底什么时候结束。当一个进程完成它的工作终止之后，它的父进程需要调用wait()或者waitpid()系统调用取得子进程的终止状态。

知道了这些，我们再来了解两种特殊的进程

## 僵尸进程和孤儿进程

### 僵尸进程

> 当一个子进程结束运行（一般是调用exit、运行时发生致命错误或收到终止信号所导致）时，子进程的退出状态（返回值）会回报给操作系统，系统则以SIGCHLD信号将子进程被结束的事件告知父进程，此时子进程的进程控制块（PCB）仍驻留在内存中。一般来说，收到SIGCHLD后，父进程会使用wait系统调用以获取子进程的退出状态，然后内核就可以从内存中释放已结束的子进程的PCB；而如若父进程没有这么做的话，子进程的PCB就会一直驻留在内存中，也即成为僵尸进程

简单来说，当进程退出但是父进程并没有调用wait或waitpid获取子进程的状态信息时就会产生僵尸进程

上文中提到的进程的僵死状态Z(zombie)就是僵尸进程对应的状态

我们可以写一个程序来查看一下僵尸进程：

```c
#include<stdio.h>
#include<unistd.h>
#include<stdlib.h>

int main(){
  printf("pid = %d\n",getpid());
  pid_t pid = fork();
  if(pid < 0){
    printf("fork error\n");
    return -1;
  }else if(pid == 0){
    //这段代码只有子进程能够运行到，因为在子进程中fork的返回值为0
    printf("This is the child!pid = %d\n",getpid());
    sleep(5);
    exit(0); //退出进程
  }else if(pid > 0){
    //这段代码只有父进程能运行到
    printf("This is the parent!pid = %d\n",getpid());
  }
  //当fork成功时下面的代码父子进程都会运行到
  while(1){
    printf("-------------pid = %d\n",getpid());
    sleep(1);
  }
  return 0;
}
```

程序的运行结果：

```text
ubuntu@VM-0-7-ubuntu:~/c_practice$ ./zombie 
pid = 24816
This is the parent!pid = 24816
-------------pid = 24816
This is the child!pid = 24817
-------------pid = 24816
-------------pid = 24816
.....
```

在程序开始运行时立即查看进程：

*(这里我分别运行了两次，分别使用ps -ef和ps -aux查看了进程状态，所以两次的进程PID是不同的)*

```text
ubuntu@VM-0-7-ubuntu:~$ ps -ef | grep -v grep | grep zombie
ubuntu   23797 15818  0 14:53 pts/0    00:00:00 ./zombie
ubuntu   23798 23797  0 14:53 pts/0    00:00:00 ./zombie

ubuntu@VM-0-7-ubuntu:~$ ps -aux | grep -v grep | grep zombie
ubuntu   24288  0.0  0.0   4352   648 pts/0    S+   14:56   0:00 ./zombie
ubuntu   24289  0.0  0.0   4352    80 pts/0    S+   14:56   0:00 ./zombie
```

在进程运行五秒后再次查看进程：

```text
ubuntu@VM-0-7-ubuntu:~$ ps -ef | grep -v grep | grep zombie
ubuntu   23797 15818  0 14:53 pts/0    00:00:00 ./zombie
ubuntu   23798 23797  0 14:53 pts/0    00:00:00 [zombie] <defunct>

ubuntu@VM-0-7-ubuntu:~$ ps -aux | grep -v grep | grep zombie
ubuntu   24288  0.0  0.0   4352   648 pts/0    S+   14:56   0:00 ./zombie
ubuntu   24289  0.0  0.0      0     0 pts/0    Z+   14:56   0:00 [zombie] <defunct>
```

可以看出当进程运行五秒后，子进程状态变成Z，就是僵死状态，子进程就成了僵尸进程

其实，僵尸进程是有危害的。进程的退出状态必须被维持下去，因为它要告诉关心它的进程（父进程），你交给我的任务，我办的怎么样了。可父进程如果一直不读取，那子进程就一直处于Z状态。维护退出状态本身就是要用数据维护，也属于进程基本信息，所以保存在task_struct(PCB)中，换句话说，当一个进程一直处于Z状态，那么它的PCB也就一直都要被维护。因为PCB本身就是一个结构体会占用空间，僵尸进程也就会造成资源浪费，所以我们应该避免僵尸进程的产生

### 孤儿进程

孤儿进程则是指当一个父进程退出，而它的一个或多个子进程还在运行，那么那些子进程将成为孤儿进程。孤儿进程将被init进程(进程号为1)所收养，并由init进程对它们完成状态收集工作。

来段代码：

```c
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include<errno.h>

int main(){ 
  pid_t pid;
  pid = fork();
  if(pid < 0){  
    perror("fork error");
    exit(1);
  }
  if(pid == 0){ 
    printf("This is the child!\n");
    printf("pid = %d,ppid = %d\n",getpid(),getppid());//父进程退出前的pid和ppid
    sleep(5);
    printf("\npid = %d,ppid = %d\n",getpid(),getppid());//父进程退出后的pid和ppid
  }else{  
    printf("This is the father!\n");
    sleep(1);
    printf("father process is exited!\n");
  }
  return 0;
}
```

运行结果：

```shell
ubuntu@VM-0-7-ubuntu:~/c_practice$ ./orphan 
This is the father!
This is the child!
pid = 2338,ppid = 2337
father process is exited!
ubuntu@VM-0-7-ubuntu:~/c_practice$ 
pid = 2338,ppid = 1
```

我们可以看到结果和我们预见的是一样的，孤儿进程在父进程退出后会被init进程领养，直到自己运行结束为止。这个程序很容易理解,先输出子进程的pid和父进程的pid，再然后子进程开始睡眠父进程退出，这时候子进程变成孤儿进程，再次输出时，该进程的父进程变为init孤儿进程由于有init进程循环的wait()回收资源，因此并没有什么危害