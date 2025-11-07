#!/bin/bash
# 更新卡片数据 - 从images目录同步图片到数据库
# ⚠️ 警告：此脚本会清空所有用户卡包和抽卡记录！

echo "🔄 更新卡片数据..."
echo ""
echo "⚠️  警告：此操作会清空所有用户卡包和每日抽卡记录！"
echo "   如果只想添加新图片，请使用: ./update_cards_safe.sh"
echo ""
read -p "确认继续？(y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "❌ 已取消"
    exit 0
fi
echo ""

# 检查数据库是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库未运行，请先启动数据库: ./start_db.sh"
    exit 1
fi

# 获取所有图片文件
IMAGES=$(find images -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | sort)

if [ -z "$IMAGES" ]; then
    echo "❌ 未找到图片文件"
    exit 1
fi

echo "📸 找到以下图片："
echo "$IMAGES" | sed 's/^/   /'
echo ""

# 清空现有卡片并重新导入
echo "🗑️  清空现有卡片..."
docker exec -i h5project_db psql -U h5user -d h5project << 'EOF'
TRUNCATE TABLE user_cards CASCADE;
TRUNCATE TABLE daily_draws CASCADE;
TRUNCATE TABLE cards CASCADE;
EOF
echo "✅ 已清空"

# 插入/更新卡片
echo "📝 更新卡片数据..."
CARD_NUM=1
for img in $IMAGES; do
    # 转换为URL路径
    IMG_URL="/${img}"
    CARD_NAME="卡片${CARD_NUM}"
    
    echo "   添加: $CARD_NAME -> $IMG_URL"
    
    docker exec -i h5project_db psql -U h5user -d h5project << EOF
INSERT INTO cards (name, image_url, rarity) 
VALUES ('$CARD_NAME', '$IMG_URL', 'common')
ON CONFLICT DO NOTHING;
EOF
    
    CARD_NUM=$((CARD_NUM + 1))
done

echo ""
echo "✅ 卡片数据更新完成！"
echo ""
echo "📊 当前卡片列表："
docker exec h5project_db psql -U h5user -d h5project -c "SELECT id, name, image_url FROM cards ORDER BY id;" 2>/dev/null

