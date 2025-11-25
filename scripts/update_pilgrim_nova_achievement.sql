-- 更新"朝圣新星"成就描述：从3个教堂改为2个教堂
UPDATE achievement_types 
SET description = '累计在 2 个不同的教堂打卡成功'
WHERE code = 'pilgrim_nova';

-- 验证更新结果
SELECT code, name, description, reward_points 
FROM achievement_types 
WHERE code = 'pilgrim_nova';

