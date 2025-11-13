#!/bin/bash
# 服务器初始化脚本 - 初始化数据库和导入图片
# 在服务器上运行，部署后执行一次

set -e

echo "🚀 服务器初始化..."
echo ""

# 检查数据库连接
echo "🔍 检查数据库连接..."
if ! PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ 数据库连接失败，请确保："
    echo "   1. 数据库已启动"
    echo "   2. 数据库配置正确"
    exit 1
fi
echo "✅ 数据库连接正常"
echo ""

# 初始化数据库表结构
echo "📊 初始化数据库表结构..."
if [ -f "init.sql" ]; then
    PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -f init.sql > /dev/null 2>&1
    echo "✅ 数据库表结构初始化完成"
else
    echo "⚠️  未找到 init.sql 文件"
fi
echo ""

# 导入图片到数据库
echo "🖼️  导入图片到数据库..."
if [ ! -d "images" ]; then
    echo "❌ 错误: 找不到 images 目录"
    exit 1
fi

# 获取所有图片文件（统一命名后的card*.png）
IMAGES=$(find images -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" \) | sort)

if [ -z "$IMAGES" ]; then
    echo "⚠️  未找到图片文件，跳过导入"
    exit 0
fi

IMAGE_COUNT=$(echo "$IMAGES" | wc -l | tr -d ' ')
echo "📸 找到 $IMAGE_COUNT 张图片"
echo ""

# 获取数据库中已有的图片URL
EXISTING_URLS=$(PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -t -c "SELECT image_url FROM cards;" 2>/dev/null | tr -d ' ')

# 插入/更新卡片
CARD_NUM=1
ADDED_COUNT=0
SKIPPED_COUNT=0

for img in $IMAGES; do
    # 转换为URL路径
    IMG_URL="/${img}"
    
    # 检查是否已存在
    if echo "$EXISTING_URLS" | grep -q "^${IMG_URL}$"; then
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
        
        PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project << EOF > /dev/null 2>&1
INSERT INTO cards (name, image_url, rarity) 
VALUES ('$CARD_NAME', '$IMG_URL', 'common')
ON CONFLICT DO NOTHING;
EOF
        
        ADDED_COUNT=$((ADDED_COUNT + 1))
        CARD_NUM=$((CARD_NUM + 1))
    fi
done

echo "✅ 导入完成！"
echo "   📊 新增: $ADDED_COUNT 张"
echo "   ⏭️  跳过: $SKIPPED_COUNT 张"
echo ""

# 显示当前卡片数量
TOTAL_CARDS=$(PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -t -c "SELECT COUNT(*) FROM cards;" 2>/dev/null | tr -d ' ')
echo "📋 当前数据库中共有 $TOTAL_CARDS 张卡片"
echo ""

