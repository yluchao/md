非常感谢大家的指正。

![img](https://oscimg.oschina.net/oscnet/31e6af2e49f9d10fba11700c031c2f9600c.png)

![img](https://oscimg.oschina.net/oscnet/aafc2573d855db262ca41462edd017191a6.png)





**————— 第二天 —————**

![img](https://oscimg.oschina.net/oscnet/b7073d8debce4b79714e38b6c9386626b49.png)

![img](https://oscimg.oschina.net/oscnet/1627aa7cf54ef1f129b628f144e681931f3.png)

![img](https://oscimg.oschina.net/oscnet/006894ea6410c29c754f82f3d3842811539.png)

![img](https://oscimg.oschina.net/oscnet/334deb072a693e95b333e53070f3a3da7c9.png)

![img](https://oscimg.oschina.net/oscnet/a94272c1d9d31a33ab6cb85f299d082793a.png)

![img](https://oscimg.oschina.net/oscnet/bb035983356ca50970fa92e1b7b16d941ba.png)

![img](https://oscimg.oschina.net/oscnet/676a23bf69982b2350c7fc0d298116f90f3.png)





————————————

![img](https://oscimg.oschina.net/oscnet/abd55619cc4488a606fc9b57613361266dc.png)

![img](https://oscimg.oschina.net/oscnet/d58d8a3738a6170f83214ac5a429003d5a1.png)

![img](https://oscimg.oschina.net/oscnet/ace001944868f6cc3aaf867d20f365b6e57.png)



![img](https://oscimg.oschina.net/oscnet/d2121a174cecf6d487bba324b2022190313.png)

![img](https://oscimg.oschina.net/oscnet/c82259e67738f1addfdc40b03469d2ad8a5.png)

![img](https://oscimg.oschina.net/oscnet/324508878510f91cc089656426bc1c7b814.png)

![img](https://oscimg.oschina.net/oscnet/dd58473aa54ccbc2595c9afe4ed05ee9eb1.png)

![img](https://oscimg.oschina.net/oscnet/a3eab934ea70d8531883430c5b96fb9416b.png)





在红黑树当中，我们通过红色结点和黑色结点作为辅助，来判断一颗二叉树是否相对平衡。



![img](https://oscimg.oschina.net/oscnet/a5a89c8538a2e62fc4871cf8faf53c00db0.png)



而在AVL树当中，我们通过“平衡因子”来判断一颗二叉树是否符合高度平衡。



到底什么是AVL树的平衡因子呢？



对于AVL树的每一个结点，平衡因子是它的**左子树高度和右子树高度的差值**。只有当二叉树所有结点的平衡因子都是-1, 0, 1这三个值的时候，这颗二叉树才是一颗合格的AVL树。



举个例子，下图就是一颗典型的AVL树，每个节点旁边都标注了平衡因子：



![img](https://oscimg.oschina.net/oscnet/44f6801565b987d5431950b492f01276bbe.png)



其中结点4的左子树高度是1，右子树不存在，所以该结点的平衡因子是1-0=1。



结点7的左子树不存在，右子树高度是1，所以平衡因子是0-1=-1。



所有的叶子结点，不存在左右子树，所以平衡因子都是0。



![img](https://oscimg.oschina.net/oscnet/e06187d02a5de2b3ba59de0ca37e09524c0.png)

![img](https://oscimg.oschina.net/oscnet/b5cd20c44fb586a1a410c1879ba8c4e1eb1.png)



![img](https://oscimg.oschina.net/oscnet/e18fe64f339ac5eb7b4c505a901a9a780e8.png)



上图原本是一个平衡的AVL树，当插入了新结点1时，父结点2的平衡因子变成了1，祖父结点4的平衡因子变成了2。



此时，结点4的左右子树高度差超过了1，打破了AVL树的平衡。





那么，怎样才能重新恢复AVL的平衡呢？



之前讲解红黑树的时候，我们提到红黑树包括左旋转、右旋转、变色这三种操作。



而AVL树不存在变色的问题，只有**左旋转**、**右旋转**这两种操作。



**左旋转：**



**逆时针**旋转AVL树的两个结点X和Y，使得父结点被自己的右孩子取代，而自己成为自己的左孩子。说起来有些绕，见下图（标号1,2,3的三角形，是结点X和Y的子树）：



![img](https://oscimg.oschina.net/oscnet/0d320b490a766391e22699ff5939d23ea5b.png)

图中，身为右孩子的Y取代了X的位置，而X变成了自己的左孩子。此为左旋转。





**右旋转：**



**顺时针**旋转AVL树的两个结点X和Y，使得父结点被自己的左孩子取代，而自己成为自己的右孩子。见下图：



![img](https://oscimg.oschina.net/oscnet/be65041d1f7a9cf2ac5cc15d54674369f79.png)

图中，身为左孩子的Y取代了X的位置，而X变成了自己的右孩子。此为右旋转。

![img](https://oscimg.oschina.net/oscnet/590a6d521d4900a5976387a63a3b5421390.png)

![img](https://oscimg.oschina.net/oscnet/89c83e696c31b555014f549949599c271aa.png)





**1. 左左局面（LL）**



![img](https://oscimg.oschina.net/oscnet/2b0b63e6bdef40fa38a604aa0c8ef1eaf03.png)



顾名思义，祖父结点A有一个左孩子结点B，而结点B又有一个左孩子结点C。标号1,2,3,4的三角形是各个结点的子树。



在这种局面下，我们以结点A为轴，进行**右旋**操作：



![img](https://oscimg.oschina.net/oscnet/fdf53e8a4ad71a9611adf5fb9659712e569.png)



**2. 右右局面（RR）**



![img](https://oscimg.oschina.net/oscnet/5a10857a0f2a62a5b790d2b8cb3716c603e.png)





祖父结点A有一个右孩子结点B，而结点B又有一个右孩子结点C。



在这种局面下，我们以结点A为轴，进行**左旋**操作：





![img](https://oscimg.oschina.net/oscnet/072e4765c8f4dfb27a6b3eb90d392b58c4d.png)

**
**

**3****. 左右局面（LR）**

**
**

![img](https://oscimg.oschina.net/oscnet/bbedd401e42a8fb8628868b318c3547819d.png)





祖父结点A有一个左孩子结点B，而结点B又有一个右孩子结点C。



在这种局面下，我们先以结点B为轴，进行**左旋**操作：





![img](https://oscimg.oschina.net/oscnet/4cd5065ec74ccf43fa0b1e6c4bd3ee62e57.png)



这样就转化成了左左局面。我们继续以结点A为轴，进行右旋操作：



![img](https://oscimg.oschina.net/oscnet/96d8d2096bf0b620198dc4f99f9057f555a.png)

**
**

**4. 右左局面（RL）**

**
**

![img](https://oscimg.oschina.net/oscnet/0e1c130390ebfb7672c954150c137e81caf.png)





祖父结点A有一个右孩子结点B，而结点B又有一个左孩子结点C。



在这种局面下，我们先以结点B为轴，进行**右旋**操作：



![img](https://oscimg.oschina.net/oscnet/ed2f7bc4166799c43755d9cfe52010d7b3d.png)



这样就转化成了右右局面。我们继续以结点A为轴，进行左旋操作：



![img](https://oscimg.oschina.net/oscnet/00bf3702677c17db6365c1d8b3a8521df42.png)

![img](https://oscimg.oschina.net/oscnet/73ffe5af94435748744aa59c921b9c60eb4.png)

![img](https://oscimg.oschina.net/oscnet/1ad30e2e5c7447b921a6581154ef90c2aaa.png)



例子中，以结点4为根的子树出现了不平衡的情况。



不难看出，这个子树正好符合 “左左局面”。



于是，我们以结点4为轴，进行右旋操作：



![img](https://oscimg.oschina.net/oscnet/a406fd0ee24c8965f58ec3c9a2aaaa945d1.png)



这样一来，这颗AVL树重新恢复了高度平衡。



![img](https://oscimg.oschina.net/oscnet/3f02886ba95f615778cefdbad09796532be.png)



![img](https://oscimg.oschina.net/oscnet/9dc6c00126ad647a28137575bafa91dc77b.png)



![img](https://oscimg.oschina.net/oscnet/8039b703f4ff2068d6a7f1ac870a796dc32.png)



如上图所示，在AVL树中删除了结点1，导致父节点2的平衡因子变为-2，打破了平衡。



此时，以结点2为根的子树正好形成了“右左局面”，于是我们首先以结点4为轴进行右旋：



![img](https://oscimg.oschina.net/oscnet/c5dc83aeb5a6009da5c1e072fdd92043dd9.png)



然后以结点2为轴进行左旋：



![img](https://oscimg.oschina.net/oscnet/5d60d8bb1315ea8d6db52605c621a4fadd0.png)



如此一来，AVL树重新恢复了高度平衡。

![img](https://oscimg.oschina.net/oscnet/b62fcbac2d6a8ad746819bbd98d02a45343.png)



![img](https://oscimg.oschina.net/oscnet/2b8911ec866203f331e96306efb66b1f689.png)