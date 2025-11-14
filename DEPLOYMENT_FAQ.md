# 🚀 部署常见问题解答

## 1. 云主机IP地址问题

### 查看公网IP

你看到的 `172.19.24.157` 是**内网IP**（私有IP），不是公网IP。

**查看公网IP的方法：**

```bash
# 方法1：使用curl查询
curl ifconfig.me
# 或
curl ip.sb
# 或
curl icanhazip.com

# 方法2：在云服务商控制台查看
# 阿里云：ECS控制台 -> 实例详情 -> 网络信息 -> 公网IP
# 腾讯云：CVM控制台 -> 实例详情 -> 网络信息 -> 公网IP
```

### IP会变吗？

**内网IP（172.19.24.157）：**
- ✅ **可能会变**：重启实例、释放后重新创建可能会变化
- ⚠️ **不影响**：服务只监听内网IP，不影响使用

**公网IP：**
- ⚠️ **可能会变**：如果使用按量付费的公网IP，释放后重新创建会变化
- ✅ **解决方案**：使用**弹性公网IP（EIP）**
  - 绑定弹性IP后，IP地址**不会变**
  - 即使重启、释放实例，IP也不会变
  - 这是**推荐的做法**

### 推荐配置（阿里云/腾讯云）

1. **申请弹性公网IP（EIP）**
2. **绑定到云主机**
3. **使用弹性IP访问服务**
4. **生成二维码时使用弹性IP**

这样二维码地址就**永远不会变**了！

---

## 2. 数据库数据存储位置

### 数据存储在哪里？

数据库数据存储在 **Docker Volume** 中：

```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
```

**实际存储位置：**
```bash
# Docker volume 存储在：
/var/lib/docker/volumes/<volume_name>/_data

# 查看volume信息
docker volume inspect h5project_postgres_data
```

### 数据会丢失吗？

**不会丢失的情况：**
- ✅ 重启服务：`sudo systemctl restart h5project`
- ✅ 重启数据库容器：`docker restart h5project_db`
- ✅ 重启服务器（如果volume还在）
- ✅ 更新代码：只更新应用代码，不删除volume

**会丢失的情况：**
- ❌ 删除Docker volume：`docker volume rm h5project_postgres_data`
- ❌ 删除容器时同时删除volume：`docker-compose down -v`
- ❌ 重装系统或格式化磁盘

### 如何确保数据不丢失？

1. **定期备份**（推荐）：
   ```bash
   # 使用备份脚本
   ./scripts/backup_db.sh
   
   # 设置自动备份（每天凌晨2点）
   crontab -e
   # 添加：
   0 2 * * * /opt/h5project/scripts/backup_db.sh
   ```

2. **不要删除volume**：
   ```bash
   # ❌ 错误：会删除数据
   docker-compose down -v
   
   # ✅ 正确：只停止容器，保留数据
   docker-compose down
   # 或
   docker-compose stop
   ```

---

## 3. 服务更新时数据一致性

### 更新代码不会影响数据库

**数据存储在Docker volume中，与代码分离：**

```
应用代码（/opt/h5project/）  ← 可以随时更新
    ↓
数据库容器（h5project_db）  ← 数据在volume中
    ↓
Docker Volume（postgres_data） ← 数据持久化存储
```

### 服务更新流程

```bash
# 1. 进入项目目录
cd /opt/h5project

# 2. 拉取最新代码（如果有git）
git pull

# 3. 重新编译
go build -o h5project main.go

# 4. 复制新文件
sudo cp h5project /opt/h5project/
sudo cp -r static/* /opt/h5project/static/

# 5. 重启服务（数据库数据不受影响）
sudo systemctl restart h5project
```

**重要：**
- ✅ 数据库数据**不会丢失**
- ✅ 用户数据、卡片数据**保持不变**
- ✅ 只需要重启应用服务，不需要重启数据库

### 如果添加了新图片

```bash
# 1. 上传新图片到 /opt/h5project/images/
# 2. 运行初始化脚本（只导入新图片，不会删除已有数据）
cd /opt/h5project
./scripts/init_server.sh
```

---

## 4. 数据库迁移和备份

### 备份数据库

```bash
# 手动备份
./scripts/backup_db.sh

# 备份文件保存在：
/opt/h5project/backups/h5project_backup_YYYYMMDD_HHMMSS.sql.gz
```

### 恢复数据库

```bash
# 1. 停止服务
sudo systemctl stop h5project

# 2. 恢复备份
gunzip < /opt/h5project/backups/h5project_backup_20240101_020000.sql.gz | \
  docker exec -i h5project_db psql -U h5user -d h5project

# 3. 启动服务
sudo systemctl start h5project
```

### 迁移到新服务器

```bash
# 1. 在旧服务器备份
./scripts/backup_db.sh

# 2. 复制备份文件到新服务器
scp /opt/h5project/backups/h5project_backup_*.sql.gz user@new-server:/tmp/

# 3. 在新服务器恢复
gunzip < /tmp/h5project_backup_*.sql.gz | \
  docker exec -i h5project_db psql -U h5user -d h5project
```

---

## 5. 检查清单

### 部署前检查

- [ ] 已申请弹性公网IP（EIP）并绑定
- [ ] 确认公网IP地址（使用 `curl ifconfig.me`）
- [ ] 防火墙已开放80和443端口
- [ ] 数据库密码已修改（不使用默认密码）

### 部署后检查

- [ ] 服务正常运行：`sudo systemctl status h5project`
- [ ] 数据库正常运行：`docker ps | grep h5project_db`
- [ ] 可以访问：`curl http://你的公网IP/health`
- [ ] 二维码页面正常：`http://你的公网IP/qrcode.html`
- [ ] 数据库备份脚本已设置

### 定期检查

- [ ] 每周查看一次日志：`sudo journalctl -u h5project -p err`
- [ ] 确认备份正常执行：`ls -lh /opt/h5project/backups/`
- [ ] 检查磁盘空间：`df -h`

---

## 6. 常见问题

### Q: 如何查看Docker volume的实际位置？

```bash
docker volume inspect h5project_postgres_data
```

### Q: 如何手动备份数据库？

```bash
docker exec h5project_db pg_dump -U h5user h5project > backup.sql
```

### Q: 如何查看数据库大小？

```bash
docker exec h5project_db psql -U h5user -d h5project -c \
  "SELECT pg_size_pretty(pg_database_size('h5project'));"
```

### Q: 如何查看volume大小？

```bash
docker system df -v | grep postgres_data
```

---

## 📝 总结

1. **IP地址**：使用弹性公网IP（EIP），确保二维码地址不变
2. **数据存储**：在Docker volume中，重启服务不会丢失
3. **服务更新**：只更新代码，数据库数据保持不变
4. **数据备份**：设置自动备份，定期检查备份文件

