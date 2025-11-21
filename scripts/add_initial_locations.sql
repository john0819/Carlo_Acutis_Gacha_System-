-- 添加初始打卡地点
-- 注意：用户提供的坐标格式是 经度,纬度，需要转换为 纬度,经度

-- 清空现有地点（如果需要重新初始化）
-- DELETE FROM checkin_locations;

-- 南门天主教堂：经度119.54, 纬度26.48 -> 纬度26.48, 经度119.54
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES
    ('南门天主教堂', 26.48, 119.54, 1000, 'location_a_15')
ON CONFLICT DO NOTHING;

-- 港头天主教堂：经度119.56, 纬度26.50 -> 纬度26.50, 经度119.56
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES
    ('港头天主教堂', 26.50, 119.56, 1000, 'location_b_15')
ON CONFLICT DO NOTHING;

-- 测试地点：经度114.18, 纬度22.30 -> 纬度22.30, 经度114.18（不关联成就）
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES
    ('测试地点', 22.30, 114.18, 1000, NULL)
ON CONFLICT DO NOTHING;

-- 查看插入的地点
SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations ORDER BY id;

