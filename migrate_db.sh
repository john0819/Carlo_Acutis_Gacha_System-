#!/bin/bash
# 数据库迁移脚本 - 创建新的表结构

echo "🔄 执行数据库迁移..."
echo ""

# 检查数据库是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 数据库未运行，请先启动数据库: ./start_db.sh"
    exit 1
fi

echo "📊 创建卡片相关表..."

docker exec -i h5project_db psql -U h5user -d h5project << 'EOF'
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
EOF

if [ $? -eq 0 ]; then
    echo "✅ 数据库表创建成功！"
    echo ""
    echo "📋 已创建的表："
    docker exec h5project_db psql -U h5user -d h5project -c "\dt" 2>/dev/null | grep -E "(cards|user_cards|daily_draws)"
else
    echo "❌ 数据库迁移失败"
    exit 1
fi

