#!/bin/bash
# 安全更新卡片数据 - 只添加新图片，不删除用户数据

echo "🔄 安全更新卡片数据（保留用户数据）..."
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

# 获取数据库中已有的图片URL
echo "🔍 检查已有卡片..."
EXISTING_URLS=$(docker exec h5project_db psql -U h5user -d h5project -t -c "SELECT image_url FROM cards;" 2>/dev/null | tr -d ' ')

# 插入/更新卡片
echo "📝 更新卡片数据..."
CARD_NUM=1
ADDED_COUNT=0
SKIPPED_COUNT=0

for img in $IMAGES; do
    # 转换为URL路径
    IMG_URL="/${img}"
    
    # 检查是否已存在
    if echo "$EXISTING_URLS" | grep -q "^${IMG_URL}$"; then
        echo "   ⏭️  跳过（已存在）: $IMG_URL"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    else
        # 获取当前最大卡片编号
        MAX_NUM=$(docker exec h5project_db psql -U h5user -d h5project -t -c "SELECT COALESCE(MAX(CAST(SUBSTRING(name FROM '卡片([0-9]+)') AS INTEGER)), 0) FROM cards WHERE name ~ '^卡片[0-9]+$';" 2>/dev/null | tr -d ' ')
        if [ -z "$MAX_NUM" ] || [ "$MAX_NUM" = "0" ]; then
            CARD_NUM=1
        else
            CARD_NUM=$((MAX_NUM + 1))
        fi
        
        CARD_NAME="卡片${CARD_NUM}"
        
        echo "   ✅ 添加: $CARD_NAME -> $IMG_URL"
        
        docker exec -i h5project_db psql -U h5user -d h5project << EOF
INSERT INTO cards (name, image_url, rarity) 
VALUES ('$CARD_NAME', '$IMG_URL', 'common')
ON CONFLICT DO NOTHING;
EOF
        
        ADDED_COUNT=$((ADDED_COUNT + 1))
        CARD_NUM=$((CARD_NUM + 1))
    fi
done

echo ""
echo "✅ 更新完成！"
echo "   📊 新增: $ADDED_COUNT 张"
echo "   ⏭️  跳过: $SKIPPED_COUNT 张"
echo ""
echo "📋 当前卡片列表："
docker exec h5project_db psql -U h5user -d h5project -c "SELECT id, name, image_url FROM cards ORDER BY id;" 2>/dev/null

