# 打卡地点管理指南

## 📍 位置定位功能说明

**重要确认**：位置定位功能**仅在打卡抽卡时使用**，其他功能（查看卡包、成就、兑换等）都不需要位置信息。

## 🎯 如何管理打卡地点

### 方法一：使用管理脚本（推荐）

我们提供了一个便捷的管理脚本 `scripts/manage_locations.sh`：

#### 1. 列出所有地点
```bash
./scripts/manage_locations.sh list
```

#### 2. 添加新地点
```bash
./scripts/manage_locations.sh add <名称> <纬度> <经度> [半径(默认500米)] [成就代码]
```

示例：
```bash
# 添加打卡点A
./scripts/manage_locations.sh add '罗源南门堂' 26.123456 119.123456 500 location_a_15

# 添加打卡点B（不关联成就）
./scripts/manage_locations.sh add '其他地点' 26.234567 119.234567 500
```

#### 3. 更新现有地点
```bash
./scripts/manage_locations.sh update <ID> <名称> <纬度> <经度> [半径] [成就代码]
```

示例：
```bash
# 更新ID为1的地点
./scripts/manage_locations.sh update 1 '罗源南门堂（新位置）' 26.123456 119.123456 500 location_a_15
```

#### 4. 删除地点
```bash
./scripts/manage_locations.sh delete <ID>
```

⚠️ **注意**：删除地点会同时删除所有相关的打卡记录！

### 方法二：直接使用SQL

如果需要更精细的控制，可以直接连接数据库执行SQL：

```bash
# 连接数据库
docker exec -it h5project_db psql -U h5user -d h5project

# 查看所有地点
SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations;

# 添加新地点
INSERT INTO checkin_locations (name, latitude, longitude, radius_meters, achievement_code) 
VALUES ('打卡点A', 26.123456, 119.123456, 500, 'location_a_15');

# 更新地点
UPDATE checkin_locations 
SET name='新名称', latitude=26.123456, longitude=119.123456, radius_meters=500 
WHERE id=1;

# 删除地点
DELETE FROM checkin_locations WHERE id=1;
```

## 📐 如何获取地点的经纬度

### 方法1：百度地图坐标拾取工具
访问：https://lbsyun.baidu.com/jsdemo.htm#a5_2
- 在地图上点击目标地点
- 复制显示的经纬度（格式：纬度,经度）

### 方法2：高德地图
1. 打开高德地图网页版
2. 找到目标地点
3. 右键点击，选择"获取坐标"
4. 复制坐标

### 方法3：Google Maps
1. 打开 Google Maps
2. 找到目标地点
3. 右键点击，选择坐标
4. 复制坐标（格式：纬度,经度）

### 方法4：手机APP
- **高德地图APP**：长按地图上的位置，会显示坐标
- **百度地图APP**：长按地图上的位置，查看详情中的坐标

## 🎮 成就代码说明

每个打卡地点可以关联一个成就代码，当用户在该地点打卡满15次时，会自动解锁对应的成就：

- `location_a_15` - "稣稣的小羊"（打卡点A，15次）
- `location_b_15` - "主的门徒"（打卡点B，15次）
- `location_c_15` - "天主的子民"（打卡点C，15次）

如果不需要关联成就，可以不填写 `achievement_code`。

## ⚙️ 位置校验开关

位置校验功能默认是**关闭**的，方便测试。可以通过以下方式控制：

```bash
# 启用位置校验
./scripts/update_location_setting.sh true

# 禁用位置校验（测试模式）
./scripts/update_location_setting.sh false
```

## 📊 查看用户打卡统计

可以通过API查看用户在各地点的打卡次数：

```bash
# 需要先登录获取token，然后调用
curl -H "Authorization: Bearer <token>" http://localhost:8080/api/user/location-checkins
```

## ⚠️ 注意事项

1. **半径设置**：默认半径为500米，可以根据实际情况调整
2. **坐标精度**：建议使用至少6位小数的坐标（如：26.123456）
3. **删除地点**：删除地点会同时删除所有相关的打卡记录，请谨慎操作
4. **成就关联**：如果修改了地点的成就代码，已解锁的成就不会自动更新，需要手动处理

## 🔍 常见问题

**Q: 如何替换现有的三个打卡地点？**
A: 使用 `update` 命令更新每个地点的坐标：
```bash
./scripts/manage_locations.sh update 1 '新地点A' 新纬度 新经度 500 location_a_15
./scripts/manage_locations.sh update 2 '新地点B' 新纬度 新经度 500 location_b_15
./scripts/manage_locations.sh update 3 '新地点C' 新纬度 新经度 500 location_c_15
```

**Q: 可以添加超过3个地点吗？**
A: 可以！系统支持任意数量的打卡地点。只需要在添加时指定不同的成就代码，或者不指定成就代码。

**Q: 位置定位会影响其他功能吗？**
A: 不会。位置定位**仅在打卡抽卡时使用**，查看卡包、成就、兑换等功能都不需要位置信息。

