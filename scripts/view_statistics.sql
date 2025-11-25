-- 系统使用情况统计查询脚本
-- 使用现有数据库表，无需新增表

-- ==================== 1. 用户统计 ====================
-- 总注册用户数
SELECT 
    '总注册用户数' as 统计项,
    COUNT(*) as 数量,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as 今日新增
FROM users;

-- 用户注册趋势（最近30天）
SELECT 
    DATE(created_at) as 日期,
    COUNT(*) as 注册人数,
    SUM(COUNT(*)) OVER (ORDER BY DATE(created_at)) as 累计注册数
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY 日期 DESC;

-- ==================== 2. 打卡统计 ====================
-- 每日打卡次数统计（最近30天）
SELECT 
    draw_date as 日期,
    COUNT(DISTINCT user_id) as 打卡人数,
    COUNT(*) as 打卡次数,
    COUNT(CASE WHEN is_new_card THEN 1 END) as 新卡次数,
    COUNT(CASE WHEN NOT is_new_card THEN 1 END) as 重复卡次数
FROM daily_draws
WHERE draw_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY draw_date
ORDER BY draw_date DESC;

-- 今日打卡情况
SELECT 
    '今日打卡' as 统计项,
    COUNT(DISTINCT user_id) as 打卡人数,
    COUNT(*) as 打卡次数,
    COUNT(CASE WHEN is_new_card THEN 1 END) as 新卡次数
FROM daily_draws
WHERE draw_date = CURRENT_DATE;

-- 累计打卡统计
SELECT 
    '累计打卡统计' as 统计项,
    COUNT(DISTINCT user_id) as 有打卡记录的用户数,
    COUNT(DISTINCT draw_date) as 有打卡记录的天数,
    COUNT(*) as 总打卡次数,
    COUNT(CASE WHEN is_new_card THEN 1 END) as 总新卡次数,
    ROUND(AVG(daily_count), 2) as 平均每日打卡人数
FROM (
    SELECT 
        draw_date,
        COUNT(DISTINCT user_id) as daily_count
    FROM daily_draws
    GROUP BY draw_date
) daily_stats;

-- ==================== 3. 用户活跃度统计 ====================
-- 用户打卡排行榜（Top 20）
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT dd.draw_date) as 打卡天数,
    COUNT(DISTINCT uc.card_id) as 拥有卡片数,
    u.exchange_points as 兑换点
FROM users u
LEFT JOIN daily_draws dd ON u.id = dd.user_id
LEFT JOIN user_cards uc ON u.id = uc.user_id
GROUP BY u.id, u.username, u.exchange_points
ORDER BY 打卡天数 DESC, 拥有卡片数 DESC
LIMIT 20;

-- 活跃用户统计（最近7天有打卡的用户）
SELECT 
    '最近7天活跃用户' as 统计项,
    COUNT(DISTINCT user_id) as 活跃用户数
FROM daily_draws
WHERE draw_date >= CURRENT_DATE - INTERVAL '7 days';

-- ==================== 4. 卡片收集统计 ====================
-- 卡片收集情况
SELECT 
    '卡片统计' as 统计项,
    COUNT(DISTINCT c.id) as 总卡片数,
    COUNT(DISTINCT uc.card_id) as 已被收集的卡片数,
    COUNT(DISTINCT uc.user_id) as 有收集卡片的用户数,
    COUNT(*) as 总收集次数
FROM cards c
LEFT JOIN user_cards uc ON c.id = uc.card_id;

-- 最受欢迎的卡片（被收集次数最多的卡片）
SELECT 
    c.id,
    c.name,
    COUNT(uc.user_id) as 收集人数,
    ROUND(COUNT(uc.user_id) * 100.0 / (SELECT COUNT(*) FROM users), 2) as 收集率百分比
FROM cards c
LEFT JOIN user_cards uc ON c.id = uc.card_id
GROUP BY c.id, c.name
ORDER BY 收集人数 DESC
LIMIT 10;

-- ==================== 5. 成就统计 ====================
-- 成就解锁统计
SELECT 
    at.code as 成就代码,
    at.name as 成就名称,
    COUNT(ua.user_id) as 解锁人数,
    COUNT(CASE WHEN ua.claimed_at IS NOT NULL THEN 1 END) as 已领取人数,
    ROUND(COUNT(ua.user_id) * 100.0 / (SELECT COUNT(*) FROM users), 2) as 解锁率百分比
