---
name: karma-anime
description: 完整的 AI 动漫制作工作流，支持剧本创作、分镜设计、角色定妆、视频生成和后期合成，使用 Gemini Image 和 Veo 3.1 模型
license: MIT
compatibility: Claude Code 1.0+
metadata:
  author: Karma
  version: 1.0.0
  category: creation
  tags:
    - 动漫制作
    - AI视频
    - Veo3
    - 角色设计
    - 分镜设计
allowed-tools:
  - Read
  - Write
  - Bash
  - mcp__tool-gateway__gemini_generate_image
---

# Karma 动漫制作工作室

完整的 AI 动漫制作工作流，从创意到成片一站式完成。

## When to Use This Skill

当用户想要创作动漫、动画视频时使用此技能。支持的请求包括：
- "帮我制作一个动漫视频"
- "创作一部关于...的动画短片"
- "生成动漫角色"
- "设计动漫分镜"

**触发关键词:** 动漫, 动画, anime, 制作动漫, 动漫视频, 动画短片

## 技术栈

| 阶段 | 技术 |
|------|------|
| 图像生成 | Gemini 3 Pro Image |
| 视频生成 | **Google Veo 3.1** |
| 视频合成 | FFmpeg |

## 创作流程

完整的动漫制作包含 6 个阶段：

### 1. 初始化项目

设置动漫风格、目标时长、画面比例，创建项目目录结构：

```bash
mkdir -p anime_project/{characters,shots,output}
```

**项目配置示例 (project.json):**
```json
{
  "name": "项目名称",
  "style": "anime",
  "duration": "30s",
  "aspectRatio": "16:9",
  "shotDuration": 4,
  "totalShots": 6
}
```

### 2. 剧本创作

生成故事梗概、角色列表和场景设定：

**剧本结构 (script.json):**
```json
{
  "title": "故事标题",
  "logline": "一句话概述",
  "synopsis": "故事梗概",
  "characters": [
    {
      "id": "char_001",
      "name": "角色名",
      "appearance": {
        "hair": "发型描述",
        "eyes": "眼睛描述",
        "outfit": "服装描述"
      },
      "promptKeywords": "英文关键词用于图像生成"
    }
  ],
  "setting": {
    "time": "时代背景",
    "locations": ["场景1", "场景2"]
  }
}
```

### 3. 分镜设计

将剧本转化为详细分镜列表：

**分镜结构 (storyboard.json):**
```json
{
  "totalShots": 6,
  "shots": [
    {
      "id": "shot_001",
      "scene": "场景描述",
      "duration": 4,
      "visual": "画面描述",
      "camera": "镜头运动",
      "dialogue": "对白（可选）",
      "prompt": "完整的视频生成提示词"
    }
  ]
}
```

### 4. 角色定妆

使用 Gemini Image 生成角色设计图：

```
调用 mcp__tool-gateway__gemini_generate_image 工具

提示词格式：
"Anime character design sheet, [角色描述],
full body front view and side view,
clean white background, japanese anime style,
cel shading, high quality character reference sheet"
```

### 5. 视频生成 (Veo 3.1)

使用 Google Veo 3.1 API 生成视频片段。

**API 配置:**
- 端点: `https://llm.tokencloud.ai/videos`
- 模型: `google/veo-3.1-generate-preview`
- 认证: `Bearer ${TOKENCLOUD_API_KEY}` (需设置环境变量)
- 支持时长: **4秒、6秒、8秒**

**创建视频任务:**
```bash
curl -s -X POST "https://llm.tokencloud.ai/videos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKENCLOUD_API_KEY}" \
  -d '{
    "model": "google/veo-3.1-generate-preview",
    "prompt": "japanese anime style, [画面描述], [镜头运动], cinematic quality",
    "seconds": "4"
  }'
```

**查询状态:**
```bash
curl -s "https://llm.tokencloud.ai/v1/videos/{VIDEO_ID}" \
  -H "x-litellm-api-key: ${TOKENCLOUD_API_KEY}"
```

**下载视频 (status=completed 后):**
```bash
curl -s "https://llm.tokencloud.ai/v1/videos/{VIDEO_ID}/content" \
  -H "x-litellm-api-key: ${TOKENCLOUD_API_KEY}" \
  -o shot_001.mp4
```

### 6. 后期合成

使用 FFmpeg 合并视频片段：

```bash
# 创建合并列表
cat > concat_list.txt << EOF
file 'shot_001.mp4'
file 'shot_002.mp4'
file 'shot_003.mp4'
EOF

# 合并视频
ffmpeg -f concat -safe 0 -i concat_list.txt -c copy output/final.mp4
```

## 支持的风格

| 风格 | 关键词 |
|------|--------|
| 日式动漫 | `japanese anime style, cel shading, vibrant colors` |
| 吉卜力 | `studio ghibli style, hand-drawn, pastoral atmosphere` |
| 皮克斯 3D | `3D pixar style, smooth rendering, warm lighting` |
| 赛博朋克 | `cyberpunk anime, neon lights, futuristic` |
| 水墨中国风 | `chinese ink wash painting style, traditional` |
| 写实风格 | `photorealistic anime, cinematic, detailed` |

## 镜头类型参考

- `static shot` - 固定镜头
- `slow pan left/right` - 慢速平移
- `zoom in/out` - 推拉镜头
- `tracking shot` - 跟踪镜头
- `aerial shot` - 航拍镜头
- `close-up` - 特写
- `medium shot` - 中景
- `establishing shot` - 建立镜头

## 项目目录结构

```
anime_project/
├── project.json        # 项目配置
├── script.json         # 剧本数据
├── storyboard.json     # 分镜数据
├── characters/         # 角色定妆图
│   ├── char_001.png
│   └── char_002.png
├── shots/              # 视频片段
│   ├── shot_001.mp4
│   ├── shot_002.mp4
│   └── ...
└── output/             # 最终输出
    └── final.mp4
```

## 环境变量配置

使用前需要设置 Veo API 密钥:

```bash
export TOKENCLOUD_API_KEY="your-api-key-here"
```

或者在 `~/.bashrc` / `~/.zshrc` 中添加:
```bash
export TOKENCLOUD_API_KEY="your-api-key-here"
```

## 使用示例

**用户:** "帮我创作一部30秒的太空探险动漫"

**助手执行流程:**
1. 确认风格（日式动漫）和参数
2. 创建项目目录结构
3. 生成剧本：故事梗概、角色设定
4. 设计分镜：6个镜头，每个4-6秒
5. 生成角色定妆图
6. 使用 Veo 3 生成 6 个视频片段
7. FFmpeg 合成最终视频
8. 输出到 `anime_project/output/final.mp4`

## 注意事项

1. **Veo 3 时长限制**: 仅支持 4/6/8 秒，不支持其他时长
2. **生成时间**: 每个视频片段约需 1-2 分钟
3. **角色一致性**: 在所有镜头中保持角色描述一致
4. **提示词质量**: 详细的提示词能获得更好效果
5. **并行生成**: 可同时提交多个视频任务加速生成

## 常见问题

**Q: 视频生成失败怎么办？**
A: 检查 `seconds` 参数是否为 4/6/8，检查提示词是否过长或包含敏感内容。

**Q: 如何保持角色一致性？**
A: 在所有分镜的 prompt 中使用相同的角色外貌描述关键词。

**Q: 支持多长的视频？**
A: 建议 30 秒到 2 分钟，通过多个 4-8 秒片段合成。
