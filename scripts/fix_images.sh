#!/bin/bash
# 修复图片加载问题
# 在服务器上运行: ./scripts/fix_images.sh

set -e

PROJECT_DIR="/opt/h5project"
IMAGES_DIR="$PROJECT_DIR/images"

echo "🔧 修复图片加载问题..."
echo ""

# 1. 检查图片目录
echo "📁 检查图片目录..."
if [ ! -d "$IMAGES_DIR" ]; then
    echo "❌ 错误: 图片目录不存在: $IMAGES_DIR"
    exit 1
fi

# 2. 检查图片文件
echo "🖼️  检查图片文件..."
IMAGE_COUNT=$(find "$IMAGES_DIR" -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" \) | wc -l)
echo "   找到 $IMAGE_COUNT 张图片"

if [ "$IMAGE_COUNT" -eq 0 ]; then
    echo "⚠️  警告: 未找到图片文件"
    echo "   请确保图片文件在 $IMAGES_DIR 目录下"
fi

# 3. 生成 list.json
echo ""
echo "📝 生成 list.json..."
if [ -f "$PROJECT_DIR/scripts/generate_list_json.sh" ]; then
    cd "$PROJECT_DIR"
    chmod +x scripts/generate_list_json.sh
    scripts/generate_list_json.sh
else
    echo "⚠️  未找到 generate_list_json.sh 脚本"
    echo "   手动生成 list.json..."
    
    # 手动生成
    IMAGES=$(find "$IMAGES_DIR" -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" \) | sort)
    JSON_ARRAY="["
    FIRST=true
    for img in $IMAGES; do
        filename=$(basename "$img")
        img_url="/images/$filename"
        if [ "$FIRST" = true ]; then
            JSON_ARRAY="${JSON_ARRAY}\n    \"${img_url}\""
            FIRST=false
        else
            JSON_ARRAY="${JSON_ARRAY},\n    \"${img_url}\""
        fi
    done
    JSON_ARRAY="${JSON_ARRAY}\n]"
    
    cat > "$IMAGES_DIR/list.json" << EOF
{
  "images": ${JSON_ARRAY}
}
EOF
    echo "✅ list.json 生成完成"
fi

# 4. 检查文件权限
echo ""
echo "🔐 检查文件权限..."
sudo chmod 644 "$IMAGES_DIR"/*.png 2>/dev/null || true
sudo chmod 644 "$IMAGES_DIR"/*.jpg 2>/dev/null || true
sudo chmod 644 "$IMAGES_DIR"/list.json 2>/dev/null || true
sudo chown -R www-data:www-data "$IMAGES_DIR" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$IMAGES_DIR" 2>/dev/null || true
echo "✅ 权限设置完成"

# 5. 验证文件
echo ""
echo "✅ 验证文件..."
if [ -f "$IMAGES_DIR/list.json" ]; then
    echo "   ✅ list.json 存在"
    LIST_COUNT=$(grep -o '"/images/' "$IMAGES_DIR/list.json" | wc -l)
    echo "   📋 包含 $LIST_COUNT 个图片路径"
else
    echo "   ❌ list.json 不存在"
fi

# 6. 测试访问（如果Nginx运行）
echo ""
echo "🌐 测试图片访问..."
if command -v curl &> /dev/null; then
    TEST_IMG=$(grep -o '"/images/[^"]*' "$IMAGES_DIR/list.json" | head -1 | tr -d '"')
    if [ -n "$TEST_IMG" ]; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$TEST_IMG" 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ]; then
            echo "   ✅ 图片可以正常访问: $TEST_IMG"
        else
            echo "   ⚠️  图片访问失败 (HTTP $HTTP_CODE): $TEST_IMG"
            echo "   请检查Nginx配置和文件路径"
        fi
    fi
fi

echo ""
echo "=================================================="
echo "✅ 修复完成！"
echo ""
echo "📋 如果图片仍然无法加载，请检查："
echo "   1. Nginx配置: /etc/nginx/sites-available/h5project"
echo "   2. 图片文件是否存在: ls -la $IMAGES_DIR/"
echo "   3. list.json内容: cat $IMAGES_DIR/list.json"
echo "   4. Nginx错误日志: sudo tail -f /var/log/nginx/error.log"
echo ""

