#!/bin/bash
# 简化的启动脚本

cd "$(dirname "$0")"

echo "🚀 启动 H5 服务器和内网穿透"
echo ""

# 检查服务器
if ! lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "启动服务器..."
    go run main.go > server.log 2>&1 &
    sleep 2
fi
echo "✅ 服务器运行中"

# 检查并启动 ngrok
if ! pgrep -f "ngrok http" > /dev/null; then
    echo "启动 ngrok..."
    ngrok http 8080 > ngrok.log 2>&1 &
    sleep 4
fi

# 获取公网地址
echo ""
echo "获取公网地址..."
sleep 2

# 尝试多种方式获取地址
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
    FULL_URL="${PUBLIC_URL}/index.html"
    echo "═══════════════════════════════════════════════════"
    echo "✅ 成功！公网地址："
    echo "   $FULL_URL"
    echo ""
    echo "📱 下一步：打开二维码生成页面"
    echo "   运行: open generate_qrcode.html"
    echo "   或手动打开: generate_qrcode.html"
    echo ""
    echo "🌐 ngrok 控制台: http://localhost:4040"
    echo "🛑 停止服务: ./stop.sh"
    echo "═══════════════════════════════════════════════════"
    
    # 自动更新二维码页面的地址
    if [ -f "generate_qrcode.html" ]; then
        # 使用 sed 更新 HTML 中的默认地址（macOS 兼容）
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
    echo "请访问控制台查看: http://localhost:4040"
    echo "或查看日志: tail -f ngrok.log"
    echo ""
    echo "如果看到认证错误，请重新配置:"
    echo "  ngrok config add-authtoken 你的真实token"
fi

