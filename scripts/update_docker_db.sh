#!/bin/bash
# 更新Docker部署的数据库中的成就名称
# 使用方法: ./scripts/update_docker_db.sh

echo "🔄 开始更新数据库成就名称..."

# 检查Docker容器是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库容器未运行"
    echo "   请先启动数据库: docker-compose up -d 或 ./start_db.sh"
    exit 1
fi

# 获取容器名称（假设容器名包含db或postgres）
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -E "(db|postgres|h5project)" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ 未找到数据库容器"
    exit 1
fi

echo "📦 找到数据库容器: $CONTAINER_NAME"

# 检查数据库类型（PostgreSQL或MySQL）
DB_TYPE=$(docker exec $CONTAINER_NAME sh -c "command -v psql > /dev/null && echo 'postgres' || echo 'mysql'")

if [ "$DB_TYPE" = "postgres" ]; then
    echo "✅ 检测到 PostgreSQL 数据库"
    
    # 执行PostgreSQL更新脚本
    docker exec -i $CONTAINER_NAME psql -U h5user -d h5project < scripts/update_achievement_names.sql
    
    if [ $? -eq 0 ]; then
        echo "✅ 成就名称更新成功！"
    else
        echo "❌ 更新失败，请检查错误信息"
        exit 1
    fi
else
    echo "✅ 检测到 MySQL 数据库"
    
    # MySQL版本的更新SQL
    docker exec -i $CONTAINER_NAME mysql -u h5user -ph5pass123 h5project << 'EOF'
UPDATE achievement_types SET 
    name = '一点星星之光', 
    description = '获得任意第一张卡牌 (实体或数字)', 
    reward_points = 1 
WHERE code = 'first_card';

UPDATE achievement_types SET 
    name = '朝圣新星', 
    description = '累计在 3 个不同的教堂打卡成功', 
    reward_points = 1 
WHERE code = 'pilgrim_nova';

UPDATE achievement_types SET 
    name = '收集天上的宝藏', 
    description = '每 7 张不同卡片就会点亮一次', 
    reward_points = 1 
WHERE code = 'milestone_7';

INSERT INTO achievement_types (code, name, description, reward_points) VALUES
    ('complete_all', '圣卡洛的圣体奇迹集', '集齐所有打卡图片', 3)
ON DUPLICATE KEY UPDATE 
    name = VALUES(name),
    description = VALUES(description),
    reward_points = VALUES(reward_points);

SELECT code, name, description, reward_points FROM achievement_types ORDER BY id;
EOF

    if [ $? -eq 0 ]; then
        echo "✅ 成就名称更新成功！"
    else
        echo "❌ 更新失败，请检查错误信息"
        exit 1
    fi
fi

echo ""
echo "📋 更新后的成就列表："
if [ "$DB_TYPE" = "postgres" ]; then
    docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "SELECT code, name, description, reward_points FROM achievement_types ORDER BY id;"
else
    docker exec $CONTAINER_NAME mysql -u h5user -ph5pass123 h5project -e "SELECT code, name, description, reward_points FROM achievement_types ORDER BY id;"
fi

echo ""
echo "✨ 完成！请刷新页面查看更新后的成就名称。"

