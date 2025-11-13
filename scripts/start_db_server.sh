#!/bin/bash
# 在服务器上启动数据库
# 使用方法: ./scripts/start_db_server.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🗄️  启动数据库..."
echo ""

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未检测到Docker"
    echo "   请先安装Docker: yum install -y docker"
    exit 1
fi

# 启动Docker服务（如果未运行）
if ! systemctl is-active --quiet docker 2>/dev/null; then
    echo "启动Docker服务..."
    systemctl start docker
    sleep 2
fi

# 检查数据库是否已在运行
if docker ps | grep -q h5project_db; then
    echo "✅ 数据库已在运行"
    docker ps | grep h5project_db
    exit 0
fi

# 启动数据库
echo "启动PostgreSQL数据库..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f deploy/docker-compose.prod.yml up -d
elif docker compose version &> /dev/null; then
    docker compose -f deploy/docker-compose.prod.yml up -d
else
    echo "❌ 错误: 未找到docker-compose或docker compose命令"
    echo ""
    echo "解决方案："
    echo "1. 安装docker-compose:"
    echo "   yum install -y docker-compose"
    echo ""
    echo "2. 或者使用新版本Docker（自带docker compose）"
    echo "   检查: docker compose version"
    exit 1
fi

echo "⏳ 等待数据库启动..."
sleep 5

# 检查数据库状态
if docker ps | grep -q h5project_db; then
    echo "✅ 数据库启动成功"
    echo ""
    echo "📋 数据库信息:"
    docker ps | grep h5project_db
    echo ""
    echo "📋 查看日志:"
    echo "   docker logs h5project_db"
    echo ""
    echo "📋 停止数据库:"
    echo "   docker-compose -f deploy/docker-compose.prod.yml down"
    echo "   或: docker compose -f deploy/docker-compose.prod.yml down"
else
    echo "❌ 数据库启动失败"
    echo "查看日志: docker logs h5project_db"
    exit 1
fi