FROM achievement_types at
LEFT JOIN user_achievements ua ON at.id = ua.achievement_type_id
GROUP BY at.id, at.code, at.name
ORDER BY 解锁人数 DESC;

-- ==================== 6. 兑换统计 ====================
-- 兑换统计（按月份）
SELECT 
    redemption_month as 月份,
    COUNT(*) as 兑换次数,
    COUNT(CASE WHEN redemption_type = 'basic' THEN 1 END) as 基础兑换,
    COUNT(CASE WHEN redemption_type = 'premium' THEN 1 END) as 高级兑换,
    COUNT(DISTINCT user_id) as 兑换用户数
FROM redemption_records
GROUP BY redemption_month
ORDER BY redemption_month DESC;

-- 本月兑换情况
SELECT 
    '本月兑换' as 统计项,
    COUNT(*) as 兑换次数,
    COUNT(CASE WHEN redemption_type = 'basic' THEN 1 END) as 基础兑换,
    COUNT(CASE WHEN redemption_type = 'premium' THEN 1 END) as 高级兑换
FROM redemption_records
WHERE redemption_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM');

-- ==================== 7. 地点打卡统计 ====================
-- 地点打卡统计（如果启用了地点功能）
SELECT 
    cl.name as 地点名称,
    COUNT(DISTINCT lc.user_id) as 打卡用户数,
    COUNT(*) as 总打卡次数,
    COUNT(DISTINCT lc.checkin_date) as 有打卡记录的天数
FROM checkin_locations cl
LEFT JOIN location_checkins lc ON cl.id = lc.location_id
GROUP BY cl.id, cl.name
ORDER BY 总打卡次数 DESC;

-- ==================== 8. 反馈统计 ====================
-- 反馈统计
SELECT 
    '反馈统计' as 统计项,
    COUNT(*) as 总反馈数,
    COUNT(CASE WHEN type = 'bug' THEN 1 END) as Bug反馈,
    COUNT(CASE WHEN type = 'suggestion' THEN 1 END) as 建议反馈,
    COUNT(CASE WHEN type = 'other' THEN 1 END) as 其他反馈,
    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as 今日反馈
FROM feedbacks;

-- ==================== 9. 综合日报 ====================
-- 今日综合数据
SELECT 
    '今日数据' as 日期,
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) = CURRENT_DATE) as 新增用户,
    (SELECT COUNT(DISTINCT user_id) FROM daily_draws WHERE draw_date = CURRENT_DATE) as 打卡人数,
    (SELECT COUNT(*) FROM daily_draws WHERE draw_date = CURRENT_DATE) as 打卡次数,
    (SELECT COUNT(*) FROM user_cards WHERE DATE(obtained_at) = CURRENT_DATE) as 新收集卡片,
    (SELECT COUNT(*) FROM user_achievements WHERE DATE(unlocked_at) = CURRENT_DATE) as 新解锁成就,
    (SELECT COUNT(*) FROM redemption_records WHERE DATE(redeemed_at) = CURRENT_DATE) as 兑换次数,
    (SELECT COUNT(*) FROM feedbacks WHERE DATE(created_at) = CURRENT_DATE) as 反馈数量;

-- ==================== 10. 用户留存分析 ====================
-- 用户留存（最近7天）
SELECT 
    DATE(created_at) as 注册日期,
    COUNT(*) as 注册人数,
    COUNT(CASE WHEN EXISTS (
        SELECT 1 FROM daily_draws 
        WHERE user_id = users.id 
        AND draw_date >= CURRENT_DATE - INTERVAL '7 days'
    ) THEN 1 END) as 7日内有打卡,
    ROUND(COUNT(CASE WHEN EXISTS (
        SELECT 1 FROM daily_draws 
        WHERE user_id = users.id 
        AND draw_date >= CURRENT_DATE - INTERVAL '7 days'
    ) THEN 1 END) * 100.0 / COUNT(*), 2) as 7日留存率百分比
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY 注册日期 DESC;
