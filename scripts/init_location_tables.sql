-- 初始化打卡地点相关表
-- 如果表已存在则跳过，如果不存在则创建

-- 打卡地点表
CREATE TABLE IF NOT EXISTS checkin_locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    radius_meters INTEGER DEFAULT 500,
    achievement_code VARCHAR(50),
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

-- 系统配置表
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(50) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_location_checkins_user_id ON location_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_location_checkins_location_id ON location_checkins(location_id);
CREATE INDEX IF NOT EXISTS idx_location_checkins_date ON location_checkins(checkin_date);

-- 插入默认配置（如果不存在）
INSERT INTO system_config (key, value, description) VALUES
    ('location_check_enabled', 'false', '是否启用位置校验（true/false）')
ON CONFLICT (key) DO NOTHING;

-- 插入三个地点成就类型（如果不存在）
INSERT INTO achievement_types (code, name, description, reward_points) VALUES
    ('location_a_15', '稣稣的小羊', '在打卡点A累计打卡15次', 1),
    ('location_b_15', '主的门徒', '在打卡点B累计打卡15次', 1),
    ('location_c_15', '天主的子民', '在打卡点C累计打卡15次', 1)
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    reward_points = EXCLUDED.reward_points;

