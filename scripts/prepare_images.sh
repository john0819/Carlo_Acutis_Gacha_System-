#!/bin/bash
# 图片预处理脚本 - 统一命名并复制到images目录
# 使用方法: ./scripts/prepare_images.sh

set -e

SOURCE_DIR="carlo_img"
TARGET_DIR="images"

echo "🖼️  开始处理图片..."
echo ""

# 检查源目录
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误: 找不到 $SOURCE_DIR 目录"
    exit 1
fi

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 统计PNG文件数量
PNG_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.png" | wc -l | tr -d ' ')

if [ "$PNG_COUNT" -eq 0 ]; then
    echo "❌ 错误: $SOURCE_DIR 目录下没有找到PNG文件"
    exit 1
fi

echo "📊 找到 $PNG_COUNT 张PNG图片"
echo ""

# 备份原有images目录（如果存在重要文件）
if [ -d "$TARGET_DIR" ] && [ "$(ls -A $TARGET_DIR 2>/dev/null)" ]; then
    echo "⚠️  检测到 $TARGET_DIR 目录已有文件"
    # 自动备份（不询问）
    BACKUP_DIR="${TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$TARGET_DIR" "$BACKUP_DIR"
    echo "✅ 已自动备份到: $BACKUP_DIR"
fi

# 清空目标目录（只删除图片，保留其他文件如list.json）
echo ""
echo "🧹 清理目标目录..."
find "$TARGET_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -delete
echo "✅ 清理完成"

# 复制并重命名图片
echo ""
echo "📋 复制并重命名图片..."
COUNTER=1

# 按文件名排序处理
find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.png" | sort | while read -r img; do
    # 统一命名为 card001.png, card002.png ...
    NEW_NAME=$(printf "card%03d.png" $COUNTER)
    TARGET_PATH="$TARGET_DIR/$NEW_NAME"
    
    cp "$img" "$TARGET_PATH"
    echo "   ✅ $NEW_NAME"
    
    COUNTER=$((COUNTER + 1))
done

FINAL_COUNT=$(find "$TARGET_DIR" -maxdepth 1 -type f -name "card*.png" | wc -l | tr -d ' ')

echo ""
echo "=================================================="
echo "✅ 图片处理完成！"
echo "   📊 处理了 $FINAL_COUNT 张图片"
echo "   📁 目标目录: $TARGET_DIR/"
echo ""
echo "💡 下一步:"
echo "   1. 检查图片: ls $TARGET_DIR/card*.png"
echo "   2. 更新数据库: ./update_cards_safe.sh"
echo ""

