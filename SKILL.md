---
name: karma-anime
description: AI动漫制作工作流 - 使用Gemini Image和Veo 3.1自动生成动漫视频
license: MIT
compatibility: Claude Code 1.0+
metadata:
  author: Karma
  version: 1.1.0
  category: creation
  tags: [动漫制作, AI视频, Veo3]
allowed-tools:
  - Read
  - Write
  - Bash
  - mcp__tool-gateway__gemini_generate_image
---

# Karma 动漫制作工作室

完整的AI动漫制作工作流，从创意到成片一站式完成。

## When to Use This Skill

当用户想要创作动漫、动画视频时使用此技能。

**触发关键词:** 动漫, 动画, anime, 制作动漫, 动漫视频

## 技术栈

| 阶段 | 技术 |
|------|------|
| 图像生成 | Gemini 3 Pro Image |
| 视频生成 | Google Veo 3.1 |
| 视频合成 | FFmpeg |

## 创作流程

### 1. 创建项目目录

```bash
mkdir -p anime_project/{characters,shots,output}
```

### 2. 剧本创作

创建 `script.json`，包含：
- 故事梗概
- 角色列表（每个角色的外貌描述要保持一致）
- 场景设定

### 3. 分镜设计

创建 `storyboard.json`，每个镜头包含：
- `scene`: 场景描述
- `duration`: 时长 (4-8秒)
- `visual`: 画面描述
- `camera`: 镜头运动
- `prompt`: 视频生成提示词

### 4. 调用工具生成

**生成角色图：**
```
Use mcp__tool-gateway__gemini_generate_image
Prompt: "Anime character design sheet, [角色描述], full body front view, clean white background, japanese anime style"
```

**生成视频：**
```bash
bash ~/.claude/skills/EOS3-zhangkai-project_1769091531278_mkv14ljdn/scripts/generate_video.sh \
  "japanese anime style, [画面描述], [镜头运动], cinematic quality" \
  "4" \
  "shot_001.mp4"
```

**参数说明：**
- 参数1: 视频提示词（英文推荐）
- 参数2: 视频时长（4/6/8秒）
- 参数3: 输出文件名

### 5. 合成视频

```bash
cat > concat_list.txt << EOF
file shot_001.mp4
file shot_002.mp4
file shot_003.mp4
EOF

ffmpeg -f concat -safe 0 -i concat_list.txt -c copy output/final.mp4
```

## 支持的风格

- 日式动漫: `japanese anime style, cel shading, vibrant colors`
- 吉卜力: `studio ghibli style, hand-drawn, pastoral atmosphere`
- 赛博朋克: `cyberpunk anime, neon lights, futuristic`

## 镜头类型

`static shot`, `slow pan left/right`, `zoom in/out`, `tracking shot`, `aerial shot`, `close-up`

## 注意事项

1. **Veo 3时长限制**: 仅支持 4/6/8 秒
2. **角色一致性**: 所有镜头使用相同角色描述关键词
3. **生成时间**: 每个片段约 1-2 分钟
4. **提示词**: 英文提示词效果更好

## 故障排查

**视频生成失败？**
- 检查 `seconds` 参数是否为 4/6/8
- 检查提示词是否过长

**角色不一致？**
- 在所有镜头中使用相同的角色外貌描述

---

## 📚 完整参考文档

详细API说明、配置示例和故障排查请查看: `SKILL-REFERENCE.md`

## ⚠️ 重要提示 (2026-01-27)

务必使用项目内的 `generate_video.sh` 脚本生成视频，不要手动编写包含for循环的bash命令。
