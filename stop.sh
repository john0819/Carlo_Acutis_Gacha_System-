#!/bin/bash
# 停止所有服务

echo "🛑 正在停止服务..."
echo ""

# 停止 ngrok
if pgrep -f "ngrok http" > /dev/null; then
    pkill -f "ngrok http"
    sleep 1
    echo "✅ 已停止 ngrok"
else
    echo "ℹ️  ngrok 未运行"
fi

# 停止 Go 服务器（多种方式确保停止）
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    # 方式1: 通过进程名停止
    pkill -f "main.go"
    sleep 1
    
    # 方式2: 通过端口找到进程并停止
    PID=$(lsof -ti :8080 2>/dev/null)
    if [ -n "$PID" ]; then
        kill $PID 2>/dev/null
        sleep 1
        # 如果还在运行，强制停止
        if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
            kill -9 $PID 2>/dev/null
        fi
    fi
    
    # 验证是否停止
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  服务器仍在运行，尝试强制停止..."
        pkill -9 -f "main.go"
        lsof -ti :8080 2>/dev/null | xargs kill -9 2>/dev/null
    fi
    
    echo "✅ 已停止服务器"
else
    echo "ℹ️  服务器未运行"
fi

echo ""
echo "✅ 所有服务已停止"
echo ""
echo "💡 提示：数据库仍在运行（如需停止，运行: docker-compose stop）"
