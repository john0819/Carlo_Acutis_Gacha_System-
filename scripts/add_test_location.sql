-- 添加测试打卡地点
-- 测试位置：achievement_code设置为NULL即可，前端不会显示，但可以正常打卡

-- 示例：添加一个测试地点
-- 格式：INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
--       VALUES ('测试地点名称', 纬度, 经度, 半径米数, NULL);

-- 示例（你可以修改坐标和名称）：
-- INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
-- VALUES ('我的测试地点', 26.5, 119.5, 150, NULL);

-- 查看所有地点（包括测试位置）
SELECT 
    id,
    name,
    latitude as 纬度,
    longitude as 经度,
    radius_meters as 半径米,
    achievement_code as 成就代码,
    CASE WHEN achievement_code IS NULL THEN '测试位置（隐藏）' ELSE '正式地点（显示）' END as 类型
FROM checkin_locations
ORDER BY achievement_code NULLS LAST, id;
