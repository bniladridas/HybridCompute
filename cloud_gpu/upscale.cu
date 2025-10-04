#include <opencv2/opencv.hpp>
#include <iostream>
#include <cuda_runtime.h>

__device__ float cubicInterpolate(float p0, float p1, float p2, float p3, float t) {
    return p1 + 0.5f * t * (p2 - p0 + t * (2.0f * p0 - 5.0f * p1 + 4.0f * p2 - p3 + t * (3.0f * (p1 - p2) + p3 - p0)));
}

__global__ void bicubicUpscaleKernel(uchar* input, uchar* output, int in_w, int in_h, int scale) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= in_w || y >= in_h) return;

    for (int c = 0; c < 3; c++) {
        for (int i = 0; i < scale; i++) {
            for (int j = 0; j < scale; j++) {
                float gx = (float)x + (float)i / (float)scale;
                float gy = (float)y + (float)j / (float)scale;

                int gxi = (int)gx;
                int gyi = (int)gy;

                float vals[4][4];
                for (int m = -1; m <= 2; m++) {
                    for (int n = -1; n <= 2; n++) {
                        int px = min(max(gxi + m, 0), in_w - 1);
                        int py = min(max(gyi + n, 0), in_h - 1);
                        vals[m + 1][n + 1] = input[(py * in_w + px) * 3 + c];
                    }
                }

                float col[4];
                for (int m = 0; m < 4; m++) {
                    col[m] = cubicInterpolate(vals[m][0], vals[m][1], vals[m][2], vals[m][3], gx - gxi);
                }

                float value = cubicInterpolate(col[0], col[1], col[2], col[3], gy - gyi);
                int out_idx = ((y * scale + j) * (in_w * scale) + (x * scale + i)) * 3 + c;
                output[out_idx] = min(max((int)value, 0), 255);
            }
        }
    }
}

#define CUDA_CHECK(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            std::cerr << "CUDA error in " << __FILE__ << " at line " << __LINE__ << ": " << cudaGetErrorString(err) << std::endl; \
            return -1; \
        } \
    } while (0)

int main() {
    cv::Mat input = cv::imread("input_tile.jpg");
    if (input.empty()) {
        std::cerr << "Error: Could not load image!" << std::endl;
        return -1;
    }

    int in_w = input.cols;
    int in_h = input.rows;
    int scale = 2;
    int out_w = in_w * scale;
    int out_h = in_h * scale;

    cv::Mat output(out_h, out_w, CV_8UC3);

    uchar *d_input, *d_output;
    size_t input_size = in_w * in_h * 3 * sizeof(uchar);
    size_t output_size = out_w * out_h * 3 * sizeof(uchar);

    CUDA_CHECK(cudaMalloc(&d_input, input_size));
    CUDA_CHECK(cudaMalloc(&d_output, output_size));

    CUDA_CHECK(cudaMemcpy(d_input, input.data, input_size, cudaMemcpyHostToDevice));

    dim3 blockDim(16, 16);
    dim3 gridDim((in_w + blockDim.x - 1) / blockDim.x, (in_h + blockDim.y - 1) / blockDim.y);
    bicubicUpscaleKernel<<<gridDim, blockDim>>>(d_input, d_output, in_w, in_h, scale);

    CUDA_CHECK(cudaMemcpy(output.data, d_output, output_size, cudaMemcpyDeviceToHost));

    CUDA_CHECK(cudaFree(d_input));
    CUDA_CHECK(cudaFree(d_output));

    cv::imwrite("output_tile.jpg", output);

    return 0;
}
