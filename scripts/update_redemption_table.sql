-- 更新兑换记录表，添加兑换类型字段
-- 如果表已存在，需要先删除旧的唯一约束，然后添加新字段和新的唯一约束

-- 删除旧的唯一约束（如果存在）
ALTER TABLE redemption_records DROP CONSTRAINT IF EXISTS redemption_records_user_id_redemption_month_key;

-- 添加兑换类型字段（如果不存在）
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'redemption_records' AND column_name = 'redemption_type'
    ) THEN
        ALTER TABLE redemption_records ADD COLUMN redemption_type VARCHAR(20) NOT NULL DEFAULT 'basic';
    END IF;
END $$;

-- 创建新的唯一约束（用户ID + 月份 + 兑换类型）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'redemption_records_user_month_type_unique'
    ) THEN
        ALTER TABLE redemption_records 
        ADD CONSTRAINT redemption_records_user_month_type_unique 
        UNIQUE(user_id, redemption_month, redemption_type);
    END IF;
END $$;

