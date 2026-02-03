#!/bin/bash
# Karma Anime - 下载已完成的视频
# 用法: bash download_video.sh video_id output_file
# 输出: 下载的视频文件
#
# 参数:
#   video_id    - 视频任务ID
#   output_file - 输出文件路径

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

VIDEO_ID="${1:-}"
OUTPUT="${2:-output.mp4}"

if [[ -z "${VIDEO_ID}" ]]; then
    echo "[ERROR] 请提供 video_id 参数" >&2
    echo "用法: bash $0 video_id output_file" >&2
    exit 1
fi

mkdir -p "$(dirname "${OUTPUT}")"

echo "[INFO] 下载视频到 ${OUTPUT}（超时 300 秒）..."
if ! curl -sf ${CURL_DOWNLOAD_OPTS} "${API_BASE}/v1/videos/${VIDEO_ID}/content" \
    -H "x-litellm-api-key: ${API_KEY}" \
    -o "${OUTPUT}"; then
    echo "[ERROR] 视频下载失败" >&2
    exit 1
fi

SIZE=$(ls -lh "${OUTPUT}" | awk '{print $5}')
echo "[SUCCESS] 视频已保存: ${OUTPUT} (${SIZE})"
