#!/bin/bash
# 更新位置校验开关设置
# 使用方法: 
#   ./scripts/update_location_setting.sh true   # 启用位置校验
#   ./scripts/update_location_setting.sh false  # 禁用位置校验（测试模式）
#   ./scripts/update_location_setting.sh on     # 启用（简写）
#   ./scripts/update_location_setting.sh off    # 禁用（简写）

ENABLED=${1:-false}

# 支持简写形式
if [ "$ENABLED" = "on" ] || [ "$ENABLED" = "1" ]; then
    ENABLED="true"
elif [ "$ENABLED" = "off" ] || [ "$ENABLED" = "0" ]; then
    ENABLED="false"
fi

echo "🔄 更新位置校验设置..."

# 检查Docker容器是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库容器未运行"
    echo "💡 提示: 请先启动数据库容器"
    exit 1
fi

CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -E "(db|postgres|h5project)" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ 未找到数据库容器"
    exit 1
fi

echo "📦 找到数据库容器: $CONTAINER_NAME"

# 更新设置
docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "UPDATE system_config SET value = '$ENABLED' WHERE key = 'location_check_enabled';" > /dev/null

# 验证更新
VERIFY=$(docker exec $CONTAINER_NAME psql -U h5user -d h5project -t -c "SELECT value FROM system_config WHERE key = 'location_check_enabled';" | tr -d ' ')
docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "SELECT key, value, description FROM system_config WHERE key = 'location_check_enabled';"

echo ""
if [ "$ENABLED" = "true" ]; then
    echo "✅ 位置校验已启用"
    echo "📍 用户必须在指定地点范围内才能打卡"
else
    echo "✅ 位置校验已禁用（测试模式）"
    echo "🔓 不进行位置校验，可以在任何地点打卡"
fi
echo ""
echo "💡 提示: 刷新页面后生效"

