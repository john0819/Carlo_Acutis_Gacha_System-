-- 更新地点成就的描述，使用实际地点名称
-- 根据checkin_locations表中的实际地点名称更新成就描述

UPDATE achievement_types 
SET description = (
    SELECT '在' || cl.name || '累计打卡15次'
    FROM checkin_locations cl
    WHERE cl.achievement_code = achievement_types.code
)
WHERE code IN ('location_a_15', 'location_b_15', 'location_c_15')
AND EXISTS (
    SELECT 1 FROM checkin_locations 
    WHERE achievement_code = achievement_types.code
);

-- 如果地点表中没有对应的成就代码，使用默认描述
-- 这里我们手动更新为已知的地点名称
UPDATE achievement_types 
SET description = '在南门天主教堂累计打卡15次'
WHERE code = 'location_a_15' 
AND NOT EXISTS (
    SELECT 1 FROM checkin_locations WHERE achievement_code = 'location_a_15'
);

UPDATE achievement_types 
SET description = '在港头天主教堂累计打卡15次'
WHERE code = 'location_b_15'
AND NOT EXISTS (
    SELECT 1 FROM checkin_locations WHERE achievement_code = 'location_b_15'
);

-- 查看更新结果
SELECT code, name, description, reward_points FROM achievement_types 
WHERE code IN ('location_a_15', 'location_b_15', 'location_c_15');

