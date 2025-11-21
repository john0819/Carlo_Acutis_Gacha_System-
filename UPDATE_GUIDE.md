# 🔄 服务器更新指南

## 快速更新（推荐）

### 方式1：使用更新脚本（最简单）

在**代码仓库目录**运行：
```bash
cd /path/to/h5Project  # 你的代码仓库目录
./deploy/update.sh
```

或者在**服务器部署目录**运行（如果部署目录是Git仓库）：
```bash
cd /opt/h5project
./deploy/update.sh
```

**更新脚本会自动完成：**
1. ✅ Git pull 拉取最新代码
2. ✅ 重新编译Go程序
3. ✅ 复制更新的文件（HTML/CSS/JS等）
4. ✅ 重启服务
5. ✅ 重新加载Nginx配置

---

## 方式2：手动更新步骤

### 1. 登录服务器并进入代码目录

```bash
# 如果代码在 /opt/h5project
cd /opt/h5project

# 或者如果代码在其他位置
cd /path/to/your/code
```

### 2. 拉取最新代码

```bash
git pull origin main
# 或者你使用的分支名
git pull origin master
```

### 3. 重新编译Go程序

```bash
go build -o h5project main.go
```

### 4. 复制更新的文件

```bash
# 复制编译好的程序
sudo cp h5project /opt/h5project/

# 复制静态文件（HTML/CSS/JS）
sudo cp -r static/* /opt/h5project/static/

# 如果有新的图片
sudo cp -r images/* /opt/h5project/images/ 2>/dev/null || true

# 如果有数据库更新脚本
sudo cp -r scripts/* /opt/h5project/scripts/ 2>/dev/null || true
sudo chmod +x /opt/h5project/scripts/*.sh 2>/dev/null || true

# 设置执行权限
sudo chmod +x /opt/h5project/h5project
```

### 5. 更新数据库（如果需要）

如果代码中有数据库结构变更（如新增表、修改表结构），需要运行更新脚本：

```bash
cd /opt/h5project
./scripts/update_docker_db.sh
```

### 6. 重启服务

```bash
# 重启应用服务
sudo systemctl restart h5project

# 重新加载Nginx配置（如果有配置更新）
sudo systemctl reload nginx
```

### 7. 验证更新

```bash
# 检查服务状态
sudo systemctl status h5project

# 查看日志
sudo journalctl -u h5project -f

# 测试健康检查
curl http://localhost/health
```

---

## 更新检查清单

更新前：
- [ ] 确认已提交所有本地更改
- [ ] 确认服务器上的代码已备份（Git会自动处理）
- [ ] 确认数据库已备份（重要！）

更新后：
- [ ] 检查服务是否正常运行：`sudo systemctl status h5project`
- [ ] 检查网站是否可以访问
- [ ] 测试主要功能（登录、抽卡、查看卡包等）
- [ ] 查看日志确认没有错误：`sudo journalctl -u h5project -n 50`

---

## 常见问题

### Q: 更新后服务启动失败怎么办？

```bash
# 查看详细错误日志
sudo journalctl -u h5project -n 100

# 检查Go程序是否编译成功
file /opt/h5project/h5project

# 手动测试运行
sudo -u www-data /opt/h5project/h5project
```

### Q: 更新后静态文件没有变化？

```bash
# 清除浏览器缓存
# 或者强制刷新：Ctrl+F5 (Windows) 或 Cmd+Shift+R (Mac)

# 检查文件是否真的更新了
ls -lh /opt/h5project/static/index.html
cat /opt/h5project/static/index.html | head -20
```

### Q: 数据库更新失败？

```bash
# 检查数据库是否运行
docker ps | grep h5project_db

# 查看数据库日志
docker logs h5project_db

# 手动连接数据库检查
docker exec -it h5project_db psql -U h5user -d h5project
```

### Q: 如何回滚到之前的版本？

```bash
cd /opt/h5project  # 或你的代码目录
git log --oneline  # 查看提交历史
git checkout <之前的commit-hash>  # 切换到之前的版本
./deploy/update.sh  # 重新部署
```

---

## 自动化更新（可选）

如果你想要更自动化的更新流程，可以设置Git钩子或定时任务：

### 设置Git钩子（服务器端）

在服务器上创建 `post-receive` 钩子，当代码push后自动更新：

```bash
# 在服务器上创建钩子
cat > /opt/h5project/.git/hooks/post-receive << 'EOF'
#!/bin/bash
cd /opt/h5project
./deploy/update.sh
EOF

chmod +x /opt/h5project/.git/hooks/post-receive
```

### 定时检查更新（不推荐，但可用）

```bash
# 添加到crontab（每天凌晨3点检查更新）
0 3 * * * cd /opt/h5project && git pull && ./deploy/update.sh >> /var/log/h5project_update.log 2>&1
```

---

## 更新频率建议

- **前端更新（HTML/CSS/JS）**：可以频繁更新，不影响数据库
- **后端更新（Go代码）**：需要重启服务，建议在低峰期更新
- **数据库更新**：需要谨慎，建议先备份，在维护窗口期更新

---

## 快速命令参考

```bash
# 一键更新
cd /path/to/h5Project && ./deploy/update.sh

# 手动更新（三步）
cd /opt/h5project
git pull && go build -o h5project main.go && sudo cp h5project /opt/h5project/ && sudo cp -r static/* /opt/h5project/static/ && sudo systemctl restart h5project

# 查看更新日志
sudo journalctl -u h5project -f

# 检查服务状态
sudo systemctl status h5project
```

