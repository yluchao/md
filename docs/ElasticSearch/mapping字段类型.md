# Dynamic Mapping 和常见字段类型

Mapping中的字段一旦设定后，禁止直接修改。因为倒排索引生成后不允许直接修改。需要重新建立新的索引，做reindex操作。

类似数据库中表结构的概念，主要作用如下

- 定义索引下面的名字
- 定义字段的类型
- 定义倒排索引相关的配置（是否被索引）

Mapping 会把JSON文档映射成 Lucene 所需要的扁平格式一个Mapping 属于一个索引的 Type or 每个文档都属于一个Type



![image-20210124213650273](http://img.yluchao.cn/typora/ff02fdd0bb36e0f1025bafd0d2b8cc9c.png)

![image-20210124213706984](http://img.yluchao.cn/typora/83899601376b38b7155025c647b33d63.png)

### 能否更改Mapping的字段类型

主要分两种情况

- 新增加字段
    - Dynamic设为true时，一旦有新增字段的文档写入，Mapping也同时被
        更新
    - Dynamic设为false，Mapping 不会被更新，新增字段的数据无法被索引，但是信息会出现在_source中
    - Dynamic设置成 Strict，文档写入失败
- 对已有字段，一旦已经有数据写入，就不再支持修改字段定义
    - Lucene 实现的倒排索引，一旦生成后，就不允许修改
- 如果希望改变字段类型，必须 Reindex APl，重建索引

原因

- 如果修改了字段的数据类型，会导致已被索引的属于无法被搜索
- 但是如果是增加新的字段，就不会有这样的影响

# 什么是Dynamic Template

根据Elasticsearch识别的数据类型，结合字段名称，来动态设定字段类型

- 所有的字符串类型都设定成 Keyword，或者关闭keyword字段
- is开头的字段都设置成boolean
- long_开头的都设置成long类型