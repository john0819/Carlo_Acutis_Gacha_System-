-- 初始化打卡地点
-- 使用方法：根据实际地点修改经纬度，然后执行此脚本
-- 获取经纬度的方法：
-- 1. 使用百度地图、高德地图或Google地图，找到地点后右键点击，选择"获取坐标"
-- 2. 或者使用在线工具：https://lbsyun.baidu.com/jsdemo.htm#a5_2
-- 3. 格式：纬度在前，经度在后（例如：26.123456, 119.123456）

-- 示例：插入3个打卡地点（请根据实际情况修改）
-- 打卡点A
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES
    ('打卡点A', 26.123456, 119.123456, 500, 'location_a_15')
ON CONFLICT DO NOTHING;

-- 打卡点B
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES
    ('打卡点B', 26.234567, 119.234567, 500, 'location_b_15')
ON CONFLICT DO NOTHING;

-- 打卡点C
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) VALUES
    ('打卡点C', 26.345678, 119.345678, 500, 'location_c_15')
ON CONFLICT DO NOTHING;

-- 查看插入的地点
SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations;

