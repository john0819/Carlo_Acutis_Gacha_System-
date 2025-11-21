#!/bin/bash
# 验证位置校验设置是否生效

echo "🔍 检查位置校验设置..."

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

echo "📦 数据库容器: $CONTAINER_NAME"
echo ""

# 检查数据库中的设置
echo "1️⃣ 数据库中的设置："
DB_VALUE=$(docker exec $CONTAINER_NAME psql -U h5user -d h5project -t -c "SELECT value FROM system_config WHERE key = 'location_check_enabled';" | tr -d ' ')
echo "   location_check_enabled = $DB_VALUE"

if [ "$DB_VALUE" = "true" ]; then
    echo "   ✅ 数据库设置：已启用"
else
    echo "   ❌ 数据库设置：未启用"
fi

echo ""

# 检查打卡地点
echo "2️⃣ 打卡地点配置："
docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations ORDER BY id;" -t

echo ""

# 检查服务器是否运行
echo "3️⃣ 服务器状态："
if pgrep -f "go run main.go" > /dev/null || pgrep -f "h5project" > /dev/null; then
    echo "   ✅ 服务器正在运行"
    echo ""
    echo "💡 提示："
    echo "   - 如果修改了数据库设置，需要刷新浏览器页面"
    echo "   - 如果修改了代码，需要重启服务器"
    echo ""
    echo "   重启服务器命令："
    echo "   - 停止：按 Ctrl+C 或 kill <进程ID>"
    echo "   - 启动：go run main.go"
else
    echo "   ⚠️  服务器未运行"
    echo ""
    echo "💡 提示：请先启动服务器"
fi

echo ""
echo "4️⃣ 测试建议："
echo "   - 打开浏览器控制台（F12）"
echo "   - 刷新页面，查看是否有 '📍 位置校验状态' 日志"
echo "   - 尝试打卡，查看是否请求位置权限"
echo "   - 如果位置校验已启用，不在指定地点应该会提示错误"

