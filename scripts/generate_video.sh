#!/bin/bash
# Karma Anime - Veo 3 视频生成脚本
# 使用: bash generate_video.sh "prompt" duration output_file
#
# 环境变量 (可选):
#   VEO_API_BASE     - API 地址，默认 https://llm.tokencloud.ai
#   VEO_MAX_ATTEMPTS - 最大轮询次数，默认 60 (约10分钟)
#   VEO_POLL_INTERVAL- 轮询间隔秒数，默认 10

set -euo pipefail

# 配置 (测试阶段使用固定值，正式环境请改为环境变量)
API_KEY="sk-RPo8Q8Lf9_SKoNMSjo5DNA"
API_BASE="${VEO_API_BASE:-https://llm.tokencloud.ai}"
MAX_ATTEMPTS="${VEO_MAX_ATTEMPTS:-60}"
POLL_INTERVAL="${VEO_POLL_INTERVAL:-10}"

# 解析参数
PROMPT="${1:-}"
DURATION="${2:-4}"
OUTPUT="${3:-output.mp4}"

# 检查必需参数
if [[ -z "${PROMPT}" ]]; then
    echo "[ERROR] 请提供 prompt 参数" >&2
    echo "使用: VEO_API_KEY=xxx bash $0 \"prompt\" [duration] [output_file]" >&2
    exit 1
fi

# 验证时长参数
if [[ "${DURATION}" != "4" && "${DURATION}" != "6" && "${DURATION}" != "8" ]]; then
    echo "[ERROR] 时长必须是 4, 6, 或 8 秒" >&2
    exit 1
fi

echo "[INFO] 创建视频任务: prompt=${PROMPT:0:50}..., duration=${DURATION}s"

# 使用 jq 安全构建 JSON，避免 shell injection
JSON_BODY=$(jq -nc \
    --arg model "google/veo-3.1-generate-preview" \
    --arg prompt "${PROMPT}" \
    --arg seconds "${DURATION}" \
    '{model: $model, prompt: $prompt, seconds: $seconds}')

RESPONSE=$(curl -s -X POST "${API_BASE}/videos" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "${JSON_BODY}")

# 安全解析 JSON 响应
if ! VIDEO_ID=$(echo "${RESPONSE}" | jq -re '.id' 2>/dev/null); then
    echo "[ERROR] 创建任务失败，无法解析响应" >&2
    echo "${RESPONSE}" | jq . 2>/dev/null || echo "${RESPONSE}" >&2
    exit 1
fi

echo "[INFO] 任务已创建: ${VIDEO_ID:0:50}..."

# 轮询检查状态
echo "[INFO] 等待生成完成 (最多 $((MAX_ATTEMPTS * POLL_INTERVAL)) 秒)..."
ATTEMPT=0
while [[ ${ATTEMPT} -lt ${MAX_ATTEMPTS} ]]; do
    POLL_RESPONSE=$(curl -s "${API_BASE}/v1/videos/${VIDEO_ID}" \
        -H "x-litellm-api-key: ${API_KEY}")

    if ! STATUS=$(echo "${POLL_RESPONSE}" | jq -re '.status' 2>/dev/null); then
        echo "[WARN] 无法解析状态响应，继续重试..." >&2
        sleep "${POLL_INTERVAL}"
        ATTEMPT=$((ATTEMPT + 1))
        continue
    fi

    if [[ "${STATUS}" == "completed" ]]; then
        echo "[SUCCESS] 视频生成完成!"
        break
    elif [[ "${STATUS}" == "failed" ]]; then
        echo "[ERROR] 视频生成失败" >&2
        echo "${POLL_RESPONSE}" | jq . 2>/dev/null || echo "${POLL_RESPONSE}" >&2
        exit 1
    fi

    echo "[INFO] 状态: ${STATUS} ($((ATTEMPT + 1))/${MAX_ATTEMPTS})"
    sleep "${POLL_INTERVAL}"
    ATTEMPT=$((ATTEMPT + 1))
done

if [[ ${ATTEMPT} -ge ${MAX_ATTEMPTS} ]]; then
    echo "[ERROR] 视频生成超时 (已等待 $((MAX_ATTEMPTS * POLL_INTERVAL)) 秒)" >&2
    exit 1
fi

# 下载视频
echo "[INFO] 下载视频..."
if ! curl -sf "${API_BASE}/v1/videos/${VIDEO_ID}/content" \
    -H "x-litellm-api-key: ${API_KEY}" \
    -o "${OUTPUT}"; then
    echo "[ERROR] 视频下载失败" >&2
    exit 1
fi

SIZE=$(ls -lh "${OUTPUT}" | awk '{print $5}')
echo "[SUCCESS] 视频已保存: ${OUTPUT} (${SIZE})"
