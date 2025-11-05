# 🚀 运行指南

## 运行顺序

### 方法一：一键启动（推荐）⭐

```bash
./start_full.sh
```

这个脚本会自动：
1. ✅ 启动数据库（如果未运行）
2. ✅ 检查并下载Go依赖
3. ✅ 启动服务器

### 方法二：分步启动

**步骤1：启动数据库**
```bash
./start_db.sh
```

**步骤2：启动服务器**
```bash
go run main.go
```

或者使用后台运行：
```bash
go run main.go > server.log 2>&1 &
```

---

## 📊 使用 Beekeeper Studio 连接数据库

### 连接信息

打开 Beekeeper Studio，创建新连接：

- **连接类型**: PostgreSQL
- **Host**: `localhost` 或 `127.0.0.1`
- **Port**: `5432`
- **Database**: `h5project`
- **Username**: `h5user`
- **Password**: `h5pass123`
- **SSL Mode**: Disable

### 连接步骤

1. 打开 Beekeeper Studio
2. 点击 "New Connection"
3. 选择 "PostgreSQL"
4. 填入上述信息
5. 点击 "Connect"

### 查看数据

连接成功后，你可以：
- 查看 `users` 表结构
- 查看注册的用户数据
- 执行SQL查询

常用查询：
```sql
-- 查看所有用户
SELECT * FROM users;

-- 查看用户数量
SELECT COUNT(*) FROM users;

-- 查看最近注册的用户
SELECT id, username, holy_name, nickname, created_at 
FROM users 
ORDER BY created_at DESC;
```

---

## 🧪 测试流程

### 1. 启动服务

```bash
./start_full.sh
```

### 2. 访问登录页面

打开浏览器访问：http://localhost:8080/login.html

### 3. 注册账号

- 点击"立即注册"
- 输入用户名和密码（至少6位）
- 点击"注册"
- 注册成功后会自动登录并跳转到主页

### 4. 查看数据库

在 Beekeeper Studio 中：
```sql
SELECT * FROM users;
```

你应该能看到刚注册的用户数据。

### 5. 测试登录

- 退出登录
- 使用刚才注册的账号密码登录
- 应该能成功登录

### 6. 编辑个人资料

- 点击"个人资料"
- 编辑圣名、昵称、生日
- 保存后查看数据库，数据应该已更新

---

## 🔍 验证服务状态

### 检查数据库是否运行
```bash
docker ps | grep h5project_db
```

### 检查服务器是否运行
```bash
lsof -Pi :8080
```

### 查看服务器日志
```bash
tail -f server.log
```

### 测试API接口
```bash
# 测试注册接口
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"123456"}'

# 测试登录接口
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"123456"}'
```

---

## 🛑 停止服务

```bash
./stop.sh
```

这会停止：
- Go服务器
- ngrok（如果运行）
- **注意**：数据库不会停止（需要手动停止）

### 停止数据库

```bash
docker-compose down
```

### 停止数据库但保留数据

```bash
docker-compose stop
```

---

## 📝 完整测试流程示例

```bash
# 1. 启动所有服务
./start_full.sh

# 2. 等待几秒让服务启动完成

# 3. 打开浏览器访问
open http://localhost:8080/login.html

# 4. 注册一个测试账号（例如：用户名 test，密码 123456）

# 5. 打开 Beekeeper Studio，连接数据库

# 6. 执行查询查看数据
SELECT * FROM users WHERE username = 'test';

# 7. 在网页上编辑个人资料

# 8. 再次查询数据库，验证数据已更新
SELECT * FROM users WHERE username = 'test';
```

---

## ❓ 常见问题

**Q: 数据库连接失败？**
A: 确保数据库已启动：`./start_db.sh` 或 `docker-compose up -d`

**Q: 服务器启动失败？**
A: 检查是否有端口占用：`lsof -Pi :8080`，或查看日志：`tail -f server.log`

**Q: 登录后看不到数据？**
A: 确保数据库连接正常，检查服务器日志是否有错误

**Q: Beekeeper连接失败？**
A: 确认数据库正在运行，检查连接信息是否正确

