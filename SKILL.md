---
name: karma-anime
description: AI动漫制作工作流 - 使用Gemini Image和Veo 3生成动漫视频
license: MIT
compatibility: Claude Code 1.0+
metadata:
  author: Karma
  version: 1.3.0
  category: creation
  tags: [动漫制作, AI视频, Veo3]
allowed-tools:
  - Read
  - Write
  - Bash
  - mcp__tool-gateway__gemini_generate_image
---

# Karma 动漫制作工作室

当用户想要创作动漫、动画视频时使用此技能。

**触发关键词:** 动漫, 动画, anime, 制作动漫, 动漫视频

---

## ⚠️ 必须严格按以下步骤执行，不要跳步或修改命令

### 第 1 步：初始化项目

```bash
SKILL_DIR=$(dirname "$(find "${HOME}/.claude/skills" -maxdepth 3 -name "create_task.sh" -path "*/scripts/*" 2>/dev/null | head -1)")/..
cd "${SKILL_DIR}/workspace"
mkdir -p myproject/characters myproject/output myproject/shots
cd myproject
```

> ⚠️ **每个 Bash 调用的开头**都必须先设置 SKILL_DIR 和 cd 到项目目录，因为每次 Bash 调用是独立的 shell 环境：
> ```bash
> SKILL_DIR=$(dirname "$(find "${HOME}/.claude/skills" -maxdepth 3 -name "create_task.sh" -path "*/scripts/*" 2>/dev/null | head -1)")/..
> cd "${SKILL_DIR}/workspace/myproject"
> ```

### 第 2 步：创建角色描述文件

```bash
cat > characters/hero.txt << 'EOF'
japanese anime style, [角色1外貌描述], [角色2外貌描述（如有）]
EOF
```

> ⚠️ **多角色场景**：所有角色描述必须写在同一个文件中，用逗号分隔。不要传多个文件！

### 第 3 步：计算片段拆分

Veo 3.1 单段仅支持 4/6/8 秒。根据用户要求的总时长，拆分为多个片段：
- 4秒 → [4]
- 6秒 → [6]
- 8秒 → [8]
- 10秒 → [6, 4]
- 12秒 → [8, 4]
- 14秒 → [8, 6]
- 16秒 → [8, 8]
- 更长 → 每8秒一段，余数按上述规则

### 第 4 步：生成定妆照 + 创建所有视频任务（⚡ 并行执行）

> ⚠️ **必须在同一个回复中同时发起以下所有工具调用，实现真正并行。不要分多次发送！**

在**同一个回复**中并行发起：

**工具调用 A - 生成定妆照：**
```
Use mcp__tool-gateway__gemini_generate_image
Prompt: "Anime character design sheet, [角色外貌描述], full body front view, clean white background, japanese anime style"
```

**工具调用 B/C/D... - 创建每个片段的视频任务：**
```bash
bash "${SKILL_DIR}/scripts/create_task.sh" \
  "场景动作描述, 镜头运动, cinematic quality" \
  "片段秒数" \
  "characters/hero.txt"
```

> 💡 例如 10 秒视频拆分为 [6, 4]，则在同一个回复中发起 3 个并行调用：gemini_generate_image + create_task.sh(6s) + create_task.sh(4s)

**create_task.sh 输出示例：**
```
[SUCCESS] 任务已创建
VIDEO_ID=gen-xxxxxxxxxxxxx
```

> ⚠️ **必须记录每个片段的 VIDEO_ID**，后续轮询和下载需要用到。

### 第 5 步：轮询等待每个任务完成

对每个 VIDEO_ID 反复调用（每次约 2 秒）：
```bash
bash "${SKILL_DIR}/scripts/poll_status.sh" "VIDEO_ID值"
```

**输出示例：**
```
STATUS=processing  ← 还在生成，等 15 秒后再查
STATUS=completed   ← 生成完成，进入下载步骤
STATUS=failed      ← 生成失败，需要重新创建任务
```

> ⚠️ **轮询规则**：
> - 每次轮询间隔 **15 秒**（使用 `sleep 15`）
> - 最多轮询 **40 次**（约 10 分钟）
> - 多个任务可在同一个回复中并行轮询
> - `STATUS=completed` 时进入第 6 步
> - `STATUS=failed` 时重新执行 create_task.sh 创建新任务

### 第 6 步：下载已完成的视频

对每个已完成的 VIDEO_ID 执行：
```bash
bash "${SKILL_DIR}/scripts/download_video.sh" \
  "VIDEO_ID值" \
  "shots/shot_001.mp4"
```

> 文件名按顺序编号：shot_001.mp4, shot_002.mp4, ...

### 第 7 步：合并视频片段（仅多片段时需要）

如果只有一个片段，直接复制到最终输出：
```bash
cp shots/shot_001.mp4 output/video.mp4
```

如果有多个片段，使用合并脚本：
```bash
bash "${SKILL_DIR}/scripts/merge_videos.sh" "shots" "output/video.mp4"
```

---

## ⛔ 禁止事项

