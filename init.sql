-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    holy_name VARCHAR(100),
    nickname VARCHAR(100),
    birthday DATE,
    checkin_count INTEGER DEFAULT 0,
    exchange_points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_username ON users(username);

-- 卡片表
CREATE TABLE IF NOT EXISTS cards (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    rarity VARCHAR(20) DEFAULT 'common',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户卡包表（记录用户拥有的卡片）
CREATE TABLE IF NOT EXISTS user_cards (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, card_id)
);

-- 每日抽卡记录表（记录用户每天的抽卡结果）
CREATE TABLE IF NOT EXISTS daily_draws (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_id INTEGER NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    draw_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_new_card BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, draw_date)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cards_card_id ON user_cards(card_id);
CREATE INDEX IF NOT EXISTS idx_daily_draws_user_id ON daily_draws(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_draws_draw_date ON daily_draws(draw_date);
CREATE INDEX IF NOT EXISTS idx_daily_draws_user_date ON daily_draws(user_id, draw_date);

-- 成就类型表
CREATE TABLE IF NOT EXISTS achievement_types (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    reward_points INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户成就记录表
CREATE TABLE IF NOT EXISTS user_achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_type_id INTEGER NOT NULL REFERENCES achievement_types(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    claimed_at TIMESTAMP,
    UNIQUE(user_id, achievement_type_id)
);

-- 兑换记录表
CREATE TABLE IF NOT EXISTS redemption_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    redemption_month VARCHAR(7) NOT NULL, -- 格式: YYYY-MM
    redemption_type VARCHAR(20) NOT NULL DEFAULT 'basic', -- 'basic' 或 'premium'
    redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    UNIQUE(user_id, redemption_month) -- 一个月总共只能兑换一次
);

-- 里程碑领取记录表（用于追踪milestone_7的多次领取）
CREATE TABLE IF NOT EXISTS milestone_claims (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_count INTEGER NOT NULL, -- 达到这个数量时领取的
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, card_count)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_type_id ON user_achievements(achievement_type_id);
CREATE INDEX IF NOT EXISTS idx_redemption_records_user_id ON redemption_records(user_id);
CREATE INDEX IF NOT EXISTS idx_redemption_records_month ON redemption_records(redemption_month);
CREATE INDEX IF NOT EXISTS idx_milestone_claims_user_id ON milestone_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_milestone_claims_card_count ON milestone_claims(card_count);

-- 打卡地点表
CREATE TABLE IF NOT EXISTS checkin_locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    radius_meters INTEGER DEFAULT 500,
    achievement_code VARCHAR(50), -- 关联的成就代码
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户地点打卡记录表
CREATE TABLE IF NOT EXISTS location_checkins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location_id INTEGER NOT NULL REFERENCES checkin_locations(id) ON DELETE CASCADE,
    checkin_date DATE NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, location_id, checkin_date)
);

CREATE INDEX IF NOT EXISTS idx_location_checkins_user_id ON location_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_location_checkins_location_id ON location_checkins(location_id);
CREATE INDEX IF NOT EXISTS idx_location_checkins_date ON location_checkins(checkin_date);

-- 系统配置表（用于控制定位功能开关等）
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(50) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认配置
INSERT INTO system_config (key, value, description) VALUES
    ('location_check_enabled', 'false', '是否启用位置校验（true/false）')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    description = EXCLUDED.description;

-- 插入默认成就类型
INSERT INTO achievement_types (code, name, description, reward_points) VALUES
    ('first_card', '一点星星之光', '获得任意第一张卡牌 (实体或数字)', 1),
    ('pilgrim_nova', '朝圣新星', '累计在 3 个不同的教堂打卡成功', 1),
    ('milestone_7', '收集天上的宝藏', '每 7 张不同卡片就会点亮一次', 1),
    ('complete_all', '圣卡洛的圣体奇迹集', '集齐所有打卡图片', 3),
    ('location_a_15', '稣稣的小羊', '在打卡点A累计打卡15次', 1),
    ('location_b_15', '主的门徒', '在打卡点B累计打卡15次', 1),
    ('location_c_15', '天主的子民', '在打卡点C累计打卡15次', 1)
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    reward_points = EXCLUDED.reward_points;

-- 插入默认打卡地点（如果不存在，基于name判断）
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
SELECT * FROM (VALUES
    ('南门天主教堂', 26.48, 119.54, 1000, 'location_a_15'),
    ('港头天主教堂', 26.50, 119.56, 1000, 'location_b_15'),
    ('测试地点', 22.30, 114.18, 1000, NULL)
) AS v(name, latitude, longitude, radius_meters, achievement_code)
WHERE NOT EXISTS (
    SELECT 1 FROM checkin_locations WHERE checkin_locations.name = v.name
);

-- 反馈表
CREATE TABLE IF NOT EXISTS feedbacks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'other',
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_feedbacks_user_id ON feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_feedbacks_status ON feedbacks(status);
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at ON feedbacks(created_at);

