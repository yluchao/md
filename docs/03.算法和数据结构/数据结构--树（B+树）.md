![图片](https://img.yluchao.cn/typora/c6e10bfa6320c7f1208842c452fb41a3.webp)





![图片](https://img.yluchao.cn/typora/85cbce2ab260c378abf4f7ef7f08bf67.webp)





![图片](https://img.yluchao.cn/typora/dacf48fce0f138d9df33b6705098ebbd.webp)





![图片](https://img.yluchao.cn/typora/9528e67a51f49d2c29c1d9ffb98c58e1.webp)





**一个m阶的B树具有如下几个特征：**

1. 根结点至少有两个子女。

2. 每个中间节点都包含k-1个元素和k个孩子，其中 m/2 <= k <= m

3. 每一个叶子节点都包含k-1个元素，其中 m/2 <= k <= m

4. 所有的叶子结点都位于同一层。

5. 每个节点中的元素从小到大排列，节点当中k-1个元素正好是k个孩子包含的元素的值域分划。

![图片](https://img.yluchao.cn/typora/8a7b12c878da984a02367417edb3fe91.webp)





**一个m阶的B+树具有如下几个特征：**

1.有k个子树的中间节点包含有k个元素（B树中是k-1个元素），每个元素不保存数据，只用来索引，所有数据都保存在叶子节点。

2.所有的叶子结点中包含了全部元素的信息，及指向含这些元素记录的指针，且叶子结点本身依关键字的大小自小而大顺序链接。

3.所有的中间节点元素都同时存在于子节点，在子节点元素中是最大（或最小）元素。

![图片](https://img.yluchao.cn/typora/5703e1712b2792fce7af9c25dd317dc8.webp)

![图片](https://img.yluchao.cn/typora/f9a2d3bfcc77bb4b82afb0824fbab4a5.webp)





![图片](https://img.yluchao.cn/typora/b2337549fbb7d5ea370d3dca88949b6b.webp)





![图片](https://img.yluchao.cn/typora/12f10530826c270e9146d3fa386eb3bb.webp)





![图片](https://img.yluchao.cn/typora/87f14a66094f8cbf7195c318488c4fc0.webp)





![图片](https://img.yluchao.cn/typora/7032347e4ac2b4f830c0f3f10b09f712.webp)

![图片](https://img.yluchao.cn/typora/1b4472a8d6b71ebc9c4d4dfbc0bec721.webp)





![图片](https://img.yluchao.cn/typora/058bce21d553199ce209bc592f606d2c.webp)





![图片](http://mmbiz.qpic.cn/mmbiz_jpg/NtO5sialJZGrhjbBgkNEqGwLjaRu359pW9yjIQHedIcYbWGTdknjMb4k2YCJbu4R0oenib3aHKKmNLrNHFVHFjHA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)





![图片](http://mmbiz.qpic.cn/mmbiz_jpg/NtO5sialJZGrhjbBgkNEqGwLjaRu359pW1mop77hmW0euicbCO0vyA4DPwMy4UbBvFWiaQiabibXkKLAgaicpwUicESYA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



![图片](https://img.yluchao.cn/typora/8fc279366c3b84b1080baafd33951009.webp)





![图片](https://img.yluchao.cn/typora/684a2b362cd001854633c7b099fee809.webp)

![图片](https://img.yluchao.cn/typora/6ab02153d1e3b04cbd75b3d25c50be8c.webp)



![图片](https://img.yluchao.cn/typora/c7bcb0d76c0ab86eb326f017ff0f08fd.webp)

B-树中的卫星数据（Satellite Information）：

![图片](https://img.yluchao.cn/typora/bec156d54e4ccf80ad1216a6b92460df.webp)





![图片](https://img.yluchao.cn/typora/31664e96f6536ef6f0bae064c779a563.webp)

B+树中的卫星数据（Satellite Information）：

![图片](https://img.yluchao.cn/typora/a3fb36ecb540f0e07d2281ff8acb1b65.webp)

需要补充的是，在数据库的聚集索引（Clustered Index）中，叶子节点直接包含卫星数据。在非聚集索引（NonClustered Index）中，叶子节点带有指向卫星数据的指针。

![图片](https://img.yluchao.cn/typora/53ed28cf28cca28f728c94bb46a6ccf1.webp)

![图片](https://img.yluchao.cn/typora/12d3068111d1f07e409545e2369d3874.webp)





![图片](https://img.yluchao.cn/typora/b67ac373e42572f1683b3425ff27ea47.webp)

第一次磁盘IO：

![图片](https://img.yluchao.cn/typora/c4806cc6439b5dbf08f0dcfdb8daca71.webp)

第二次磁盘IO：

![图片](https://img.yluchao.cn/typora/9570e62ffb233601d58910a47878c170.webp)

第三次磁盘IO：



![图片](https://img.yluchao.cn/typora/1232289655fbe52ec61a3c84a5ace4e1.webp)

![图片](https://img.yluchao.cn/typora/6900eb4c9a23f653b7ca5adb6a83cb14.webp)





![图片](https://img.yluchao.cn/typora/c1aea0d5f491722ac2537f59ae4446f1.webp)





![图片](https://img.yluchao.cn/typora/bac5f7d8dc2f3f6d3620879ba06ecc4d.webp)

![图片](https://img.yluchao.cn/typora/5ea5b7e89f9065038724c307d9b857b8.webp)



![图片](https://img.yluchao.cn/typora/c499cb6437ba1297ba635076dfb0f635.webp)

![图片](https://img.yluchao.cn/typora/c5ebeb48549bf7ea6bb36f231da6a118.webp)





**B-树的范围查找过程**

自顶向下，查找到范围的下限（3）：



![图片](https://img.yluchao.cn/typora/d4627853d36fd605cc61e62efcc72650.webp)





中序遍历到元素6：



![图片](https://img.yluchao.cn/typora/96d559e6f6c6d52b6a4ca06446d41287.webp)

中序遍历到元素8：

![图片](https://img.yluchao.cn/typora/7a8b92ec0c06048a67bf63d2a66ccfce.webp)

中序遍历到元素9：

![图片](https://img.yluchao.cn/typora/0df28e86ca6ec9fb745eac4d23de78c6.webp)

中序遍历到元素11，遍历结束：

![图片](https://img.yluchao.cn/typora/4f2b7225749299e25583a8edb1444dd6.webp)



![图片](https://img.yluchao.cn/typora/ee2fad078a83d01e8e23fad35e140567.webp)





![图片](https://img.yluchao.cn/typora/eb73547a579027db1bc12108b1abbf97.webp)





**B+树的范围查找过程**

自顶向下，查找到范围的下限（3）：

![图片](https://img.yluchao.cn/typora/c77932a919e2c6586e4ea2ee3f80294d.webp)

通过链表指针，遍历到元素6, 8：

![图片](https://img.yluchao.cn/typora/7c226828f51ae73b4df9540f6009779d.webp)

通过链表指针，遍历到元素9, 11，遍历结束：

![图片](https://img.yluchao.cn/typora/088ecee5114869e1c507b3bee256fbd9.webp)

![图片](https://img.yluchao.cn/typora/15834cc7d7172697550f0c56ee1ca0ac.webp)



![图片](https://img.yluchao.cn/typora/3dfd1294665c1dce0697fec703862af8.webp)

![图片](https://img.yluchao.cn/typora/cdfc065a4af80f724ca94fe34a65b1fc.webp)

![图片](https://img.yluchao.cn/typora/1b3a735b58b3143e8422c9a846f76bd2.webp)





**B+树的特征：**

1.有k个子树的中间节点包含有k个元素（B树中是k-1个元素），每个元素不保存数据，只用来索引，所有数据都保存在叶子节点。

2.所有的叶子结点中包含了全部元素的信息，及指向含这些元素记录的指针，且叶子结点本身依关键字的大小自小而大顺序链接。

3.所有的中间节点元素都同时存在于子节点，在子节点元素中是最大（或最小）元素。

**B+树的优势：**

1.单一节点存储更多的元素，使得查询的IO次数更少。

2.所有查询都要查找到叶子节点，查询性能稳定。

3.所有叶子节点形成有序链表，便于范围查询。

![图片](https://img.yluchao.cn/typora/95342d187d2f452005bf4cc1c11052f4.webp)