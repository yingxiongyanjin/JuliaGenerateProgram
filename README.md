# JuliaGenerateProgram
用于生成Julia集的简单项目，但是最终的结果是很美、很令人兴奋的。  
## 简单
1. **原理容易实现**   
通过下式反复迭代判断该复平面点是否发散即可生成Julia集：
$$
f_c(Z) = z^2 + c
$$
2. **程序结构清晰**  
通过调整以下参数就可以完全控制程序的走向：
```C
const int DIM = 3000;                 // 二维数组的大小
int *bitmap;                           // 存储位图数据,采用灰度图存储结果

const float scale = 1.5;               // 控制x,y的值域，
                                       //具体的说先通过 f(x) = 1 - 2x/DIM 将值映射到[-1,1],再通过该因子进行放缩

cuComplex c(-0.8, 0.156);              // 迭代式中的常量，通过改变它可以获得不同的Julia集图案
const int step = 200;                  // 控制迭代次数
const float inf = 1000;                // 判断点是否发散的设置的无穷大值
```
## 美与令人兴奋的结果
本文只提供了python的可视化代码,也可以查看直接运行visual.ipynb文件。
```python
import numpy as np
import matplotlib.pyplot as plt

# 读入数据
data = np.loadtxt('test.txt')

# 显示灰度图
plt.imshow(data, cmap='gray')
plt.show()
```
- 结果1  
参数列表如下：
```C
const int DIM = 1000;
const float scale = 1.5;
cuComplex c(-0.8, 0.156);
const int step = 200; 
const float inf = 1000; 
```
![result1](./img/Julia%E9%9B%86.png)