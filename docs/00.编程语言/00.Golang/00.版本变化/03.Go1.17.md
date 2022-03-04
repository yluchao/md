# 允许从切片到数组指针的转换

第一个是对语言类型转换规则的扩展，允许从切片到数组指针的转换，下面的代码在Go 1.17版本中是可以正常编译和运行的：

```go
// github.com/bigwhite/experiments/tree/master/go1.17-examples/lang/slice2arrayptr/main.go
func slice2arrayptr() {
    var b = []int{11, 12, 13}
    var p = (*[3]int)(b)
    p[1] = p[1] + 10
    fmt.Printf("%v\n", b) // [11 22 13]
}
```

Go通过运行时对这类切片到数组指针的转换代码做检查，如果发现越界行为，就会通过运行时panic予以处理。Go运行时实施检查的一条原则就是“转换后的数组长度不能大于原切片的长度”，注意这里是切片的长度(len)，而不是切片的容量(cap)。

第二个变动则是unsafe包增加了两个函数：Add与Slice。使用这两个函数可以让开发人员更容易地写出符合[unsafe包使用的安全规则]的代码。这两个函数原型如下：

```go
// $GOROOT/src/unsafe.go
func Add(ptr Pointer, len IntegerType) Pointe
func Slice(ptr *ArbitraryType, len IntegerType) []ArbitraryType
```

unsafe.Add允许更安全的指针运算，而unsafe.Slice允许更安全地将底层存储的指针转换为切片。

# 引入//go:build形式的构建约束指示符，以替代原先易错的// +build形式

构建约束主要解决了代码解耦问题，例如我们写的采集器，会针对不同的系统都有要一套采集代码，返回结果是一样的。如果采用这中方式，只需针对不同的系统要增加文件即可。完美解决了以前都是先判断系统，然后switch的方式。

Go 1.17之前，我们可以通过在源码文件头部放置+build构建约束指示符来实现构建约束，但这种形式十分易错，并且它并不支持&&和||这样的直观的逻辑操作符，而是用逗号、空格替代，下面是原+build形式构建约束指示符的用法及含义：

| build tags                       | 含义                                     |
| -------------------------------- | ---------------------------------------- |
| // +build tag1 tag2              | tag1 or tag2                             |
| // +build tag1,tag2              | tag1 and tag2                            |
| // +build !tag1                  | not tag1                                 |
| // +build tag1<br>// +build tag2 | tag1 and tag2                            |
| // +build tag1,tag2 tag3,!tag4   | (tag1 and tag2) or (tag3 and (not tag4)) |

这种与程序员直觉“有悖”的形式让Gopher们十分痛苦，于是Go 1.17回归“正规”，引入了//go:build形式的构建约束指示符[6]，这样一方面是与源文件中的其他指示符保持形式一致，比如: //go:nosplit、//go:norace、//go:noinline、//go:generate等。另外一方面，新形式将支持&&和||逻辑操作符，对于程序员来说，这样的形式就是自解释的，我们无需再像上面那样列出一个表来解释每个指示符组合的含义了，如下代码所示：

```go
//go:build linux && (386 || amd64 || arm || arm64 || mips64 || mips64le || ppc64 || ppc64le)
//go:build linux && (mips64 || mips64le)
//go:build linux && (ppc64 || ppc64le)
//go:build linux && !386 && !arm
```

考虑到兼容性，Go命令可以识别这两种形式的构建约束指示符，但推荐Go 1.17之后都用新引入的这种形式。

gofmt可以兼容处理两种形式，处理原则是：如果一个源码文件只有// +build形式的指示符，gofmt会将与其等价的//go:build行加入。否则，如果一个源文件中同时存在这两种形式的指示符行，那么//+build行的信息将被//go:build行的信息所覆盖。

go vet工具也会检测源文件中同时存在的不同形式的构建指示符语义不一致的情况，比如针对下面这段代码：

```go
// github.com/bigwhite/experiments/tree/master/go1.17-examples/runtime/buildtag.go

//go:build linux && !386 && !arm
// +build linux

package main

import "fmt"

func main() {
    fmt.Println("hello, world")
}
```

go vet会提示如下问题：

```shell
./buildtag.go:2:1: +build lines do not match //go:build condition
```

# go module的变化

自[Go 1.11版本引入go module]以来，每个Go大版本发布时，go module都会有不少的积极变化，这是Go核心团队与社区就go module深入互动的结果。

Go 1.17中go module同样有几处显著变化，其中最最重要的一个变化就是pruned module graph（修剪的module依赖图）。Go 1.17之前的版本某个module的依赖图由该module的直接依赖以及所有间接依赖组成，无论某个间接依赖是否真正为原module的构建做出贡献，这样go命令在解决依赖时会读取每个依赖的go.mod，包括那些没有被真正使用到的module，这样形成的module依赖图被称为**完整module依赖图（complete module graph）**。

Go 1.17不再使用“完整module依赖图”，而是引入了pruned module graph（修剪的module依赖图）。修剪的module依赖图就是在完整module依赖图的基础上将那些“占着茅坑不拉屎”、对构建完全没有“贡献”的间接依赖module修剪后的依赖图。使用修剪后的module依赖图进行构建将有助于避免下载或阅读那些不必要的go.mod文件，这样Go命令可以不去获取那些不相关的依赖关系，从而在日常开发中节省时间。

但module依赖图修剪也带来了一个副作用，那就是go.mod文件size的变大。因为Go 1.17版本后，每次go mod tidy（当go.mod中的go版本为1.17时），go命令都会对main module的依赖做一次深度扫描(deepening scan)，并将main module的所有直接和间接依赖都记录在go.mod中（之前说的版本只记录直接依赖）。考虑到内容较多，go 1.17将直接依赖和间接依赖分别放在两个不同的require块中。

go1.17之前的go.mod

```go
require (
   github.com/HdrHistogram/hdrhistogram-go v1.1.2 // indirect
   github.com/alecthomas/template v0.0.0-20190718012654-fb15b899a751
   github.com/uber/jaeger-lib v2.4.1+incompatible // indirect
   gopkg.in/alexcesaro/quotedprintable.v3 v3.0.0-20150716171945-2caba252f4dc // indirect
   ...
   gorm.io/gorm v1.21.16
)
```

go1.17及以后

```go
require (
	github.com/alecthomas/template v0.0.0-20190718012654-fb15b899a751
	github.com/dgrijalva/jwt-go v3.2.0+incompatible
    ...
	gorm.io/gorm v1.21.16
)

require (
	github.com/HdrHistogram/hdrhistogram-go v1.1.2 // indirect
    ...
	gopkg.in/yaml.v2 v2.4.0 // indirect
)
```

参考文章：

- [支持切片转换为数组指针](https://mp.weixin.qq.com/s/v1czjzlUsaSQTpAOG9Ub3w)
- [增强构建时的编译约束](https://mp.weixin.qq.com/s/5kLFIuI0UJl_o8vMmZNfoA)
- [优化 modules：支持模块依赖图裁剪、延时模块加载](https://mp.weixin.qq.com/s/2vVGVd_QJSrCeenuvwGS3g)
- [优化基于寄存器的函数参数和结果传递](https://mp.weixin.qq.com/s/cYnlPTM3R02_kZsIukmVfg)
- [优化恐慌所抛出的异常堆栈信息](https://mp.weixin.qq.com/s/zu5atVDYYaRIJ5sj96mlmg)

