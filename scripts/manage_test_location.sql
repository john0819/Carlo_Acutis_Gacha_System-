-- 管理测试打卡地点
-- 1. 删除所有现有的测试地点（achievement_code IS NULL）
-- 2. 插入新的测试地点

-- 步骤1：删除所有测试地点
DELETE FROM checkin_locations 
WHERE achievement_code IS NULL;

-- 步骤2：插入新的测试地点
-- 坐标：纬度 22.30000000, 经度 114.18000000
-- 半径：150米（与教堂保持一致）
-- achievement_code: NULL（测试位置，前端不显示）
-- INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
-- VALUES ('测试地点', 22.30000000, 114.18000000, 150, NULL);

-- 验证结果：查看所有地点
SELECT 
    id,
    name,
    latitude as 纬度,
    longitude as 经度,
    radius_meters as 半径米,
    achievement_code as 成就代码,
    CASE 
        WHEN achievement_code IS NULL THEN '测试位置（隐藏）' 
        ELSE '正式地点（显示）' 
    END as 类型
FROM checkin_locations
ORDER BY achievement_code NULLS LAST, id;

