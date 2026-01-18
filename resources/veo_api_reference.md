# Veo 3 API Reference

TokenCloud Veo 3.1 视频生成 API 完整参考文档。

## API 概览

| 项目 | 值 |
|------|-----|
| 基础URL | `https://llm.tokencloud.ai` |
| 模型 | `google/veo-3.1-generate-preview` |
| 认证 | Bearer Token |
| 支持时长 | 4秒、6秒、8秒 |

---

## 1. 创建视频生成任务

### 请求

```bash
curl -s --location --request POST 'https://llm.tokencloud.ai/videos' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer sk-RPo8Q8Lf9_SKoNMSjo5DNA' \
--data-raw '{
  "model": "google/veo-3.1-generate-preview",
  "prompt": "japanese anime style, young female character with flowing blue hair, cherry blossom petals floating in the wind, soft pink lighting, gentle camera pan right",
  "seconds": "4"
}'
```

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| model | string | 是 | 固定值 `google/veo-3.1-generate-preview` |
| prompt | string | 是 | 视频描述提示词 |
| seconds | string | 否 | 视频时长: "4", "6", "8" (默认 "4") |

### 响应

```json
{
  "id": "4f4b5e9e-09dc-425d-b08b-29d232c64f98",
  "created_at": 1737210055,
  "status": "pending",
  "model": "google/veo-3.1-generate-preview"
}
```

### 响应字段

| 字段 | 说明 |
|------|------|
| id | 视频任务 ID，用于后续查询 |
| created_at | 任务创建时间戳 |
| status | 任务状态 (pending, processing, completed, failed) |
| model | 使用的模型 |

---

## 2. 查询视频生成状态

### 请求

```bash
curl -s 'https://llm.tokencloud.ai/v1/videos/{VIDEO_ID}' \
--header 'x-litellm-api-key: sk-RPo8Q8Lf9_SKoNMSjo5DNA'
```

### 响应 - 处理中

```json
{
  "id": "4f4b5e9e-09dc-425d-b08b-29d232c64f98",
  "created_at": 1737210055,
  "status": "processing",
  "model": "google/veo-3.1-generate-preview"
}
```

### 响应 - 完成

```json
{
  "id": "4f4b5e9e-09dc-425d-b08b-29d232c64f98",
  "created_at": 1737210055,
  "status": "completed",
  "model": "google/veo-3.1-generate-preview",
  "video_url": "https://storage.googleapis.com/..."
}
```

### 状态说明

| 状态 | 说明 |
|------|------|
| pending | 任务已创建，等待处理 |
| processing | 视频生成中 |
| completed | 生成完成，可下载 |
| failed | 生成失败 |

---

## 3. 下载视频文件

### 请求

```bash
curl 'https://llm.tokencloud.ai/v1/videos/{VIDEO_ID}/content' \
--header 'x-litellm-api-key: sk-RPo8Q8Lf9_SKoNMSjo5DNA' \
--output shot_001.mp4
```

### 说明

- 返回 MP4 格式视频文件
- 建议使用 `-o` 或 `--output` 保存到本地文件

---

## 工作流示例

### 完整流程

```bash
#!/bin/bash
# 1. 创建任务
RESPONSE=$(curl -s --location --request POST 'https://llm.tokencloud.ai/videos' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer sk-RPo8Q8Lf9_SKoNMSjo5DNA' \
--data-raw '{
  "model": "google/veo-3.1-generate-preview",
  "prompt": "your prompt here",
  "seconds": "4"
}')

VIDEO_ID=$(echo $RESPONSE | jq -r '.id')
echo "Video ID: $VIDEO_ID"

# 2. 轮询状态
while true; do
  STATUS=$(curl -s "https://llm.tokencloud.ai/v1/videos/$VIDEO_ID" \
    --header 'x-litellm-api-key: sk-RPo8Q8Lf9_SKoNMSjo5DNA' | jq -r '.status')

  echo "Status: $STATUS"

  if [ "$STATUS" = "completed" ]; then
    break
  elif [ "$STATUS" = "failed" ]; then
    echo "Generation failed"
    exit 1
  fi

  sleep 10
done

# 3. 下载视频
curl "https://llm.tokencloud.ai/v1/videos/$VIDEO_ID/content" \
  --header 'x-litellm-api-key: sk-RPo8Q8Lf9_SKoNMSjo5DNA' \
  --output output.mp4

echo "Video saved to output.mp4"
```

---

## 提示词最佳实践

### 结构

```
[风格] + [主体描述] + [动作] + [环境] + [光影] + [镜头运动]
```

### 示例

```
japanese anime style, young samurai with black hair and red katana,
slashing through falling autumn leaves, ancient temple background,
dramatic sunset lighting, dynamic camera tracking shot
```

### 风格关键词

- 日式动漫: `japanese anime style, cel shading, vibrant colors`
- 吉卜力: `studio ghibli style, hand-drawn, watercolor textures`
- 赛博朋克: `cyberpunk anime, neon lights, futuristic city`
- 中国风: `chinese ink wash painting style, elegant brushwork`

### 镜头运动

- 固定: `static shot`
- 平移: `pan left/right`
- 推进: `zoom in`
- 跟踪: `tracking shot`
- 环绕: `orbit shot`

---

## 注意事项

1. **生成时间**: 每个视频约需 1-3 分钟生成
2. **并发限制**: 建议同时不超过 3 个任务
3. **提示词长度**: 建议 50-200 字符
4. **角色一致性**: 保持角色描述一致以确保连贯性