| 禁止 | 原因 |
|------|------|
| ❌ 手写 curl 调用 API | 必须使用脚本 |
| ❌ 在 /tmp 目录工作 | noexec 限制 |
| ❌ 调用 `mcp__tool-gateway__gemini_generate_video` | 绕过 Veo 3.1 流程 |
| ❌ 使用可灵/Kling 或其他视频模型 | 必须使用 Veo 3.1 |
| ❌ 跳过角色描述文件 | 角色外貌不一致 |
| ❌ 使用 run_skill.sh 或 generate_video.sh | 已删除 |
| ❌ 把多个步骤放在一个 Bash 调用里执行 | 会触发平台 300 秒超时 |

> **强制要求**：视频生成只能使用 `create_task.sh` + `poll_status.sh` + `download_video.sh` 三个脚本分步执行。脚本内部固定使用 **Veo 3.1** (`google/veo-3.1-generate-preview`)。

---

## 📋 用户界面显示规则

> ⚠️ **以下内容不要展示给用户，只在内部使用：**
> - VIDEO_ID（很长的 base64 字符串）
> - 脚本执行的原始输出
> - 轮询状态的详细信息（STATUS=processing 等）
> - 技术参数（API 地址、片段秒数拆分等）
> - 定妆照图片：**禁止在文本中用 `![](路径)` 重复展示定妆照**。平台在 gemini_generate_image 工具返回时已自动展示图片，Claude 再次引用会导致 "Failed to load image" 错误。

**应该展示给用户的内容：**
- 简洁的进度提示，例如：「视频生成中，请稍候...」「片段 1/2 已完成」
- 最终生成的视频文件路径：**必须用绝对路径纯文本**，禁止用反引号 \` 或其他 markdown 格式包裹，否则用户无法点击下载。正确示例：「视频已生成：/home/laiye/.../output/video.mp4」
- 失败时的简要错误说明

---

## 完整示例

### 单角色 8 秒视频

**步骤 1-2：初始化 + 创建角色描述**
```bash
SKILL_DIR=$(dirname "$(find "${HOME}/.claude/skills" -maxdepth 3 -name "create_task.sh" -path "*/scripts/*" 2>/dev/null | head -1)")/..
cd "${SKILL_DIR}/workspace"
mkdir -p sword_battle/characters sword_battle/output sword_battle/shots
cd sword_battle

cat > characters/hero.txt << 'EOF'
japanese anime style, young male swordsman with long black hair, white hanfu robe, glowing jade sword
EOF
```

**步骤 3：计算拆分** → 8秒 = [8]，单片段

**步骤 4：在同一个回复中并行发起 2 个工具调用：**
- 调用 A: `mcp__tool-gateway__gemini_generate_image` 生成定妆照
- 调用 B: `bash create_task.sh "Epic sword battle, hero leaping through clouds, cinematic quality" "8" "characters/hero.txt"`
- 记录输出: VIDEO_ID=gen-xxx

**步骤 5：轮询（每 15 秒一次）**
```bash
bash "${SKILL_DIR}/scripts/poll_status.sh" "gen-xxx"
# → STATUS=processing → sleep 15 → 再次轮询
# → STATUS=completed → 进入下载
```

**步骤 6：下载**
```bash
bash "${SKILL_DIR}/scripts/download_video.sh" "gen-xxx" "output/battle.mp4"
```

### 多角色 10 秒视频（拆分为 6s + 4s）

**步骤 1-2：初始化 + 创建角色描述（所有角色写在同一个文件）**
```bash
cat > characters/fighters.txt << 'EOF'
japanese anime style, male sword immortal with long black hair in white robe holding jade sword, female sword immortal with silver hair in blue robe holding crystal blade
EOF
```

**步骤 3：计算拆分** → 10秒 = [6, 4]

**步骤 4：在同一个回复中并行发起 3 个工具调用：**
- 调用 A: `mcp__tool-gateway__gemini_generate_image` 生成定妆照
- 调用 B: `bash create_task.sh "Two sword immortals fighting, dynamic camera, cinematic quality" "6" "characters/fighters.txt"` → VIDEO_ID_1
- 调用 C: `bash create_task.sh "Two sword immortals fighting, dynamic camera, cinematic quality" "4" "characters/fighters.txt"` → VIDEO_ID_2

**步骤 5：并行轮询两个任务（同一个回复中）**
```bash
bash "${SKILL_DIR}/scripts/poll_status.sh" "VIDEO_ID_1"
bash "${SKILL_DIR}/scripts/poll_status.sh" "VIDEO_ID_2"
```

**步骤 6：下载（按顺序编号）**
```bash
bash "${SKILL_DIR}/scripts/download_video.sh" "VIDEO_ID_1" "shots/shot_001.mp4"
bash "${SKILL_DIR}/scripts/download_video.sh" "VIDEO_ID_2" "shots/shot_002.mp4"
```

**步骤 7：合并**
```bash
bash "${SKILL_DIR}/scripts/merge_videos.sh" "shots" "output/battle.mp4"
```

---

## 故障排查

| 错误 | 解决方案 |
|------|---------|
| 角色描述文件不存在 | 确保第 2 步创建了 characters/xxx.txt |
| create_task.sh 失败 | 检查网络连接，确认 API 可用 |
| STATUS=failed | 重新执行 create_task.sh 创建新任务 |
| 下载失败 | 确认 STATUS=completed 后再下载 |
| 合并失败 | 确认 shots/ 目录下有 shot_*.mp4 文件 |
