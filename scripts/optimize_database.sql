-- 数据库性能优化脚本
-- 添加必要的索引以提升查询性能

-- 用户表索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- 每日抽卡表索引
CREATE INDEX IF NOT EXISTS idx_daily_draws_user_date ON daily_draws(user_id, draw_date);
CREATE INDEX IF NOT EXISTS idx_daily_draws_date ON daily_draws(draw_date);
CREATE INDEX IF NOT EXISTS idx_daily_draws_user_id ON daily_draws(user_id);

-- 用户卡片表索引
CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cards_card_id ON user_cards(card_id);

-- 用户成就表索引
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_type_id ON user_achievements(achievement_type_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked ON user_achievements(unlocked_at) WHERE unlocked_at IS NOT NULL;

-- 兑换记录表索引
CREATE INDEX IF NOT EXISTS idx_redemption_records_user_month ON redemption_records(user_id, redemption_month);
CREATE INDEX IF NOT EXISTS idx_redemption_records_month ON redemption_records(redemption_month);

-- 地点打卡表索引
CREATE INDEX IF NOT EXISTS idx_location_checkins_user_date ON location_checkins(user_id, checkin_date);
CREATE INDEX IF NOT EXISTS idx_location_checkins_location_date ON location_checkins(location_id, checkin_date);

-- 反馈表索引
CREATE INDEX IF NOT EXISTS idx_feedbacks_user_id ON feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at ON feedbacks(created_at);
CREATE INDEX IF NOT EXISTS idx_feedbacks_type ON feedbacks(type);

-- 分析查询性能
ANALYZE;

-- 显示表大小统计
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE schemaname = 'public' 
ORDER BY tablename, attname;
