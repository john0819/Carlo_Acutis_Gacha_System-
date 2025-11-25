#!/bin/bash

# 月活跃用户（MAU）统计查询脚本
# 用于快速查看月活数据

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}月活跃用户（MAU）统计${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Docker 容器是否存在
if ! docker ps -a | grep -q h5project_db; then
    echo -e "${YELLOW}错误: 找不到 h5project_db 容器${NC}"
    echo -e "${YELLOW}请先启动 Docker 容器${NC}"
    exit 1
fi

# 检查容器是否运行
if ! docker ps | grep -q h5project_db; then
    echo -e "${YELLOW}警告: h5project_db 容器未运行，正在启动...${NC}"
    docker start h5project_db
    sleep 2
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 显示菜单
echo ""
echo -e "${BLUE}请选择查询类型:${NC}"
echo "1. 当前月份月活（快速查询）"
echo "2. 最近12个月月活趋势"
echo "3. 用户活跃度分级（最近30天）"
echo "4. 用户留存分析"
echo "5. 活跃用户行为分析（Top 50）"
echo "6. 本月 vs 上月对比"
echo "7. 执行完整统计（所有查询）"
echo ""
read -p "请输入选项 (1-7): " choice

case $choice in
    1)
        echo -e "\n${GREEN}当前月份月活统计:${NC}"
        docker exec h5project_db psql -U h5user -d h5project -c "
        SELECT 
            TO_CHAR(CURRENT_DATE, 'YYYY-MM') as 月份,
            COUNT(DISTINCT active_users.user_id) as 月活用户数,
            (SELECT COUNT(*) FROM users) as 总注册用户数,
            ROUND(COUNT(DISTINCT active_users.user_id) * 100.0 / NULLIF((SELECT COUNT(*) FROM users), 0), 2) as 活跃率百分比
        FROM (
            SELECT DISTINCT user_id FROM daily_draws 
            WHERE draw_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE
            UNION
            SELECT DISTINCT user_id FROM location_checkins 
            WHERE checkin_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE
            UNION
            SELECT DISTINCT user_id FROM redemption_records 
            WHERE redemption_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM')
            UNION
            SELECT DISTINCT user_id FROM user_achievements 
            WHERE unlocked_at >= DATE_TRUNC('month', CURRENT_DATE)
            UNION
            SELECT DISTINCT user_id FROM user_cards 
            WHERE obtained_at >= DATE_TRUNC('month', CURRENT_DATE)
        ) active_users;
        "
        ;;
    2)
        echo -e "\n${GREEN}最近12个月月活趋势:${NC}"
        docker exec h5project_db psql -U h5user -d h5project -f "$ROOT_DIR/scripts/monthly_active_users.sql" | grep -A 20 "最近12个月的月活趋势"
        ;;
    3)
        echo -e "\n${GREEN}用户活跃度分级:${NC}"
        docker exec h5project_db psql -U h5user -d h5project -f "$ROOT_DIR/scripts/monthly_active_users.sql" | grep -A 10 "用户活跃度分级"
        ;;
    4)
        echo -e "\n${GREEN}用户留存分析:${NC}"
        docker exec h5project_db psql -U h5user -d h5project -f "$ROOT_DIR/scripts/monthly_active_users.sql" | grep -A 15 "用户留存分析"
        ;;
    5)
        echo -e "\n${GREEN}活跃用户行为分析（Top 50）:${NC}"
        docker exec h5project_db psql -U h5user -d h5project -f "$ROOT_DIR/scripts/monthly_active_users.sql" | grep -A 55 "活跃用户行为分析"
        ;;
    6)
        echo -e "\n${GREEN}本月 vs 上月对比:${NC}"
        docker exec h5project_db psql -U h5user -d h5project -f "$ROOT_DIR/scripts/monthly_active_users.sql" | grep -A 5 "本月 vs 上月"
        ;;
    7)
        echo -e "\n${GREEN}执行完整月活统计...${NC}"
        docker exec -i h5project_db psql -U h5user -d h5project < "$ROOT_DIR/scripts/monthly_active_users.sql"
        ;;
    *)
        echo -e "${YELLOW}无效选项${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}查询完成！${NC}"

