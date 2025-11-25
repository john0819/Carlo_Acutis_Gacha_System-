#!/bin/bash
# 快速查看系统使用情况统计

DB_CONTAINER="h5project_db"
DB_USER="h5user"
DB_NAME="h5project"

# 检查Docker容器是否运行
if ! docker ps | grep -q "$DB_CONTAINER"; then
    echo "❌ 数据库容器未运行"
    exit 1
fi

echo "📊 系统使用情况统计"
echo "===================="
echo ""

# 1. 总用户数
echo "👥 用户统计:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "
SELECT 
    '总注册用户: ' || COUNT(*) || ' | 今日新增: ' || COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END)
FROM users;
"
echo ""

# 2. 今日打卡
echo "📅 今日打卡:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "
SELECT 
    '打卡人数: ' || COUNT(DISTINCT user_id) || ' | 打卡次数: ' || COUNT(*) || ' | 新卡: ' || COUNT(CASE WHEN is_new_card THEN 1 END)
FROM daily_draws
WHERE draw_date = CURRENT_DATE;
"
echo ""

# 3. 最近7天打卡趋势
echo "📈 最近7天打卡趋势:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
SELECT 
    draw_date as 日期,
    COUNT(DISTINCT user_id) as 打卡人数,
    COUNT(*) as 打卡次数
FROM daily_draws
WHERE draw_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY draw_date
ORDER BY draw_date DESC;
"
echo ""

# 4. 卡片收集情况
echo "🎴 卡片收集:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "
SELECT 
    '总卡片数: ' || COUNT(DISTINCT c.id) || ' | 已收集: ' || COUNT(DISTINCT uc.card_id) || ' | 收集用户: ' || COUNT(DISTINCT uc.user_id)
FROM cards c
LEFT JOIN user_cards uc ON c.id = uc.card_id;
"
echo ""

# 5. 成就统计
echo "🏆 成就解锁:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
SELECT 
    at.name as 成就名称,
    COUNT(ua.user_id) as 解锁人数,
    COUNT(CASE WHEN ua.claimed_at IS NOT NULL THEN 1 END) as 已领取
FROM achievement_types at
LEFT JOIN user_achievements ua ON at.id = ua.achievement_type_id
GROUP BY at.id, at.name
ORDER BY 解锁人数 DESC
LIMIT 5;
"
echo ""

# 6. 兑换统计
echo "🎁 兑换统计:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -t -c "
SELECT 
    '本月兑换: ' || COUNT(*) || ' (基础: ' || COUNT(CASE WHEN redemption_type = 'basic' THEN 1 END) || ' | 高级: ' || COUNT(CASE WHEN redemption_type = 'premium' THEN 1 END) || ')'
FROM redemption_records
WHERE redemption_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM');
"
echo ""

# 7. 活跃用户Top 10
echo "⭐ 活跃用户Top 10:"
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
SELECT 
    u.username as 用户名,
    COUNT(DISTINCT dd.draw_date) as 打卡天数,
    COUNT(DISTINCT uc.card_id) as 卡片数
FROM users u
LEFT JOIN daily_draws dd ON u.id = dd.user_id
LEFT JOIN user_cards uc ON u.id = uc.user_id
GROUP BY u.id, u.username
ORDER BY 打卡天数 DESC, 卡片数 DESC
LIMIT 10;
"
echo ""

echo "✅ 统计完成！"
echo ""
echo "💡 提示: 查看详细统计请运行:"
echo "   docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -f /path/to/view_statistics.sql"
