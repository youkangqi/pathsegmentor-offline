# PathSegmentor 离线环境（Linux x86_64）

这里发布可以从 GitHub 下载、随后离线安装的完整 Conda 环境包。
158 个依赖包，完整 tar 为 2,816,757,760 字节。二进制分卷位于
[Release v2026.10.29](https://github.com/youkangqi/pathsegmentor-offline/releases/tag/v2026.10.29)。
`git clone` 只获取仓库中的说明和脚本，不会获取 Release 附件。

## 服务器下载并安装

在 Linux x86_64 服务器执行：

```bash
curl -fL --retry 5 \
  https://github.com/youkangqi/pathsegmentor-offline/releases/download/v2026.10.29/download_and_install.sh \
  -o download_and_install.sh
bash download_and_install.sh
```

脚本依次下载三个分卷，检查每个分卷的 SHA256，合并并检查完整 tar，解压后离线安装。
支持断点续传；已校验的文件会复用。服务器需能访问 GitHub 及其 Release 附件下载地址。
如果只有 wget，可用 `wget -O download_and_install.sh URL` 下载上面的脚本；脚本会自动使用 wget。

默认环境路径：`/home/ma-user/work/y50063382/envs/pathsegmentor`。
默认下载目录：当前目录下的 `pathsegmentor-download-20261029`。
目标环境若已存在，脚本会停止，不会覆盖。

自定义环境和下载路径：

```bash
bash download_and_install.sh /your/absolute/path/pathsegmentor /your/download/directory
```

## 手动下载、校验和安装

```bash
mkdir -p pathsegmentor-download-20261029
cd pathsegmentor-download-20261029
base='https://github.com/youkangqi/pathsegmentor-offline/releases/download/v2026.10.29'
archive='pathsegmentor-offline-linux-64-20261029.tar'
for suffix in part01 part02 part03; do
  curl -fL --retry 5 -C - "$base/$archive.$suffix" -o "$archive.$suffix"
done
curl -fL --retry 5 "$base/SHA256SUMS.parts" -o SHA256SUMS.parts
curl -fL --retry 5 "$base/$archive.sha256" -o "$archive.sha256"
sha256sum -c SHA256SUMS.parts && \
cat "$archive.part01" "$archive.part02" "$archive.part03" > "$archive" && \
sha256sum -c "$archive.sha256" && \
tar -xf "$archive" && \
bash pathsegmentor-offline-linux-64-20261029/install_offline.sh
```

三个分卷大小：1,000,000,000、1,000,000,000、816,757,760 字节。
完整 tar 的 SHA256：

```text
52f3b5d2466e1bb66bb6e615c78fadaba9e004885e23c7e806d939aae32813fe
```

## 环境版本

| 软件 | 版本 |
| --- | --- |
| Python | 3.11.18 |
| pip | 26.2.2 |
| setuptools | 72.1.0 |
| NumPy | 1.26.4 |
| PyTorch | 2.1.0，CUDA 12.1 构建 |
| torchvision | 0.16.0，cu121 构建 |
| pytorch-cuda | 12.1 |
| mpi4py | 4.0.0 |
| OpenMPI | 5.0.5 |
| ninja | 1.13.2 |

完整来源、构建号和依赖记录在离线包内的 `packages.tsv`、`manifest.json` 和 `environment.resolved.yml`。
额外约束 `mkl < 2024.1`（最终 2023.2.0），避免旧 PyTorch 的 `iJIT_NotifyEvent` 导入错误；
CUDA 附属库也锁定到 12.1 对应版本。

## 运行条件与验证

- Linux x86_64，glibc >= 2.17；建议预留约 25 GB 用于分卷、合并文件、解压目录、环境和缓存。
- 安装包附带 micromamba 2.10.0，无需预先安装 Conda 或 Python。
- GPU 运算需要服务器已有兼容 NVIDIA 驱动，并为当前作业分配 GPU。
- 原始清单不包含 NVIDIA 驱动或 nvcc；编译 CUDA 扩展可能需要额外工具链。
- 安装后自动验证版本、NumPy/PyTorch 运算、torchvision NMS、MPI 初始化和 ninja。
  可访问 GPU 时，还会验证 CUDA 运算。
- 在 macOS 上完成依赖求解、下载校验、安装脚本语法和离线安装预检查；实际 Linux/GPU/MPI
  运行由服务器安装后的验证脚本完成。多节点 MPI 通信不在基本验证范围内。

安装后若已有 Conda，可运行：

```bash
conda activate /home/ma-user/work/y50063382/envs/pathsegmentor
```

包内另有 `README_中文.txt`。第三方软件包保留各自许可证；此仓库不为这些依赖重新授予许可证。

参考：[PyTorch 历史版本](https://docs.pytorch.org/get-started/previous-versions/)、
[MKL 兼容问题](https://github.com/pytorch/pytorch/issues/123097)、
[CUDA 12.1 驱动兼容说明](https://docs.nvidia.com/cuda/archive/12.1.0/cuda-toolkit-release-notes/index.html)。
