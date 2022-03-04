# 语言內建的资源嵌入支持

之前市面上已经有很多把今天文件嵌入golang二进制程序的工具了，这次golang官方将这一功能加入了`embed`标准库，从语言层面上提供了支持。。

新的 embed 包使用新的 //go:embed 指令，在编译时嵌入的文件，并对其进行访问。现在可以轻松地将支持数据文件捆绑到 Go 程序中，从而使使用 Go 进行开发更加顺畅。通过它，真正做到部署时只有一个二进制文件。下面通过一个使用viper读取配置文件的例子看下：

```go
package main

import (
	"bytes"
	_ "embed"
	"fmt"
	"github.com/spf13/viper"
)
//go:embed env.yml
var configContent string

func main() {

	remoteViper := viper.New()
	remoteViper.SetConfigType("yaml")
	err := remoteViper.ReadConfig(bytes.NewBuffer([]byte(configContent)))
	if err != nil {
		return
	}
	res := remoteViper.Get("test.name")
	fmt.Println(res)
}
```

我们首先在对应的目录下创建了 `env.yml` 文件，并且写入文本内容：

```yml
test:
  name: 杨路超
```

在代码中编写了最为核心的 `//go:embed env.yml` 注解。注解的格式很简单，就是 `go:embed` 指令声明，外加读取的内容的地址，**可支持相对和绝对路径**。

输出结果：

```shell
[root@5CG026B3DH go]# go build -o main_no_embed main.go
[root@5CG026B3DH go]# ll
total 13636
-rw-r--r-- 1 root root      23 Nov 30 10:56 env.yml
-rw-r--r-- 1 root root      63 Nov 30 10:49 go.mod
-rw-r--r-- 1 root root   64860 Nov 30 10:49 go.sum
drwxr-xr-x 2 root root    4096 Nov 24 15:24 go_test
-rwxr-xr-x 1 root root 5666966 Nov 30 11:08 main_embed
-rw-r--r-- 1 root root     357 Nov 30 11:05 main.go
[root@5CG026B3DH go]# mv env.yml env.yml_bak
[root@5CG026B3DH go]# ll
total 13636
-rw-r--r-- 1 root root      23 Nov 30 10:56 env.yml_bak
-rw-r--r-- 1 root root      63 Nov 30 10:49 go.mod
-rw-r--r-- 1 root root   64860 Nov 30 10:49 go.sum
drwxr-xr-x 2 root root    4096 Nov 24 15:24 go_test
-rwxr-xr-x 1 root root 5666966 Nov 30 11:08 main_embed
-rw-r--r-- 1 root root     357 Nov 30 11:05 main.go
[root@5CG026B3DH go]# ./main_embed
杨路超
```

