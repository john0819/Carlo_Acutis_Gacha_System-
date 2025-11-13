#!/bin/bash
# 服务器端更新卡片脚本 - 不使用Docker，直接连接PostgreSQL
# 使用方法: ./scripts/update_cards_server.sh

set -e

echo "🔄 更新卡片数据（服务器端）..."
echo ""

# 检查数据库连接
if ! PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ 数据库连接失败"
    echo "   请检查数据库是否运行，或修改脚本中的数据库配置"
    exit 1
fi

# 获取所有图片文件
IMAGES=$(find images -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" -o -name "*.png" -o -name "*.jpg" \) | sort)

if [ -z "$IMAGES" ]; then
    echo "❌ 未找到图片文件"
    exit 1
fi

echo "📸 找到以下图片："
echo "$IMAGES" | sed 's/^/   /'
echo ""

# 获取数据库中已有的图片URL
echo "🔍 检查已有卡片..."
EXISTING_URLS=$(PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -t -c "SELECT image_url FROM cards;" 2>/dev/null | tr -d ' ')

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
        MAX_NUM=$(PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -t -c "SELECT COALESCE(MAX(CAST(SUBSTRING(name FROM '卡片([0-9]+)') AS INTEGER)), 0) FROM cards WHERE name ~ '^卡片[0-9]+$';" 2>/dev/null | tr -d ' ')
        if [ -z "$MAX_NUM" ] || [ "$MAX_NUM" = "0" ]; then
            CARD_NUM=1
        else
            CARD_NUM=$((MAX_NUM + 1))
        fi
        
        CARD_NAME="卡片${CARD_NUM}"
        
        echo "   ✅ 添加: $CARD_NAME -> $IMG_URL"
        
        PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project << EOF > /dev/null 2>&1
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
PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -c "SELECT id, name, image_url FROM cards ORDER BY id;" 2>/dev/null

