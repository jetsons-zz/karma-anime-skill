#!/bin/bash
# Karma Anime - 创建 Veo 视频生成任务
# 用法: bash create_task.sh "prompt" duration character_file
# 输出: VIDEO_ID=xxx (供后续脚本使用)
#
# 参数:
#   prompt         - 场景动作描述（不含角色描述）
#   duration       - 视频时长 (4/6/8)
#   character_file - 角色描述文件路径

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

PROMPT="${1:-}"
DURATION="${2:-4}"
CHARACTER_FILE="${3:-}"

# 检查必需参数
if [[ -z "${PROMPT}" ]]; then
    echo "[ERROR] 请提供 prompt 参数" >&2
    echo "用法: bash $0 \"prompt\" duration character_file" >&2
    exit 1
fi

if [[ -z "${CHARACTER_FILE}" ]]; then
    echo "[ERROR] 请提供角色描述文件路径" >&2
    exit 1
fi

# 验证时长参数（Veo 3.1 仅支持 4/6/8 秒）
if [[ "${DURATION}" != "4" && "${DURATION}" != "6" && "${DURATION}" != "8" ]]; then
    echo "[ERROR] 时长必须是 4, 6, 或 8 秒" >&2
    exit 1
fi

# 读取角色描述文件
if [[ ! -f "${CHARACTER_FILE}" ]]; then
    echo "[ERROR] 角色描述文件不存在: ${CHARACTER_FILE}" >&2
    exit 1
fi
CHARACTER_DESC=$(cat "${CHARACTER_FILE}")
if [[ -z "${CHARACTER_DESC}" ]]; then
    echo "[ERROR] 角色描述文件为空: ${CHARACTER_FILE}" >&2
    exit 1
fi

# 将角色描述插入到提示词开头
FULL_PROMPT="${CHARACTER_DESC}, ${PROMPT}"
echo "[INFO] 已加载角色描述: ${CHARACTER_FILE}"
echo "[INFO] 创建视频任务: prompt=${FULL_PROMPT:0:80}..., duration=${DURATION}s"

# 使用 jq 安全构建 JSON
JSON_BODY=$(jq -nc \
    --arg model "google/veo-3.1-generate-preview" \
    --arg prompt "${FULL_PROMPT}" \
    --arg seconds "${DURATION}" \
    '{model: $model, prompt: $prompt, seconds: $seconds}')

RESPONSE=$(curl -s ${CURL_OPTS} -X POST "${API_BASE}/videos" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "${JSON_BODY}")

# 安全解析 JSON 响应
if ! VIDEO_ID=$(echo "${RESPONSE}" | jq -re '.id' 2>/dev/null); then
    echo "[ERROR] 创建任务失败，无法解析响应" >&2
    echo "${RESPONSE}" | jq . 2>/dev/null || echo "${RESPONSE}" >&2
    exit 1
fi

echo "[SUCCESS] 任务已创建"
echo "VIDEO_ID=${VIDEO_ID}"