更多用法可查看[一文快速上手 Go embed](https://mp.weixin.qq.com/s?__biz=MzUxMDI4MDc1NA==&mid=2247486403&idx=1&sn=e68d83cd37670715939a409eae0744fb&chksm=f9041e9ece739788b8fb0a52068c6fae225b28cf44573d648d36552399ea7d6e81a1456a355e&scene=178&cur_album_id=1515516076481101825#rd)

# go modules的新特性

本次更新依旧带来了许多modules的新特性。

### GO111MODULE现在默认为on

1.16开始默认启用modules，这在1.15的时候已经预告过了。现在GO111MODULE的默认值为on。

不过golang还是提供了一个版本的适应期，如果你还不习惯modules，可以把GO111MODULE设置回auto。在1.17中这个环境变量将会被删除。

都1202年了，也该学学go modules怎么用了。

### go build不再更改mod相关文件

以前会自动下载依赖，这会更新mod文件。现在这一行为被禁止了。想要安装、更新依赖只能使用go get命令，go build和go test将不会再做这类工作。

### go install的变化

go install在1.16中也有了不小的变化。

首先是通过go install my.module/tool@1.0.0 这样在module末尾加上版本号，可以在不影响当前mod的依赖的情况下安装golang程序。

go install是未来唯一可以安装golang程序的命令，go get的编译安装功能现在可以靠`-d`选项关闭，而未来编译安装功能会从go get移除。

也就是说go的命令各司其职，不再长臂管辖了。

### 相对路径导入不在被允许

golang1.16开始禁止import导入的模块以`.`开头，模块路径中也不允许出现任何非ASCII字符，所以下面的代码不再合法：

```go
import (
    "./tools/factory"
    "../models/user"
)
```

### 新的GOVCS环境变量

新的GOVCS环境变量指定了golang用什么版本控制工具下载源代码。

其格式为：`GOVCS=<module prefix>:<tool name>,[<module prefix>:<tool name>, ...]`

其中module prefix为https://github.com等，而tool name就是版本控制工具的名字，比如git，svn。

一个更具体的例子是：`GOVCS=github.com:git,evil.com:off,*:git|hg`

module prefix也可以用`*`通配任何模块的前缀。

tool name还可以设置为all和off，all代表允许使用任何可用的工具，而off则表示不允许使用任何版本控制工具。

不过现在设置为off的模块的代码仍然可能会被下载。

更多的细节可以参考`go help vcs`。



对非ASCII字符一如既往的不友好，不过也只能按规矩办事了。

# 标准库的变化

## 废弃 io/ioutil

Go 官方认为 io/ioutil 这个包的定义不明确且难以理解。所以 Russ Cox 在 2020.10.17 提出了废弃 io/ioutil 的提案。

大致变更如下：

- Discard => io.Discard
- NopCloser => io.NopCloser
- ReadAll => io.ReadAll
- ReadDir => os.ReadDir
- ReadFile => os.ReadFile
- TempDir => os.MkdirTemp
- TempFile => os.CreateTemp
- WriteFile => os.WriteFile

与此同时大家也不需要担心存在破坏性变更，因为有 Go1 兼容性的保证，在 Go1 中 io/ioutil 还会存在，只变更内部的方法调用：

```
func ReadAll(r io.Reader) ([]byte, error) {
    return io.ReadAll(r)
}

func ReadFile(filename string) ([]byte, error) {
    return os.ReadFile(filename)
}
```

**大家在后续也可以改改调用习惯**。

## 新增 io/fs 的支持

新增了标准库 io/fs，正式将文件系统相关的基础接口抽象到了该标准库中。

以前的话大多是在 `os` 标准库中，这一步抽离更进一步的抽象了文件树的接口。在后续的版本中，大家可以优先考虑使用 `io/fs` 标准库。

### 调整切片扩容策略

Go1.16 以前的 slice 的扩容条件是 `len`，在最新的代码中，已经改为了以 `cap` 属性作为基准：

```go
// src/runtime/slice.go
if cap > doublecap {
    newcap = cap
} else {
    // 这是以前的代码：if old.len < 1024 {
    // 下面是 Go1.16rc1 的代码
    if old.cap < 1024 {
        newcap = doublecap
    }
}
```

以官方的 test case 为例：

```go
func main() {
	const N = 1024
	var a [N]int
	x := append(a[:N-1:N], 9, 9)
	y := append(a[:N:N], 9)
	println(cap(x), cap(y))
}
```

在 Go1.16 以前输出 2048, 1280。在 Go1.16 及以后输出 1280, 1280，保证了两种的一致。如下：

```shell
[root@5CG026B3DH go]# gvm use go1.15
Now using version go1.15
[root@5CG026B3DH go]# go run main.go
2048 1280
[root@5CG026B3DH go]# gvm use go1.16
Now using version go1.16
[root@5CG026B3DH go]# go run main.go
1280 1280
```

# 内存管理机制变更

不在啰嗦，感兴趣的可以阅读下这篇文章：[Go1.16 新特性：详解内存管理机制的变更，你需要了解](https://mp.weixin.qq.com/s?__biz=MzUxMDI4MDc1NA==&mid=2247486590&idx=1&sn=c073ed631816f65c23e83ab56b1e6b02&chksm=f9041923ce739035f9e9da0ee46acd2b74e4cc21ba1ed42aecac96301f9ee41508ba38b0fc2e&cur_album_id=1515516076481101825&scene=189#wechat_redirect)

# 其他变化

### 新增 GODEBUG inittrace

GODEBUG 新增 inittrace 指令，可以用于 `init` 方法的排查：

```shell
[root@5CG026B3DH go]# env GODEBUG=inittrace=1 go run main.go
```

输出结果：

```
init internal/bytealg @0.008 ms, 0 ms clock, 0 bytes, 0 allocs
init runtime @0.059 ms, 0.026 ms clock, 0 bytes, 0 allocs
init math @0.19 ms, 0.001 ms clock, 0 bytes, 0 allocs
init errors @0.22 ms, 0.004 ms clock, 0 bytes, 0 allocs
init strconv @0.24 ms, 0.002 ms clock, 32 bytes, 2 allocs
init sync @0.28 ms, 0.003 ms clock, 16 bytes, 1 allocs
init unicode @0.44 ms, 0.11 ms clock, 23328 bytes, 24 allocs
...
```

主要作用是 init 函数跟踪的支持，以用于 init 调试和启动时间的概要分析，算是一个 GODEBUG 的补充功能点。

## 简化结构体标签

在 Go 语言的结构体中，我们常常会因为各种库的诉求，需要对结构体的 `tag` 设置标识。

如果像是以前，量比较多就会变成：

```go
type MyStruct struct {
  Field1 string `json:"field_1,omitempty" bson:"field_1,omitempty" xml:"field_1,omitempty" form:"field_1,omitempty" other:"value"`
}
```

但在 Go1.16 及以后，就可以通过合并的方式：

```go
type MyStruct struct {
  Field1 string `json,bson,xml,form:"field_1,omitempty" other:"value"`
}
```

方便和简洁了不少。
