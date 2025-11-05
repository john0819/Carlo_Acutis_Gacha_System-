#!/bin/bash
# 完整启动脚本：数据库 + 服务器

cd "$(dirname "$0")"

echo "🚀 启动抽卡WebApp"
echo "================================"
echo ""

# 1. 启动数据库
echo "📊 步骤1: 启动数据库"
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if docker ps | grep -q h5project_db; then
    echo "✅ 数据库已在运行"
else
    echo "启动数据库..."
    docker-compose up -d
    echo "⏳ 等待数据库就绪..."
    sleep 5
    echo "✅ 数据库已启动"
fi

# 2. 检查依赖
echo ""
echo "📦 步骤2: 检查Go依赖"
if [ ! -f "go.sum" ]; then
    echo "下载依赖..."
    go mod download
    go mod tidy
fi

# 3. 启动服务器
echo ""
echo "🌐 步骤3: 启动服务器"
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ 服务器已在运行（端口 8080）"
else
    echo "启动服务器..."
    go run main.go > server.log 2>&1 &
    sleep 2
    echo "✅ 服务器已启动"
fi

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ 启动完成！"
echo ""
echo "📱 访问地址:"
echo "   登录页面: http://localhost:8080/login.html"
echo "   主页: http://localhost:8080/index.html"
echo ""
echo "🛑 停止服务: ./stop.sh"
echo "═══════════════════════════════════════════════════"

