#!/usr/bin/env bash
set -euo pipefail
BASE_URL='https://github.com/youkangqi/pathsegmentor-offline/releases/download/v2026.10.29'
ARCHIVE='pathsegmentor-offline-linux-64-20261029.tar'
BUNDLE='pathsegmentor-offline-linux-64-20261029'
ARCHIVE_SHA='52f3b5d2466e1bb66bb6e615c78fadaba9e004885e23c7e806d939aae32813fe'
TARGET_PREFIX="${1:-/home/ma-user/work/y50063382/envs/pathsegmentor}"
DOWNLOAD_DIR="${2:-$PWD/pathsegmentor-download-20261029}"
if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo '此安装包只适用于 Linux x86_64。' >&2; exit 1
fi
if [[ "$TARGET_PREFIX" != /* || "$TARGET_PREFIX" == / || -e "$TARGET_PREFIX" ]]; then
  echo '目标环境必须为尚不存在的绝对路径；不会覆盖已有环境。' >&2; exit 1
fi
for cmd in sha256sum tar; do
  command -v "$cmd" >/dev/null || { echo "缺少命令：$cmd" >&2; exit 1; }
done
if ! command -v curl >/dev/null && ! command -v wget >/dev/null; then
  echo '需要 curl 或 wget 下载文件。' >&2; exit 1
fi
mkdir -p -- "$DOWNLOAD_DIR"
cd -- "$DOWNLOAD_DIR"
check_file() {
  local file="$1" expected="$2"
  [[ -f "$file" ]] && [[ "$(sha256sum -- "$file" | awk '{print $1}')" == "$expected" ]]
}
fetch_part() {
  local file="$1" expected="$2"
  if check_file "$file" "$expected"; then
    printf '已有且校验通过：%s\n' "$file"; return
  fi
  if check_file "$file.download" "$expected"; then
    mv -- "$file.download" "$file"; return
  fi
  printf '下载（支持断点续传）：%s\n' "$file"
  if command -v curl >/dev/null; then
    curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 30 \
      --continue-at - --output "$file.download" "$BASE_URL/$file"
  else
    wget --continue --tries=5 --timeout=30 --output-document="$file.download" "$BASE_URL/$file"
  fi
  if ! check_file "$file.download" "$expected"; then
    echo "校验失败：$file.download，请删除该 .download 文件后重试。" >&2; exit 1
  fi
  mv -- "$file.download" "$file"
}
if ! check_file "$ARCHIVE" "$ARCHIVE_SHA"; then
  fetch_part "$ARCHIVE.part01" 'f9949c48fa971b8c97be623acd755c3a2ed767452f946698acd9e3164b77c992'
  fetch_part "$ARCHIVE.part02" '74198e6546c572b70ff6e11365391300adef8457db34e5826a2571f477854cf9'
  fetch_part "$ARCHIVE.part03" '50b79e9c72f12d52572cac5996a0bd718d79d76a2ae7c1f5642d3bc6a44a066f'
  cat -- "$ARCHIVE.part01" "$ARCHIVE.part02" "$ARCHIVE.part03" > "$ARCHIVE.assembling"
  check_file "$ARCHIVE.assembling" "$ARCHIVE_SHA" || { echo '完整 tar 校验失败' >&2; exit 1; }
  mv -- "$ARCHIVE.assembling" "$ARCHIVE"
fi
if [[ ! -e "$BUNDLE" ]]; then
  tar -xf "$ARCHIVE"
fi
(cd -- "$BUNDLE" && sha256sum --check --quiet SHA256SUMS)
bash "$BUNDLE/install_offline.sh" "$TARGET_PREFIX"
