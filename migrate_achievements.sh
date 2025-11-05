#!/bin/bash
# 数据库迁移脚本 - 添加成就相关表

echo "🔄 执行成就系统数据库迁移..."
echo ""

# 检查数据库是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库未运行，请先启动数据库: ./start_db.sh"
    exit 1
fi

echo "📊 创建成就相关表..."

docker exec -i h5project_db psql -U h5user -d h5project << 'EOF'
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
    redemption_month VARCHAR(7) NOT NULL,
    redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    UNIQUE(user_id, redemption_month)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_type_id ON user_achievements(achievement_type_id);
CREATE INDEX IF NOT EXISTS idx_redemption_records_user_id ON redemption_records(user_id);
CREATE INDEX IF NOT EXISTS idx_redemption_records_month ON redemption_records(redemption_month);

-- 插入默认成就类型
INSERT INTO achievement_types (code, name, description, reward_points) VALUES
    ('first_card', '第一张卡', '获得第一张卡片', 1),
    ('complete_series', '集齐系列', '集齐一个系列的所有卡片', 5),
    ('milestone_7', '收集里程碑', '每收集7张不重复卡片', 1)
ON CONFLICT (code) DO NOTHING;

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
EOF

if [ $? -eq 0 ]; then
    echo "✅ 成就系统数据库表创建成功！"
    echo ""
    echo "📋 已创建的表："
    docker exec h5project_db psql -U h5user -d h5project -c "\dt" 2>/dev/null | grep -E "(achievement|redemption)"
else
    echo "❌ 数据库迁移失败"
    exit 1
fi

