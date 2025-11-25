-- 更新/插入两个教堂的打卡地点
-- 港头教堂：经度119.55, 纬度26.5
-- 南门教堂：经度119.5, 纬度26.5
-- 半径：150米

-- 先更新旧的地点名称（如果存在）
UPDATE checkin_locations 
SET name = '港头教堂',
    latitude = 26.5,
    longitude = 119.55,
    radius_meters = 150,
    achievement_code = 'location_b_15'
WHERE achievement_code = 'location_b_15' AND name != '港头教堂';

UPDATE checkin_locations 
SET name = '南门教堂',
    latitude = 26.5,
    longitude = 119.5,
    radius_meters = 150,
    achievement_code = 'location_a_15'
WHERE achievement_code = 'location_a_15' AND name != '南门教堂';

-- 插入港头教堂（如果不存在）
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
SELECT '港头教堂', 26.5, 119.55, 150, 'location_b_15'
WHERE NOT EXISTS (
    SELECT 1 FROM checkin_locations WHERE achievement_code = 'location_b_15'
);

-- 插入南门教堂（如果不存在）
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
SELECT '南门教堂', 26.5, 119.5, 150, 'location_a_15'
WHERE NOT EXISTS (
    SELECT 1 FROM checkin_locations WHERE achievement_code = 'location_a_15'
);

-- 确保坐标和半径正确（更新已存在的地点）
UPDATE checkin_locations 
SET latitude = 26.5,
    longitude = 119.55,
    radius_meters = 150
WHERE achievement_code = 'location_b_15';

UPDATE checkin_locations 
SET latitude = 26.5,
    longitude = 119.5,
    radius_meters = 150
WHERE achievement_code = 'location_a_15';

-- 验证插入结果
SELECT 
    id,
    name,
    latitude as 纬度,
    longitude as 经度,
    radius_meters as 半径米,
    achievement_code as 成就代码,
    CASE WHEN achievement_code IS NULL THEN '测试位置' ELSE '正式地点' END as 类型
FROM checkin_locations
ORDER BY achievement_code NULLS LAST, id;
