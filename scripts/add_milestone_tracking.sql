-- 添加里程碑追踪表，用于记录每次达到7的倍数时的领取记录
CREATE TABLE IF NOT EXISTS milestone_claims (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_count INTEGER NOT NULL, -- 达到这个数量时领取的
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, card_count)
);

CREATE INDEX IF NOT EXISTS idx_milestone_claims_user_id ON milestone_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_milestone_claims_card_count ON milestone_claims(card_count);

