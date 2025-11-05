#!/bin/bash
# 开发模式启动脚本 - 显示实时日志

cd "$(dirname "$0")"

echo "🔧 开发模式启动"
echo "================================"
echo ""

# 检查数据库
if ! docker ps | grep -q h5project_db; then
    echo "⚠️  数据库未运行，正在启动..."
    ./start_db.sh
    sleep 3
fi

# 检查依赖
if [ ! -f "go.sum" ]; then
    echo "📦 下载依赖..."
    go mod download
    go mod tidy
fi

# 停止旧进程
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🛑 停止旧服务器..."
    pkill -f "main.go"
    sleep 1
    # 如果还在运行，通过端口强制停止
    PID=$(lsof -ti :8080 2>/dev/null)
    if [ -n "$PID" ]; then
        kill $PID 2>/dev/null
        sleep 1
        if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
            kill -9 $PID 2>/dev/null
        fi
    fi
    sleep 1
fi

echo "🚀 启动服务器（前台运行，显示实时日志）..."
echo "📝 按 Ctrl+C 停止服务器"
echo ""
echo "═══════════════════════════════════════════════════"
echo ""

# 前台运行，显示实时日志
go run main.go

