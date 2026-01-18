# Karma Anime 动漫制作技能

完整的 AI 动漫制作工作流，从创意到成片一站式完成。

## 特性

- 🎬 **完整工作流**: 剧本 → 分镜 → 定妆 → 视频 → 合成
- 🎨 **多种风格**: 日式动漫、吉卜力、皮克斯、赛博朋克等
- 🤖 **AI 驱动**: Gemini Image + Google Veo 3.1
- ⚡ **高效生成**: 支持并行视频生成

## 技术栈

| 功能 | 技术 |
|------|------|
| 图像生成 | Gemini 3 Pro Image |
| 视频生成 | Google Veo 3.1 |
| 视频合成 | FFmpeg |

## 安装

1. 在 Karma App 的技能商店中搜索 "karma-anime"
2. 点击订阅安装
3. 技能将自动安装到 `~/.claude/skills/karma-anime/`

## 使用方法

在对话中直接说：
- "帮我制作一个动漫视频"
- "创作一部关于太空探险的30秒动画"
- "生成一个日式动漫风格的角色"

## 目录结构

```
karma-anime-skill/
├── SKILL.md           # 主技能文件
├── templates/         # 项目模板
│   ├── project.json
│   ├── script.json
│   └── storyboard.json
├── scripts/           # 辅助脚本
│   ├── generate_video.sh
│   └── merge_videos.sh
├── resources/         # 参考文档
│   └── style_guide.md
└── assets/            # 静态资源
    └── icon.png
```

## API 配置

Veo 3 视频生成 API：
- 端点: `https://llm.tokencloud.ai/videos`
- 模型: `google/veo-3.1-generate-preview`
- 支持时长: 4秒、6秒、8秒

## 许可证

MIT License

## 作者

Karma Team
