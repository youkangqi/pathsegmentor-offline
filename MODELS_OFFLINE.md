# PathSegmentor：CLIP 与 BiomedBERT 离线补充包

本包提供当前 PathSegmentor 默认推理流程需要的 CLIP 分词器和 BiomedBERT 模型。
适用于已经构建好 PathSegmentor 环境、服务器无法访问 Hugging Face 的情况。

## 下载

Release：https://github.com/youkangqi/pathsegmentor-offline/releases/tag/v2026.10.30-models

下载以下两个附件，并上传到服务器：
- pathsegmentor-models-offline-20261030.tar.gz
- pathsegmentor-models-offline-20261030.tar.gz.sha256

若服务器可以访问 GitHub，也可以直接执行：

```bash
base='https://github.com/youkangqi/pathsegmentor-offline/releases/download/v2026.10.30-models'
archive='pathsegmentor-models-offline-20261030.tar.gz'
curl -fL --retry 5 -C - "$base/$archive" -o "$archive"
curl -fL --retry 5 "$base/$archive.sha256" -o "$archive.sha256"
sha256sum -c "$archive.sha256" &&
tar -xzf "$archive" &&
(cd pathsegmentor-models-offline-20261030 && sha256sum -c SHA256SUMS)
```

完整包和内部文件均有 SHA256 校验。下载记录和固定的官方提交号见 MANIFEST.json。

## 包含文件

```text
pretrained/
├── clip-vit-base-patch32/
│   ├── vocab.json
│   ├── merges.txt
│   ├── tokenizer_config.json
│   └── special_tokens_map.json
└── biomedbert/
    ├── config.json
    └── pytorch_model.bin
```

CLIP 这里只用于分词。BiomedBERT 的 pytorch_model.bin 为 440,474,434 字节。
包内附带原始许可证、来源及逐文件校验记录。

本包为两项模型依赖的补充包。PathSegmentor 自身的 checkpoints/model_state_dict.pt
和 NLTK 数据请按 PathSegmentor 原说明准备。

## 放入服务器上的 PathSegmentor 仓库

将解压目录中的 pretrained 文件夹复制到 PathSegmentor 仓库根目录。
最终应得到：

```text
PathSegmentor/pretrained/clip-vit-base-patch32/vocab.json
PathSegmentor/pretrained/clip-vit-base-patch32/merges.txt
PathSegmentor/pretrained/clip-vit-base-patch32/tokenizer_config.json
PathSegmentor/pretrained/clip-vit-base-patch32/special_tokens_map.json
PathSegmentor/pretrained/biomedbert/config.json
PathSegmentor/pretrained/biomedbert/pytorch_model.bin
```

后续命令均在服务器的 PathSegmentor 仓库根目录运行。

## 修改加载路径

### 1. CLIP tokenizer

在 configs/pathsegmentor_inference.yaml 的现有 MODEL.TEXT 下添加以下配置：
保留该节点的其他已有字段，只增加 PRETRAINED_TOKENIZER。

```yaml
MODEL:
  TEXT:
    PRETRAINED_TOKENIZER: './pretrained/clip-vit-base-patch32'
```

上面展示的是字段位置，完整配置仍需保留原有的 ARCH、NAME、TOKENIZER 等字段。
如果用于 scripts/train.sh 或 scripts/eval.sh，也在 configs/pathsegmentor.yaml
的 MODEL.TEXT 下添加同样的字段。

### 2. BiomedBERT

在 modeling/language/vlpencoder.py 中，找到：

```python
self.biomed_encoder = AutoModel.from_pretrained("microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext")
```

替换为：

```python
self.biomed_encoder = AutoModel.from_pretrained(
    "./pretrained/biomedbert",
    local_files_only=True,
)
```

相对路径从程序启动时的工作目录解析，因此需要从 PathSegmentor 仓库根目录启动。
如果此前已经修改为其他本地目录，保持与文件实际位置一致即可。

## 离线加载验证

激活服务器上的 pathsegmentor 环境后，在仓库根目录运行：

```bash
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1

python -u - <<'PY'
from transformers import CLIPTokenizer, AutoModel

tokenizer = CLIPTokenizer.from_pretrained(
    "./pretrained/clip-vit-base-patch32", local_files_only=True
)
print("CLIP tokenizer: OK", flush=True)
print(tokenizer("tissue-level gland in colon pathology")["input_ids"])

model = AutoModel.from_pretrained(
    "./pretrained/biomedbert", local_files_only=True
)
print("BiomedBERT: OK", flush=True)
print("两项模型依赖均可离线加载")
PY
```

这项检查在 CPU 上加载 BiomedBERT，不需要 GPU。它只检查这两项依赖，
完整 PathSegmentor 推理请继续运行 inference_examples.ipynb。

如果此前使用 Jupyter，需要重启内核以应用修改；离线环境变量须在导入 transformers
之前设置，可以在启动 Jupyter 的终端中设置，也可以放在 notebook 最前面。

## 来源与固定版本

- CLIP tokenizer：
  https://huggingface.co/openai/clip-vit-base-patch32
  提交：3d74acf9a28c67741b2f4f2ea7635f0aaf6f0268
- BiomedBERT：
  https://huggingface.co/microsoft/BiomedNLP-BiomedBERT-base-uncased-abstract-fulltext
  提交：e1354b7a3a09615f6aba48dfad4b7a613eef7062
- PathSegmentor：
  https://github.com/zhi-xuan-chen/PathSegmentor
- Transformers 离线加载说明：
  https://huggingface.co/docs/transformers/v4.34.1/installation#offline-mode

小文件已对照官方 Git blob SHA1 校验；BiomedBERT 权重已对照官方 LFS SHA256 校验。
SHA256SUMS 另提供本包所有内容文件的 SHA256。
运行依赖检查需使用 PathSegmentor 所要求的 PyTorch/Transformers 环境。
