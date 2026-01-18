#!/bin/bash
# Karma Anime - 视频合并脚本
# 使用: ./merge_videos.sh shots_dir output_file

SHOTS_DIR="${1:-.}"
OUTPUT="${2:-final.mp4}"

echo "🎬 合并视频片段..."
echo "   输入目录: $SHOTS_DIR"
echo "   输出文件: $OUTPUT"

# 创建合并列表
CONCAT_FILE=$(mktemp)
for f in "$SHOTS_DIR"/shot_*.mp4; do
    if [[ -f "$f" ]]; then
        echo "file '$f'" >> "$CONCAT_FILE"
        echo "   添加: $(basename $f)"
    fi
done

# 检查是否有文件
if [[ ! -s "$CONCAT_FILE" ]]; then
    echo "❌ 未找到视频片段 (shot_*.mp4)"
    rm "$CONCAT_FILE"
    exit 1
fi

# 合并
ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c copy "$OUTPUT" 2>/dev/null

if [[ $? -eq 0 ]]; then
    SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
    DURATION=$(ffprobe -v quiet -show_format "$OUTPUT" | grep duration | cut -d= -f2 | cut -d. -f1)
    echo "✅ 合并完成: $OUTPUT"
    echo "   大小: $SIZE"
    echo "   时长: ${DURATION}秒"
else
    echo "❌ 合并失败"
fi

rm "$CONCAT_FILE"
