#!/bin/bash
# 启动服务器和内网穿透（公网访问）+ 自动生成二维码
# 使用方法: ./start_with_tunnel.sh [ngrok|cloudflare]

cd "$(dirname "$0")"

TUNNEL_TYPE=${1:-ngrok}  # 默认使用ngrok

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

# 4. 启动内网穿透
echo ""
echo "🌐 步骤3: 启动内网穿透 ($TUNNEL_TYPE)"
if [ "$TUNNEL_TYPE" = "cloudflare" ]; then
    # 使用 Cloudflare Tunnel
    if ! command -v cloudflared &> /dev/null; then
        echo "❌ cloudflared 未安装"
        echo "   安装方法: brew install cloudflared"
        exit 1
    fi
    
    echo "启动 Cloudflare Tunnel..."
    cloudflared tunnel --url http://localhost:8080 > cloudflare.log 2>&1 &
    TUNNEL_PID=$!
    sleep 4
    
    # 从日志中提取公网地址
    PUBLIC_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' cloudflare.log 2>/dev/null | head -1)
    
elif [ "$TUNNEL_TYPE" = "ngrok" ]; then
    # 使用 ngrok
    if ! command -v ngrok &> /dev/null; then
        echo "❌ ngrok 未安装"
        echo "   安装方法: brew install ngrok/ngrok/ngrok"
        echo "   首次使用需要配置token: ngrok config add-authtoken YOUR_TOKEN"
        exit 1
    fi
    
    echo "启动 ngrok..."
    ngrok http 8080 > ngrok.log 2>&1 &
    TUNNEL_PID=$!
    sleep 4
    
    # 从ngrok API获取公网地址
    PUBLIC_URL=""
    for i in {1..10}; do
        sleep 1
        API_RESPONSE=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
        
        if [ -n "$API_RESPONSE" ]; then
            # 尝试使用grep提取
            PUBLIC_URL=$(echo "$API_RESPONSE" | grep -o 'https://[^"]*\.ngrok[^"]*' | head -1)
            
            # 如果grep失败，尝试使用python
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
else
    echo "❌ 错误: 不支持的内网穿透类型: $TUNNEL_TYPE"
    echo "   支持的类型: ngrok, cloudflare"
    exit 1
fi

# 5. 显示结果
echo ""
echo "═══════════════════════════════════════════════════"
if [ -n "$PUBLIC_URL" ]; then
    LOGIN_URL="${PUBLIC_URL}/login.html"
    QRCODE_URL="${PUBLIC_URL}/qrcode.html?url=${LOGIN_URL}"
    
    echo "✅ 启动完成！"
    echo ""
    echo "📱 公网访问地址:"
    echo "   登录页面: $LOGIN_URL"
    echo "   主页: ${PUBLIC_URL}/index.html"
    echo ""
    echo "📱 生成二维码:"
    echo "   方式1: 访问 $QRCODE_URL"
    echo "   方式2: 访问 ${PUBLIC_URL}/qrcode.html 然后输入地址"
    echo ""
    echo "💡 提示:"
    echo "   - 二维码生成页面会自动检测当前公网地址"
    echo "   - 也可以手动访问 ${PUBLIC_URL}/qrcode.html 生成二维码"
    echo ""
    
    # 尝试自动打开二维码页面（macOS）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🌐 正在打开二维码生成页面..."
        open "$QRCODE_URL" 2>/dev/null || echo "   请手动访问: $QRCODE_URL"
    fi
else
    echo "⚠️  无法获取公网地址"
    echo "   请手动查看日志:"
    if [ "$TUNNEL_TYPE" = "cloudflare" ]; then
        echo "   tail -f cloudflare.log"
    else
        echo "   tail -f ngrok.log"
        echo "   或访问: http://localhost:4040"
    fi
fi

echo ""
echo "🛑 停止服务: ./stop.sh"
echo "═══════════════════════════════════════════════════"

