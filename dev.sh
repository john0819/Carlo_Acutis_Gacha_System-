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

# 停止旧进程（仅停止8081端口的开发服务器）
if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "🛑 停止旧开发服务器..."
    PID=$(lsof -ti :8081 2>/dev/null)
    if [ -n "$PID" ]; then
        kill $PID 2>/dev/null
        sleep 1
        if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
            kill -9 $PID 2>/dev/null
        fi
    fi
    sleep 1
fi

echo "🚀 启动开发服务器（端口8081，前台运行，显示实时日志）..."
echo "📝 按 Ctrl+C 停止服务器"
echo "🌐 开发地址: http://localhost:8081"
echo ""
echo "═══════════════════════════════════════════════════"
echo ""

# 设置环境变量指定端口，前台运行，显示实时日志
PORT=8081 go run main.go

