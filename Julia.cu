#include <stdio.h>
#include <math.h>
#include <time.h>

// 复数
struct cuComplex
{
    /* data */
    float r;
    float i;

    // 初始化方法
    __device__ cuComplex(float a, float b):r(a),i(b) {}

    // 计算复数的模
    __device__ float magnitude2(void) {return r*r + i*i;}

    // 规定复数的乘法和加法
    __device__ cuComplex operator*(const cuComplex &a){
        return cuComplex(r*a.r - i*a.i, i*a.r + r*a.i);
    }
    __device__ cuComplex operator+(const cuComplex &a){
        return cuComplex(r+a.r, i+a.i);
    }
};

__device__
int julia
(
    int x, int y,
    int DIM,
    float scale, int step, float inf
){
    // 首先通过缩放、平移将x和y的值控制在[-scale,scale]之间
    // 生成复数平面上的一个点
    float jx = scale * (float)(DIM/2 - x)/(DIM/2);
    float jy = scale * (float)(DIM/2 - y)/(DIM/2);

    cuComplex c(-0.8,0.156);               // 迭代式中的常量，通过改变它可以获得不同的Julia集图案
    cuComplex a(jx, jy);

    // 进行迭代，判断点集是否发散
    for(int i=0; i<step; i++){
        a = a*a + c;
        if(a.magnitude2() > inf)
            return 0;
    }

    return 1;
}

__global__
void kernel( 
    int *bitmap,
    int DIM,
    float scale, int step, float inf
)
{
    for(int y = 0; y < DIM; y++){
        for(int x = 0; x < DIM; x++){

            // 判断是否为Julia集中的点
            int juliaValue = julia(x, y, DIM, scale,step,inf);

            // 如果是Julia集中的点，将其标记为白色
            // 如果不是Julia集中的点，则将其标记为红色
            int offset = x + y * DIM;
            bitmap[offset] = 255 * juliaValue;
        }
    }
}

void checkOut(
    int &sum,
    int *bitmap,int DIM
)
{
    sum = 0;
    for (int i = 0; i < DIM; i++) {
        for (int j = 0; j < DIM; j++) {
            if(bitmap[i*DIM+j] != 0 ){
                sum++;
            }
        }
    }
}

int main( void ){

    clock_t start, end;
    double cpu_time_used;
    start = clock(); // 记录开始时间

    // 本程序的控制参数列表
    const int DIM = 10000;                 // 二维数组的大小
    int *bitmap;                           // 存储位图数据,采用灰度图存储结果

    const float scale = 1.5;               // 控制x,y的值域，具体的说先通过 f(x) = 1 - 2x/DIM 将值映射到[-1,1],再通过该因子进行放缩
    const int step = 200;                  // 控制迭代次数
    const float inf = 1000;                // 判断点是否发散的设置的无穷大值
    
    // 动态分配空间
    int n = DIM * DIM;
    const int size = n*sizeof(int);

    // CUDA内存管理办法
    cudaMallocManaged(&bitmap, size);

    // 获取设备信息
    int deviceId;
    int numberOfSMs;

    cudaGetDevice(&deviceId);
    cudaDeviceGetAttribute(&numberOfSMs, cudaDevAttrMultiProcessorCount, deviceId);

    // 核心代码
    size_t threadsPerBlock;
    size_t numberOfBlocks;

    threadsPerBlock = 256;
    numberOfBlocks = 32 * numberOfSMs;

    kernel<<<numberOfBlocks,threadsPerBlock>>>(bitmap,DIM,scale,step,inf);

    cudaError_t Err;
    cudaError_t asyncErr;

    Err = cudaGetLastError();
    if(Err != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(Err));

    // 阻断，并进行同步
    asyncErr = cudaDeviceSynchronize();
    if(asyncErr != cudaSuccess) printf("Error: %s\n", cudaGetErrorString(asyncErr));

    // 预取回主机
    cudaMemPrefetchAsync(bitmap, size, cudaCpuDeviceId);

    int sum = 0;
    checkOut(sum,bitmap,DIM);

    // 释放内存
    cudaFree(bitmap);

    printf("done! %d\n",sum);

    end = clock(); // 记录结束时间
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
    printf("程序运行时间为 %f 秒\n", cpu_time_used);

    // 程序结束
    return 0;
}