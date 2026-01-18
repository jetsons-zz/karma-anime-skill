#!/bin/bash
# Karma Anime - Veo 3 视频生成脚本
# 使用: ./generate_video.sh "prompt" duration output_file

API_KEY="sk-RPo8Q8Lf9_SKoNMSjo5DNA"
API_BASE="https://llm.tokencloud.ai"

PROMPT="$1"
DURATION="${2:-4}"  # 默认4秒，支持 4/6/8
OUTPUT="${3:-output.mp4}"

# 验证时长参数
if [[ "$DURATION" != "4" && "$DURATION" != "6" && "$DURATION" != "8" ]]; then
    echo "错误: 时长必须是 4, 6, 或 8 秒"
    exit 1
fi

echo "🎬 创建视频任务..."
echo "   提示词: ${PROMPT:0:50}..."
echo "   时长: ${DURATION}秒"

# 创建视频任务
RESPONSE=$(curl -s -X POST "${API_BASE}/videos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${API_KEY}" \
  -d "{
    \"model\": \"google/veo-3.1-generate-preview\",
    \"prompt\": \"${PROMPT}\",
    \"seconds\": \"${DURATION}\"
  }")

VIDEO_ID=$(echo "$RESPONSE" | jq -r '.id')

if [[ "$VIDEO_ID" == "null" || -z "$VIDEO_ID" ]]; then
    echo "❌ 创建任务失败"
    echo "$RESPONSE" | jq .
    exit 1
fi

echo "✅ 任务已创建: ${VIDEO_ID:0:50}..."

# 轮询检查状态
echo "⏳ 等待生成完成..."
while true; do
    STATUS=$(curl -s "${API_BASE}/v1/videos/${VIDEO_ID}" \
      -H "x-litellm-api-key: ${API_KEY}" | jq -r '.status')

    if [[ "$STATUS" == "completed" ]]; then
        echo "✅ 视频生成完成!"
        break
    elif [[ "$STATUS" == "failed" ]]; then
        echo "❌ 视频生成失败"
        curl -s "${API_BASE}/v1/videos/${VIDEO_ID}" -H "x-litellm-api-key: ${API_KEY}" | jq '.error'
        exit 1
    fi

    echo "   状态: $STATUS"
    sleep 10
done

# 下载视频
echo "📥 下载视频..."
curl -s "${API_BASE}/v1/videos/${VIDEO_ID}/content" \
  -H "x-litellm-api-key: ${API_KEY}" \
  -o "$OUTPUT"

SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
echo "✅ 视频已保存: $OUTPUT ($SIZE)"
