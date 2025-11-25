-- 更新成就描述，将打卡点A/B改为具体的教堂名称
-- 注意：location_c_15成就会自动隐藏（因为代码中会检查对应的地点是否存在）

-- 更新location_a_15成就描述（如果对应的地点存在，会被动态更新为"在南门教堂累计打卡15次"）
UPDATE achievement_types 
SET description = '在南门教堂累计打卡15次'
WHERE code = 'location_a_15';

-- 更新location_b_15成就描述（如果对应的地点存在，会被动态更新为"在港头教堂累计打卡15次"）
UPDATE achievement_types 
SET description = '在港头教堂累计打卡15次'
WHERE code = 'location_b_15';

-- location_c_15成就保留在数据库中，但如果对应的地点不存在（achievement_code为NULL），会自动隐藏
-- 如果需要完全删除location_c_15成就，可以执行：
-- DELETE FROM achievement_types WHERE code = 'location_c_15';

-- 验证更新结果
SELECT code, name, description, reward_points 
FROM achievement_types 
WHERE code LIKE 'location_%'
ORDER BY code;
