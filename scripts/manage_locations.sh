#!/bin/bash
# 打卡地点管理脚本
# 使用方法：
#   ./scripts/manage_locations.sh list                    # 列出所有地点
#   ./scripts/manage_locations.sh add <名称> <纬度> <经度> [半径] [成就代码]  # 添加地点
#   ./scripts/manage_locations.sh update <ID> <名称> <纬度> <经度> [半径] [成就代码]  # 更新地点
#   ./scripts/manage_locations.sh delete <ID>            # 删除地点

ACTION=$1

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

case "$ACTION" in
    list)
        echo "📍 当前所有打卡地点："
        echo ""
        docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations ORDER BY id;" -t
        ;;
    add)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "❌ 用法: ./scripts/manage_locations.sh add <名称> <纬度> <经度> [半径(默认500)] [成就代码]"
            echo "   示例: ./scripts/manage_locations.sh add '打卡点A' 26.123456 119.123456 500 location_a_15"
            exit 1
        fi
        
        NAME="$2"
        LAT="$3"
        LNG="$4"
        RADIUS="${5:-500}"
        ACHIEVEMENT="${6:-}"
        
        if [ -z "$ACHIEVEMENT" ]; then
            docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "INSERT INTO checkin_locations (name, latitude, longitude, radius_meters) VALUES ('$NAME', $LAT, $LNG, $RADIUS);"
        else
            docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES ('$NAME', $LAT, $LNG, $RADIUS, '$ACHIEVEMENT');"
        fi
        
        echo "✅ 已添加打卡地点: $NAME"
        ;;
    update)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
            echo "❌ 用法: ./scripts/manage_locations.sh update <ID> <名称> <纬度> <经度> [半径] [成就代码]"
            echo "   示例: ./scripts/manage_locations.sh update 1 '打卡点A' 26.123456 119.123456 500 location_a_15"
            exit 1
        fi
        
        ID="$2"
        NAME="$3"
        LAT="$4"
        LNG="$5"
        RADIUS="${6:-500}"
        ACHIEVEMENT="${7:-}"
        
        if [ -z "$ACHIEVEMENT" ]; then
            docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "UPDATE checkin_locations SET name='$NAME', latitude=$LAT, longitude=$LNG, radius_meters=$RADIUS, achievement_code=NULL WHERE id=$ID;"
        else
            docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "UPDATE checkin_locations SET name='$NAME', latitude=$LAT, longitude=$LNG, radius_meters=$RADIUS, achievement_code='$ACHIEVEMENT' WHERE id=$ID;"
        fi
        
        echo "✅ 已更新打卡地点 ID=$ID: $NAME"
        ;;
    delete)
        if [ -z "$2" ]; then
            echo "❌ 用法: ./scripts/manage_locations.sh delete <ID>"
            exit 1
        fi
        
        ID="$2"
        
        # 确认删除
        read -p "⚠️  确定要删除地点 ID=$ID 吗？这将删除所有相关的打卡记录！(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker exec $CONTAINER_NAME psql -U h5user -d h5project -c "DELETE FROM checkin_locations WHERE id=$ID;"
            echo "✅ 已删除打卡地点 ID=$ID"
        else
            echo "❌ 已取消删除"
        fi
        ;;
    *)
        echo "📍 打卡地点管理工具"
        echo ""
        echo "使用方法："
        echo "  ./scripts/manage_locations.sh list                                    # 列出所有地点"
        echo "  ./scripts/manage_locations.sh add <名称> <纬度> <经度> [半径] [成就代码]"
        echo "  ./scripts/manage_locations.sh update <ID> <名称> <纬度> <经度> [半径] [成就代码]"
        echo "  ./scripts/manage_locations.sh delete <ID>"
        echo ""
        echo "示例："
        echo "  # 列出所有地点"
        echo "  ./scripts/manage_locations.sh list"
        echo ""
        echo "  # 添加新地点"
        echo "  ./scripts/manage_locations.sh add '罗源南门堂' 26.123456 119.123456 500 location_a_15"
        echo ""
        echo "  # 更新地点（ID=1）"
        echo "  ./scripts/manage_locations.sh update 1 '罗源南门堂' 26.123456 119.123456 500 location_a_15"
        echo ""
        echo "  # 删除地点（ID=1）"
        echo "  ./scripts/manage_locations.sh delete 1"
        echo ""
        echo "如何获取经纬度："
        echo "  1. 百度地图：https://lbsyun.baidu.com/jsdemo.htm#a5_2"
        echo "  2. 高德地图：打开地图，右键点击地点，选择'获取坐标'"
        echo "  3. Google Maps：右键点击地点，选择坐标"
        ;;
esac

