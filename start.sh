#!/bin/bash
# 启动服务器和内网穿透（公网访问）

cd "$(dirname "$0")"

echo "🚀 启动 H5 服务器和内网穿透"
echo "================================"
echo ""

# 1. 检查并启动数据库
echo "📊 步骤1: 检查数据库"
if ! docker ps | grep -q h5project_db; then
    echo "启动数据库..."
    ./start_db.sh
    sleep 3
fi
echo "✅ 数据库运行中"

# 2. 检查Go依赖
if [ ! -f "go.sum" ]; then
    echo "📦 下载依赖..."
    go mod download
    go mod tidy
fi

# 3. 检查并启动服务器
echo ""
echo "🌐 步骤2: 启动服务器"
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ 服务器已在运行（端口 8080）"
else
    echo "启动服务器..."
    go run main.go > server.log 2>&1 &
    sleep 2
    echo "✅ 服务器已启动"
fi

# 4. 检查并启动 ngrok
echo ""
echo "🌐 步骤3: 启动内网穿透"
if ! pgrep -f "ngrok http" > /dev/null; then
    echo "启动 ngrok..."
    ngrok http 8080 > ngrok.log 2>&1 &
    sleep 4
    echo "✅ ngrok 已启动"
else
    echo "✅ ngrok 已在运行"
fi

# 5. 获取公网地址
echo ""
echo "📱 步骤4: 获取公网地址..."
sleep 2

PUBLIC_URL=""
for i in {1..5}; do
    sleep 1
    API_RESPONSE=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
    
    if [ -n "$API_RESPONSE" ]; then
        # 方法1: 使用 grep
        PUBLIC_URL=$(echo "$API_RESPONSE" | grep -o 'https://[^"]*\.ngrok[^"]*' | head -1)
        
        # 方法2: 如果grep失败，尝试python
        if [ -z "$PUBLIC_URL" ]; then
            PUBLIC_URL=$(echo "$API_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        url = tunnel.get('public_url', '')
        if 'https' in url:
            print(url)
            break
except:
    pass
" 2>/dev/null)
        fi
        
        if [ -n "$PUBLIC_URL" ]; then
            break
        fi
    fi
done

echo ""
if [ -n "$PUBLIC_URL" ]; then
    FULL_URL="${PUBLIC_URL}/login.html"
    echo "═══════════════════════════════════════════════════"
    echo "✅ 启动成功！"
    echo ""
    echo "🌐 公网访问地址："
    echo "   $FULL_URL"
    echo ""
    echo "📱 生成二维码："
    echo "   运行: open generate_qrcode.html"
    echo "   或手动打开: generate_qrcode.html"
    echo ""
    echo "🌐 ngrok 控制台: http://localhost:4040"
    echo "🛑 停止服务: ./stop.sh"
    echo "═══════════════════════════════════════════════════"
    
    # 自动更新二维码页面的地址
    if [ -f "generate_qrcode.html" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|value=\"https://[^\"]*\"|value=\"$FULL_URL\"|g" generate_qrcode.html
        else
            sed -i "s|value=\"https://[^\"]*\"|value=\"$FULL_URL\"|g" generate_qrcode.html
        fi
        echo "✅ 已更新二维码页面地址"
    fi
    
    # 自动打开二维码页面
    sleep 1
    open generate_qrcode.html 2>/dev/null || echo "💡 请手动打开 generate_qrcode.html"
else
    echo "⚠️  无法自动获取地址"
    echo ""
    echo "请访问 ngrok 控制台查看: http://localhost:4040"
    echo "或查看日志: tail -f ngrok.log"
fi
