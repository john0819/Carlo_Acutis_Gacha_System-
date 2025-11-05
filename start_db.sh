#!/bin/bash
# 启动数据库

echo "🐳 启动 PostgreSQL 数据库..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查是否已在运行
if docker ps | grep -q h5project_db; then
    echo "✅ 数据库已在运行"
else
    docker-compose up -d
    echo "✅ 数据库启动中..."
    echo "⏳ 等待数据库就绪..."
    sleep 5
fi

echo "✅ 数据库已就绪"
echo "📊 数据库信息:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   User: h5user"
echo "   Password: h5pass123"
echo "   Database: h5project"

