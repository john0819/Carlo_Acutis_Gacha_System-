#!/bin/bash
# 一键初始化所有地点相关表和初始数据

echo "🔄 开始初始化打卡地点系统..."

# 检查Docker容器是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库容器未运行"
    echo "请先启动数据库容器：docker-compose up -d db"
    exit 1
fi

CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -E "(db|postgres|h5project)" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ 未找到数据库容器"
    exit 1
fi

echo "📦 找到数据库容器: $CONTAINER_NAME"
echo ""

# 步骤1: 创建表结构
echo "📋 步骤1: 创建数据库表..."
docker exec -i $CONTAINER_NAME psql -U h5user -d h5project < scripts/init_location_tables.sql
if [ $? -eq 0 ]; then
    echo "✅ 表结构创建成功"
else
    echo "❌ 表结构创建失败"
    exit 1
fi

echo ""

# 步骤2: 添加初始地点数据
echo "📍 步骤2: 添加初始打卡地点..."
docker exec -i $CONTAINER_NAME psql -U h5user -d h5project < scripts/add_initial_locations.sql
if [ $? -eq 0 ]; then
    echo "✅ 初始地点添加成功"
else
    echo "❌ 初始地点添加失败"
    exit 1
fi

echo ""
echo "🎉 初始化完成！"
echo ""
echo "📍 当前所有打卡地点："
docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations ORDER BY id;" -t

