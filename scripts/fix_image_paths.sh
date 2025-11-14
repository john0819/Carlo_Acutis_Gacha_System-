#!/bin/bash
# 修复数据库中错误的图片路径
# 将 /images/image*.jpg 和 /images/image*.png 改为对应的 /images/card*.png

set -e

echo "🔧 修复数据库中的图片路径..."
echo ""

# 检查数据库连接
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库容器未运行"
    echo "   请先启动数据库: ./start_db.sh"
    exit 1
fi

# 修复 image1.jpg -> card001.png, image2.jpg -> card002.png 等
echo "📝 修复 image*.jpg 路径..."
docker exec h5project_db psql -U h5user -d h5project << 'EOF'
-- 修复 image1.jpg -> card001.png
UPDATE cards SET image_url = '/images/card001.png' WHERE image_url = '/images/image1.jpg';
UPDATE cards SET image_url = '/images/card002.png' WHERE image_url = '/images/image2.jpg';
UPDATE cards SET image_url = '/images/card003.png' WHERE image_url = '/images/image3.jpg';
UPDATE cards SET image_url = '/images/card004.png' WHERE image_url = '/images/image4.jpg';
UPDATE cards SET image_url = '/images/card005.png' WHERE image_url = '/images/image5.jpg';

-- 修复 image*.png 路径
UPDATE cards SET image_url = '/images/card001.png' WHERE image_url = '/images/image1.png';
UPDATE cards SET image_url = '/images/card002.png' WHERE image_url = '/images/image2.png';
UPDATE cards SET image_url = '/images/card003.png' WHERE image_url = '/images/image3.png';
EOF

echo "✅ 路径修复完成"
echo ""

# 显示修复后的结果
echo "📋 修复后的前10张卡片路径："
docker exec h5project_db psql -U h5user -d h5project -c "SELECT id, name, image_url FROM cards ORDER BY id LIMIT 10;"

echo ""
echo "✅ 修复完成！"

