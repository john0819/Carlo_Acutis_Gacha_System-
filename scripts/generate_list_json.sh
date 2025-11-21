#!/bin/bash
# 生成 images/list.json 文件
# 使用方法: ./scripts/generate_list_json.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGES_DIR="$PROJECT_DIR/images"
LIST_JSON="$IMAGES_DIR/list.json"

echo "🖼️  生成图片列表文件..."
echo "   图片目录: $IMAGES_DIR"
echo "   输出文件: $LIST_JSON"
echo ""

# 检查图片目录
if [ ! -d "$IMAGES_DIR" ]; then
    echo "❌ 错误: 找不到 images 目录: $IMAGES_DIR"
    exit 1
fi

# 获取所有图片文件（card*.png 或 card*.jpg）
IMAGES=$(find "$IMAGES_DIR" -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" \) | sort)

if [ -z "$IMAGES" ]; then
    echo "⚠️  未找到图片文件（card*.png 或 card*.jpg）"
    echo "   请确保 images 目录下有图片文件"
    exit 1
fi

IMAGE_COUNT=$(echo "$IMAGES" | wc -l | tr -d ' ')
echo "📸 找到 $IMAGE_COUNT 张图片"
echo ""

# 生成JSON数组
echo "📝 生成 list.json..."

# 使用Python或jq生成JSON（更可靠）
if command -v python3 &> /dev/null; then
    python3 << PYEOF > "$LIST_JSON"
import json
import os
import glob

images_dir = "$IMAGES_DIR"
image_files = []
for ext in ['*.png', '*.jpg', '*.jpeg']:
    image_files.extend(glob.glob(os.path.join(images_dir, ext)))
image_files.sort()

image_urls = [f"/images/{os.path.basename(img)}" for img in image_files]

result = {"images": image_urls}
with open("$LIST_JSON", 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)
PYEOF
elif command -v jq &> /dev/null; then
    # 使用jq生成
    echo '{"images":[]}' | jq --argjson imgs "$(printf '%s\n' $IMAGES | sed 's|.*/images/|/images/|' | jq -R . | jq -s .)" '.images = $imgs' > "$LIST_JSON"
else
    # 手动生成（兼容方式）
    {
        echo "{"
        echo "  \"images\": ["
        FIRST=true
        for img in $IMAGES; do
            filename=$(basename "$img")
            img_url="/images/$filename"
            if [ "$FIRST" = true ]; then
                echo "    \"${img_url}\""
                FIRST=false
            else
                echo "    ,\"${img_url}\""
            fi
        done
        echo "  ]"
        echo "}"
    } > "$LIST_JSON"
fi

echo "✅ list.json 生成完成！"
echo ""
echo "📋 前5个图片路径："
head -n 6 "$LIST_JSON" | tail -n 5
echo ""

