-- 更新成就类型名称和描述
-- 适用于Docker部署的MySQL/PostgreSQL数据库

-- 更新成就名称
UPDATE achievement_types SET 
    name = '一点星星之光', 
    description = '获得任意第一张卡牌 (实体或数字)', 
    reward_points = 1 
WHERE code = 'first_card';

UPDATE achievement_types SET 
    name = '朝圣新星', 
    description = '累计在 3 个不同的教堂打卡成功', 
    reward_points = 1 
WHERE code = 'pilgrim_nova';

UPDATE achievement_types SET 
    name = '收集天上的宝藏', 
    description = '每 7 张不同卡片就会点亮一次', 
    reward_points = 1 
WHERE code = 'milestone_7';

-- 插入或更新"圣卡洛的圣体奇迹集"成就
INSERT INTO achievement_types (code, name, description, reward_points) VALUES
    ('complete_all', '圣卡洛的圣体奇迹集', '集齐所有打卡图片', 3)
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    reward_points = EXCLUDED.reward_points;

-- 显示更新结果
SELECT code, name, description, reward_points FROM achievement_types ORDER BY id;

