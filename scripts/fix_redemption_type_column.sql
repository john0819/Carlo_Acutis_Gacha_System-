-- 修复兑换记录表，添加缺失的 redemption_type 列
-- 适用于服务器上的旧数据库

-- 检查并添加 redemption_type 列
DO $$ 
BEGIN
    -- 检查列是否存在
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'redemption_records' 
        AND column_name = 'redemption_type'
    ) THEN
        -- 添加列，设置默认值为 'basic'
        ALTER TABLE redemption_records 
        ADD COLUMN redemption_type VARCHAR(20) NOT NULL DEFAULT 'basic';
        
        RAISE NOTICE '已添加 redemption_type 列';
    ELSE
        RAISE NOTICE 'redemption_type 列已存在';
    END IF;
END $$;

-- 确保唯一约束正确（一个月总共只能兑换一次，不管哪种类型）
-- 先删除可能存在的旧约束
ALTER TABLE redemption_records 
DROP CONSTRAINT IF EXISTS redemption_records_user_id_redemption_month_redemption_type_key;

ALTER TABLE redemption_records 
DROP CONSTRAINT IF EXISTS redemption_records_user_month_type_unique;

-- 添加新的唯一约束（只基于用户ID和月份）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'redemption_records_user_month_unique'
    ) THEN
        ALTER TABLE redemption_records 
        ADD CONSTRAINT redemption_records_user_month_unique 
        UNIQUE(user_id, redemption_month);
        
        RAISE NOTICE '已添加唯一约束';
    ELSE
        RAISE NOTICE '唯一约束已存在';
    END IF;
END $$;

-- 验证修复结果
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'redemption_records' 
AND column_name = 'redemption_type';

-- 显示约束信息
SELECT 
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'redemption_records'::regclass
AND contype = 'u';
