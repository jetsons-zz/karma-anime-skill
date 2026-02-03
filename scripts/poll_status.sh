#!/bin/bash
# Karma Anime - 查询视频生成状态
# 用法: bash poll_status.sh video_id
# 输出: STATUS=processing|completed|failed
#
# 返回码:
#   0 - 查询成功（不代表视频完成，需检查 STATUS）
#   1 - 查询失败

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

VIDEO_ID="${1:-}"

if [[ -z "${VIDEO_ID}" ]]; then
    echo "[ERROR] 请提供 video_id 参数" >&2
    echo "用法: bash $0 video_id" >&2
    exit 1
fi

RESPONSE=$(curl -s ${CURL_OPTS} "${API_BASE}/v1/videos/${VIDEO_ID}" \
    -H "x-litellm-api-key: ${API_KEY}")

if ! STATUS=$(echo "${RESPONSE}" | jq -re '.status' 2>/dev/null); then
    echo "[WARN] 无法解析状态响应" >&2
    echo "${RESPONSE}" | jq . 2>/dev/null || echo "${RESPONSE}" >&2
    echo "STATUS=unknown"
    exit 1
fi

if [[ "${STATUS}" == "failed" ]]; then
    echo "[ERROR] 视频生成失败" >&2
    echo "${RESPONSE}" | jq . 2>/dev/null || echo "${RESPONSE}" >&2
fi

echo "STATUS=${STATUS}"
