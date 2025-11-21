#!/bin/bash
# 快速切换位置校验开关
# 使用方法: ./scripts/toggle_location.sh [on|off]
# 如果不带参数，则切换当前状态

echo "🔄 位置校验开关管理..."

# 检查Docker容器是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库容器未运行"
    exit 1
fi

CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -E "(db|postgres|h5project)" | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ 未找到数据库容器"
    exit 1
fi

# 获取当前状态
CURRENT=$(docker exec $CONTAINER_NAME psql -U h5user -d h5project -t -c "SELECT value FROM system_config WHERE key = 'location_check_enabled';" | tr -d ' ')

if [ -z "$1" ]; then
    # 没有参数，切换状态
    if [ "$CURRENT" = "true" ]; then
        NEW_STATE="false"
        ACTION="关闭"
    else
        NEW_STATE="true"
        ACTION="开启"
    fi
else
    # 有参数，使用指定状态
    if [ "$1" = "on" ] || [ "$1" = "true" ] || [ "$1" = "1" ]; then
        NEW_STATE="true"
        ACTION="开启"
    elif [ "$1" = "off" ] || [ "$1" = "false" ] || [ "$1" = "0" ]; then
        NEW_STATE="false"
        ACTION="关闭"
    else
        echo "❌ 无效的参数。使用方法: ./scripts/toggle_location.sh [on|off]"
        exit 1
    fi
fi

# 更新状态
docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "UPDATE system_config SET value = '$NEW_STATE' WHERE key = 'location_check_enabled';" > /dev/null

echo "✅ 位置校验已${ACTION}"
echo ""
echo "当前状态: $NEW_STATE"
if [ "$NEW_STATE" = "true" ]; then
    echo "📍 用户必须在指定地点范围内才能打卡"
else
    echo "🔓 测试模式：不进行位置校验"
fi
echo ""
echo "💡 提示：刷新页面后生效"

