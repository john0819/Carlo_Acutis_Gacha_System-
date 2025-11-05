#!/bin/bash
# 停止所有服务

echo "🛑 正在停止服务..."

# 停止 ngrok
if pgrep -f "ngrok http" > /dev/null; then
    pkill -f "ngrok http"
    echo "✅ 已停止 ngrok"
else
    echo "ℹ️  ngrok 未运行"
fi

# 停止 Go 服务器
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    pkill -f "main.go"
    echo "✅ 已停止服务器"
else
    echo "ℹ️  服务器未运行"
fi

echo ""
echo "✅ 所有服务已停止"

