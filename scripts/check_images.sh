#!/bin/bash
# 检查图片配置和数据库中的卡片数据
# 使用方法: ./scripts/check_images.sh

echo "🔍 检查图片配置..."
echo ""

# 1. 检查图片文件
echo "📁 步骤1: 检查图片文件"
if [ ! -d "images" ]; then
    echo "❌ images 目录不存在"
    exit 1
fi

IMAGE_COUNT=$(find images -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" \) | wc -l | tr -d ' ')
echo "✅ 找到 $IMAGE_COUNT 张图片文件"
if [ "$IMAGE_COUNT" -gt 0 ]; then
    echo "   前5张图片："
    find images -maxdepth 1 -type f \( -name "card*.png" -o -name "card*.jpg" \) | sort | head -5 | while read img; do
        echo "   - $img"
    done
fi
echo ""

# 2. 检查数据库连接
echo "📊 步骤2: 检查数据库连接"
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库容器未运行"
    echo "   请先启动数据库: ./start_db.sh"
    exit 1
fi

if ! docker exec h5project_db psql -U h5user -d h5project -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ 数据库连接失败"
    echo "   请先启动数据库: ./start_db.sh"
    exit 1
fi
echo "✅ 数据库连接正常"
echo ""

# 3. 检查数据库中的卡片数量
echo "📋 步骤3: 检查数据库中的卡片数据"
CARD_COUNT=$(docker exec h5project_db psql -U h5user -d h5project -t -c "SELECT COUNT(*) FROM cards;" 2>/dev/null | tr -d ' ')

if [ -z "$CARD_COUNT" ] || [ "$CARD_COUNT" = "0" ]; then
    echo "⚠️  数据库中没有任何卡片数据"
    echo "   请运行: ./scripts/init_local.sh 导入图片到数据库"
else
    echo "✅ 数据库中有 $CARD_COUNT 张卡片"
    echo ""
    echo "   前5张卡片的路径："
    docker exec h5project_db psql -U h5user -d h5project -t -c "SELECT name, image_url FROM cards ORDER BY id LIMIT 5;" 2>/dev/null | while read line; do
        if [ -n "$line" ]; then
            echo "   $line"
        fi
    done
fi
echo ""

# 4. 检查服务器是否运行
echo "🌐 步骤4: 检查服务器状态"
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ 服务器正在运行（端口8080）"
    
    # 测试图片访问
    echo ""
    echo "🔗 步骤5: 测试图片访问"
    TEST_IMAGE="/images/card001.png"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080$TEST_IMAGE" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ 图片可以正常访问: http://localhost:8080$TEST_IMAGE"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⚠️  图片访问返回404: http://localhost:8080$TEST_IMAGE"
        echo "   可能原因："
        echo "   1. 图片文件不存在: images/card001.png"
        echo "   2. 服务器配置问题"
    else
        echo "⚠️  图片访问返回HTTP $HTTP_CODE"
    fi
else
    echo "⚠️  服务器未运行"
    echo "   请先启动服务器: ./dev.sh"
fi
echo ""

# 总结
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 诊断总结："
echo ""

if [ "$CARD_COUNT" = "0" ]; then
    echo "❌ 问题：数据库中没有卡片数据"
    echo "   解决方案：运行 ./scripts/init_local.sh"
elif [ "$IMAGE_COUNT" = "0" ]; then
    echo "❌ 问题：images目录中没有图片文件"
    echo "   解决方案：确保images目录下有card*.png或card*.jpg文件"
else
    echo "✅ 配置看起来正常"
    echo "   如果图片仍然不显示，请检查："
    echo "   1. 浏览器控制台是否有错误"
    echo "   2. 网络请求是否成功（F12 -> Network）"
    echo "   3. 图片路径是否正确（应该是 /images/card001.png 格式）"
fi
echo ""

