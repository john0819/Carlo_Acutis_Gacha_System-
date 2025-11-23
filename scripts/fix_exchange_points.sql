-- 修复用户兑换点字段的NULL值问题
-- 确保所有用户的exchange_points字段都有有效值

-- 更新所有NULL的exchange_points为0
UPDATE users 
SET exchange_points = 0 
WHERE exchange_points IS NULL;

-- 确保字段不能为NULL（如果还没有设置的话）
ALTER TABLE users 
ALTER COLUMN exchange_points SET NOT NULL;

-- 确保默认值为0
ALTER TABLE users 
ALTER COLUMN exchange_points SET DEFAULT 0;

-- 验证修复结果
SELECT 
    COUNT(*) as total_users,
    COUNT(exchange_points) as users_with_points,
    SUM(CASE WHEN exchange_points IS NULL THEN 1 ELSE 0 END) as null_points_count,
    MIN(exchange_points) as min_points,
    MAX(exchange_points) as max_points,
    AVG(exchange_points) as avg_points
FROM users;
