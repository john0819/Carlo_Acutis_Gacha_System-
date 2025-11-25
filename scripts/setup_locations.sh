#!/bin/bash

# 定位功能一键部署脚本
# 用于在云主机上重新 git clone 后设置定位相关配置

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}定位功能配置脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Docker 容器是否存在
if ! docker ps -a | grep -q h5project_db; then
    echo -e "${RED}错误: 找不到 h5project_db 容器${NC}"
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

echo -e "\n${GREEN}步骤1: 更新教堂定位坐标...${NC}"
docker exec -i h5project_db psql -U h5user -d h5project < "$ROOT_DIR/scripts/update_church_locations.sql"
echo -e "${GREEN}✓ 教堂定位坐标更新完成${NC}"

echo -e "\n${GREEN}步骤2: 更新成就描述...${NC}"
docker exec -i h5project_db psql -U h5user -d h5project < "$ROOT_DIR/scripts/update_achievement_descriptions.sql"
echo -e "${GREEN}✓ 成就描述更新完成${NC}"

echo -e "\n${GREEN}步骤3: 清理测试地点（可选）...${NC}"
echo -e "${YELLOW}注意: 测试地点的插入已被注释，如需添加请编辑 manage_test_location.sql${NC}"
docker exec -i h5project_db psql -U h5user -d h5project < "$ROOT_DIR/scripts/manage_test_location.sql"
echo -e "${GREEN}✓ 测试地点管理完成${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}配置完成！${NC}"
echo -e "${GREEN}========================================${NC}"

# 显示最终结果
echo -e "\n${GREEN}当前所有打卡地点:${NC}"
docker exec h5project_db psql -U h5user -d h5project -c "
SELECT 
    id,
    name,
    latitude as 纬度,
    longitude as 经度,
    radius_meters as 半径米,
    achievement_code as 成就代码,
    CASE 
        WHEN achievement_code IS NULL THEN '测试位置（隐藏）' 
        ELSE '正式地点（显示）' 
    END as 类型
FROM checkin_locations
ORDER BY achievement_code NULLS LAST, id;
"

echo -e "\n${GREEN}当前定位相关成就:${NC}"
docker exec h5project_db psql -U h5user -d h5project -c "
SELECT code, name, description, reward_points 
FROM achievement_types 
WHERE code LIKE 'location_%'
ORDER BY code;
"

