-- ============================================================
-- 月活跃用户（MAU）统计查询脚本
-- 基于现有数据库表，无需新增表
-- ============================================================

-- ==================== 1. 月活跃用户统计（MAU） ====================
-- 定义：在一个月内至少有一次活动的用户
-- 活动包括：抽卡、地点打卡、兑换、解锁成就、收集卡片

-- 1.1 指定月份的月活用户数（按不同行为分类）
-- 使用方法：修改下面的月份，例如 '2024-01'
WITH target_month AS (
    SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM') as month  -- 当前月份，可手动修改
),
month_start AS (
    SELECT DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM'))::DATE as start_date
),
month_end AS (
    SELECT (DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM')) + INTERVAL '1 month - 1 day')::DATE as end_date
)
SELECT 
    (SELECT month FROM target_month) as 统计月份,
    -- 基于抽卡的活跃用户
    COUNT(DISTINCT CASE WHEN dd.draw_date BETWEEN (SELECT start_date FROM month_start) AND (SELECT end_date FROM month_end) THEN dd.user_id END) as 抽卡活跃用户,
    -- 基于地点打卡的活跃用户
    COUNT(DISTINCT CASE WHEN lc.checkin_date BETWEEN (SELECT start_date FROM month_start) AND (SELECT end_date FROM month_end) THEN lc.user_id END) as 地点打卡活跃用户,
    -- 基于兑换的活跃用户
    COUNT(DISTINCT CASE WHEN rr.redemption_month = (SELECT month FROM target_month) THEN rr.user_id END) as 兑换活跃用户,
    -- 基于解锁成就的活跃用户
    COUNT(DISTINCT CASE WHEN ua.unlocked_at::DATE BETWEEN (SELECT start_date FROM month_start) AND (SELECT end_date FROM month_end) THEN ua.user_id END) as 成就解锁活跃用户,
    -- 基于收集卡片的活跃用户
    COUNT(DISTINCT CASE WHEN uc.obtained_at::DATE BETWEEN (SELECT start_date FROM month_start) AND (SELECT end_date FROM month_end) THEN uc.user_id END) as 收集卡片活跃用户,
    -- 综合月活用户（至少有一种行为的用户）
    COUNT(DISTINCT active_users.user_id) as 综合月活用户数
FROM (
    SELECT DISTINCT user_id FROM daily_draws 
    WHERE draw_date BETWEEN (SELECT DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM'))::DATE) 
        AND (SELECT (DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM')) + INTERVAL '1 month - 1 day')::DATE)
    UNION
    SELECT DISTINCT user_id FROM location_checkins 
    WHERE checkin_date BETWEEN (SELECT DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM'))::DATE) 
        AND (SELECT (DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM')) + INTERVAL '1 month - 1 day')::DATE)
    UNION
    SELECT DISTINCT user_id FROM redemption_records 
    WHERE redemption_month = (SELECT month FROM target_month)
    UNION
    SELECT DISTINCT user_id FROM user_achievements 
    WHERE unlocked_at::DATE BETWEEN (SELECT DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM'))::DATE) 
        AND (SELECT (DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM')) + INTERVAL '1 month - 1 day')::DATE)
    UNION
    SELECT DISTINCT user_id FROM user_cards 
    WHERE obtained_at::DATE BETWEEN (SELECT DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM'))::DATE) 
        AND (SELECT (DATE_TRUNC('month', TO_DATE((SELECT month FROM target_month), 'YYYY-MM')) + INTERVAL '1 month - 1 day')::DATE)
) active_users
LEFT JOIN daily_draws dd ON active_users.user_id = dd.user_id
LEFT JOIN location_checkins lc ON active_users.user_id = lc.user_id
LEFT JOIN redemption_records rr ON active_users.user_id = rr.user_id
LEFT JOIN user_achievements ua ON active_users.user_id = ua.user_id
LEFT JOIN user_cards uc ON active_users.user_id = uc.user_id;

-- 1.2 最近12个月的月活趋势
SELECT 
    TO_CHAR(months.month_start, 'YYYY-MM') as 月份,
    COUNT(DISTINCT active_users.user_id) as 月活用户数,
    COUNT(DISTINCT CASE WHEN u.created_at <= month_range.month_end THEN u.id END) as 当月累计注册用户数,
    ROUND(COUNT(DISTINCT active_users.user_id) * 100.0 / NULLIF(COUNT(DISTINCT CASE WHEN u.created_at <= month_range.month_end THEN u.id END), 0), 2) as 活跃率百分比
FROM (
    SELECT generate_series(
        DATE_TRUNC('month', CURRENT_DATE - INTERVAL '11 months'),
        DATE_TRUNC('month', CURRENT_DATE),
        '1 month'::INTERVAL
    )::DATE as month_start
) months
CROSS JOIN LATERAL (
    SELECT 
        months.month_start as month_start,
        (months.month_start + INTERVAL '1 month - 1 day')::DATE as month_end
) month_range
LEFT JOIN LATERAL (
    SELECT DISTINCT user_id FROM daily_draws 
    WHERE draw_date BETWEEN month_range.month_start AND month_range.month_end
    UNION
    SELECT DISTINCT user_id FROM location_checkins 
    WHERE checkin_date BETWEEN month_range.month_start AND month_range.month_end
    UNION
    SELECT DISTINCT user_id FROM redemption_records 
    WHERE redemption_month = TO_CHAR(month_range.month_start, 'YYYY-MM')
    UNION
    SELECT DISTINCT user_id FROM user_achievements 
    WHERE unlocked_at::DATE BETWEEN month_range.month_start AND month_range.month_end
    UNION
    SELECT DISTINCT user_id FROM user_cards 
    WHERE obtained_at::DATE BETWEEN month_range.month_start AND month_range.month_end
) active_users ON true
LEFT JOIN users u ON u.created_at <= month_range.month_end
GROUP BY months.month_start
ORDER BY months.month_start DESC;

-- ==================== 2. 日活跃用户统计（DAU） ====================
-- 最近30天的日活趋势
SELECT 
    draw_date as 日期,
    COUNT(DISTINCT user_id) as 日活用户数,
    COUNT(*) as 日活次数,
    COUNT(CASE WHEN is_new_card THEN 1 END) as 新卡次数
FROM daily_draws
WHERE draw_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY draw_date
ORDER BY draw_date DESC;

-- ==================== 3. 用户活跃度分级 ====================
-- 根据最近30天的活动频率，将用户分为：高活跃、中活跃、低活跃、沉睡
SELECT 
    activity_level as 活跃度等级,
    COUNT(*) as 用户数,
    ROUND(AVG(activity_days), 2) as 平均活跃天数,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) as 占比百分比
FROM (
    SELECT 
        u.id,
        COUNT(DISTINCT dd.draw_date) as activity_days,
        CASE 
            WHEN COUNT(DISTINCT dd.draw_date) >= 20 THEN '高活跃用户'
            WHEN COUNT(DISTINCT dd.draw_date) >= 10 THEN '中活跃用户'
            WHEN COUNT(DISTINCT dd.draw_date) >= 1 THEN '低活跃用户'
            ELSE '沉睡用户'
        END as activity_level
    FROM users u
    LEFT JOIN daily_draws dd ON u.id = dd.user_id 
        AND dd.draw_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY u.id
) user_activity
GROUP BY activity_level
ORDER BY 
    CASE activity_level
        WHEN '高活跃用户' THEN 1
        WHEN '中活跃用户' THEN 2
        WHEN '低活跃用户' THEN 3
        ELSE 4
    END;

-- ==================== 4. 用户留存分析 ====================
-- 4.1 新用户留存率（按注册月份）
SELECT 
    TO_CHAR(registration_month, 'YYYY-MM') as 注册月份,
    COUNT(*) as 注册用户数,
    COUNT(CASE WHEN last_activity >= registration_month + INTERVAL '1 month' THEN 1 END) as 次月留存用户,
    ROUND(COUNT(CASE WHEN last_activity >= registration_month + INTERVAL '1 month' THEN 1 END) * 100.0 / COUNT(*), 2) as 次月留存率百分比,
    COUNT(CASE WHEN last_activity >= registration_month + INTERVAL '2 months' THEN 1 END) as 第三月留存用户,
    ROUND(COUNT(CASE WHEN last_activity >= registration_month + INTERVAL '2 months' THEN 1 END) * 100.0 / COUNT(*), 2) as 第三月留存率百分比
FROM (
    SELECT 
        DATE_TRUNC('month', u.created_at)::DATE as registration_month,
        u.id,
        GREATEST(
            COALESCE(MAX(dd.draw_date), '1970-01-01'::DATE),
            COALESCE(MAX(lc.checkin_date), '1970-01-01'::DATE),
            COALESCE(MAX(rr.redeemed_at::DATE), '1970-01-01'::DATE),
            COALESCE(MAX(ua.unlocked_at::DATE), '1970-01-01'::DATE),
            COALESCE(MAX(uc.obtained_at::DATE), '1970-01-01'::DATE)
        ) as last_activity
    FROM users u
    LEFT JOIN daily_draws dd ON u.id = dd.user_id
    LEFT JOIN location_checkins lc ON u.id = lc.user_id
    LEFT JOIN redemption_records rr ON u.id = rr.user_id
    LEFT JOIN user_achievements ua ON u.id = ua.user_id
    LEFT JOIN user_cards uc ON u.id = uc.user_id
    WHERE u.created_at >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY u.id, DATE_TRUNC('month', u.created_at)::DATE
) user_retention
GROUP BY registration_month
ORDER BY registration_month DESC;

-- ==================== 5. 活跃用户行为分析 ====================
-- 5.1 本月活跃用户的详细行为统计
SELECT 
    u.id as 用户ID,
    u.username as 用户名,
    COUNT(DISTINCT dd.draw_date) as 抽卡天数,
    COUNT(DISTINCT lc.checkin_date) as 地点打卡天数,
    COUNT(DISTINCT rr.redemption_month) as 兑换次数,
    COUNT(DISTINCT ua.achievement_type_id) as 解锁成就数,
    COUNT(DISTINCT uc.card_id) as 收集卡片数,
    GREATEST(
        COALESCE(MAX(dd.draw_date), '1970-01-01'::DATE),
        COALESCE(MAX(lc.checkin_date), '1970-01-01'::DATE),
        COALESCE(MAX(rr.redeemed_at::DATE), '1970-01-01'::DATE),
        COALESCE(MAX(ua.unlocked_at::DATE), '1970-01-01'::DATE),
        COALESCE(MAX(uc.obtained_at::DATE), '1970-01-01'::DATE)
    ) as 最后活跃日期
FROM users u
INNER JOIN (
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
) active_users ON u.id = active_users.user_id
LEFT JOIN daily_draws dd ON u.id = dd.user_id 
    AND dd.draw_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE
LEFT JOIN location_checkins lc ON u.id = lc.user_id 
    AND lc.checkin_date >= DATE_TRUNC('month', CURRENT_DATE)::DATE
LEFT JOIN redemption_records rr ON u.id = rr.user_id 
    AND rr.redemption_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM')
LEFT JOIN user_achievements ua ON u.id = ua.user_id 
    AND ua.unlocked_at >= DATE_TRUNC('month', CURRENT_DATE)
LEFT JOIN user_cards uc ON u.id = uc.user_id 
    AND uc.obtained_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY u.id, u.username
ORDER BY 抽卡天数 DESC, 收集卡片数 DESC
LIMIT 50;

-- ==================== 6. 活跃度对比（环比、同比） ====================
-- 6.1 本月 vs 上月
SELECT 
    '本月' as 时间段,
    COUNT(DISTINCT active_users.user_id) as 月活用户数
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
) active_users
UNION ALL
SELECT 
    '上月' as 时间段,
    COUNT(DISTINCT active_users.user_id) as 月活用户数
FROM (
    SELECT DISTINCT user_id FROM daily_draws 
    WHERE draw_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')::DATE
        AND draw_date < DATE_TRUNC('month', CURRENT_DATE)::DATE
    UNION
    SELECT DISTINCT user_id FROM location_checkins 
    WHERE checkin_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')::DATE
        AND checkin_date < DATE_TRUNC('month', CURRENT_DATE)::DATE
    UNION
    SELECT DISTINCT user_id FROM redemption_records 
    WHERE redemption_month = TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM')
    UNION
    SELECT DISTINCT user_id FROM user_achievements 
    WHERE unlocked_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        AND unlocked_at < DATE_TRUNC('month', CURRENT_DATE)
    UNION
    SELECT DISTINCT user_id FROM user_cards 
    WHERE obtained_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
        AND obtained_at < DATE_TRUNC('month', CURRENT_DATE)
) active_users;

-- ==================== 7. 快速查询：当前月份月活 ====================
-- 最简单的月活查询（当前月份）
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

