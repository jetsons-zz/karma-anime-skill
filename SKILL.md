---
name: karma-anime
description: AI动漫制作工作流 - 使用Gemini Image和Veo 3.1自动生成动漫视频
license: MIT
compatibility: Claude Code 1.0+
metadata:
  author: Karma
  version: 1.2.0
  category: creation
  tags: [动漫制作, AI视频, Veo3]
allowed-tools:
  - Read
  - Write
  - Bash
  - mcp__tool-gateway__gemini_generate_image
---

# Karma 动漫制作工作室

## When to Use This Skill

当用户想要创作动漫、动画视频时使用此技能。

**触发关键词:** 动漫, 动画, anime, 制作动漫, 动漫视频

## 创作流程

### 1. 创建项目目录

```bash
mkdir -p anime_project/{characters,shots,output}
```

### 2. 剧本与分镜

创建 `script.json`（故事、角色、场景）和 `storyboard.json`（镜头列表）。

### 3. 生成定妆照（必须先完成）

⚠️ **生成视频前必须先为角色生成定妆照并保存描述文件！**

```
Use mcp__tool-gateway__gemini_generate_image
Prompt: "Anime character design sheet, [角色外貌], full body front view, clean white background, japanese anime style"
```

**保存角色描述到文件：**
```bash
echo "japanese anime style, [完整角色外貌描述]" > characters/角色名.txt
```

### 4. 生成视频

⚠️ **必须使用 generate_video.sh 脚本，禁止手动编写 curl/API 调用代码！**

**必须传入角色描述文件（第4个参数），脚本自动合并到提示词：**

```bash
bash ~/.claude/skills/EOS3-zhangkai-project_1769091531278_mkv14ljdn/scripts/generate_video.sh \
  "场景动作描述, 镜头运动, cinematic quality" \
  "4" \
  "shots/shot_001.mp4" \
  "characters/角色名.txt"
```

**参数:** 1-场景动作 2-时长(4/6/8) 3-输出文件 4-角色描述文件

### 5. 合成视频

```bash
cat > concat_list.txt << EOF
file shot_001.mp4
file shot_002.mp4
EOF
ffmpeg -f concat -safe 0 -i concat_list.txt -c copy output/final.mp4
```

## 风格与镜头

- 风格: `japanese anime style` / `studio ghibli style` / `cyberpunk anime`
- 镜头: `static shot` / `slow pan left/right` / `zoom in/out` / `tracking shot`

## 注意事项

1. **定妆照优先**: 必须先生成定妆照并保存角色描述文件
2. **Veo 3时长**: 仅支持 4/6/8 秒
3. **角色一致性**: 脚本自动从文件读取角色描述

## 故障排查

- **角色不一致**: 确认传入了角色描述文件路径
- **脚本报错**: 检查 characters/*.txt 文件是否存在

---

务必使用项目内的 `generate_video.sh` 脚本生成视频。
