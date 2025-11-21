-- 更新兑换记录表的唯一约束：一个月总共只能兑换一次（不管哪种类型）
-- 先删除旧的约束
ALTER TABLE redemption_records DROP CONSTRAINT IF EXISTS redemption_records_user_id_redemption_month_redemption_type_key;
ALTER TABLE redemption_records DROP CONSTRAINT IF EXISTS redemption_records_user_id_redemption_month_key;

-- 添加新的唯一约束（只基于用户ID和月份）
ALTER TABLE redemption_records ADD CONSTRAINT redemption_records_user_month_unique UNIQUE(user_id, redemption_month);

-- 创建里程碑领取记录表（如果不存在）
CREATE TABLE IF NOT EXISTS milestone_claims (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_count INTEGER NOT NULL,
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, card_count)
);

CREATE INDEX IF NOT EXISTS idx_milestone_claims_user_id ON milestone_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_milestone_claims_card_count ON milestone_claims(card_count);

