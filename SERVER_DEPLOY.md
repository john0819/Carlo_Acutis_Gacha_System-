# 🚀 服务器部署流程

## 前置要求
- Go 1.19+
- Docker & Docker Compose
- Nginx
- Git

---

## 完整部署流程

### 1. Clone 代码
```bash
cd /opt
sudo git clone <你的git仓库地址> h5project
cd h5project
```

### 2. 启动数据库
```bash
# 使用生产环境配置启动数据库
docker compose -f deploy/docker-compose.prod.yml up -d

# 等待数据库启动（约5秒）
sleep 5
```

### 3. 初始化数据库和导入图片（重要！）
```bash
# 运行初始化脚本（会创建表结构并导入所有图片到数据库）
./scripts/init_server.sh
```

**这一步会：**
- 创建数据库表结构
- 扫描 `images/` 目录下的所有 `card*.png` 图片
- 将图片路径导入到数据库的 `cards` 表

### 4. 一键部署（推荐）
```bash
# 自动完成：编译、复制文件、配置服务、启动
./deploy/deploy.sh
```

---

## 手动部署（如果自动部署失败）

### 4.1 编译程序
```bash
go build -o h5project main.go
```

### 4.2 创建目录并复制文件
```bash
sudo mkdir -p /opt/h5project/{static,images}
sudo cp h5project /opt/h5project/
sudo cp -r static/* /opt/h5project/static/
sudo cp -r images/* /opt/h5project/images/
sudo cp deploy/h5project.service /etc/systemd/system/
sudo cp deploy/nginx.conf /etc/nginx/sites-available/h5project
```

### 4.3 配置服务
```bash
# 配置 systemd
sudo systemctl daemon-reload
sudo systemctl enable h5project

# 配置 Nginx
sudo ln -s /etc/nginx/sites-available/h5project /etc/nginx/sites-enabled/
sudo nginx -t  # 测试配置
```

### 4.4 启动服务
```bash
sudo systemctl start h5project
sudo systemctl restart nginx
```

---

## 验证部署

### 检查服务状态
```bash
# 检查应用服务
sudo systemctl status h5project

# 检查数据库
docker ps | grep h5project_db

# 测试健康检查
curl http://localhost:8080/health
```

### 查看日志
```bash
# 应用日志
sudo journalctl -u h5project -f

# Nginx日志
sudo tail -f /var/log/nginx/h5project_access.log
```

---

## 📱 生成二维码

部署完成后，访问以下地址生成二维码：

### 方式1：自动检测地址（推荐）
```
http://你的服务器IP或域名/qrcode.html
```

**说明：**
- 页面会自动检测当前访问地址
- 自动生成登录页面的二维码
- 可以直接使用，也可以手动修改地址

### 方式2：手动输入地址
如果自动检测的地址不对，可以：
1. 访问 `http://你的服务器IP或域名/qrcode.html`
2. 在输入框中手动输入正确的访问地址（如：`http://你的服务器IP/login.html`）
3. 点击"生成二维码"按钮

### 使用二维码
- 用手机扫描生成的二维码
- 手机浏览器会自动打开登录页面
- 可以打印或保存二维码用于展示

**示例：**
47.111.226.140
- 如果服务器IP是 `123.456.789.0`，访问：`http://123.456.789.0/qrcode.html`
- 如果使用域名 `example.com`，访问：`http://example.com/qrcode.html`

---

## 重要说明

### 关于图片导入
- **首次部署必须运行** `./scripts/init_server.sh`
- **添加新图片后**：需要重新运行 `./scripts/init_server.sh` 导入新图片
- **图片文件命名**：必须是 `card001.png`, `card002.png` 等格式
- **图片位置**：放在 `images/` 目录下

### 关于数据库
- 数据库密码默认：`h5pass123`（**生产环境请修改！**）
- 数据库名：`h5project`
- 用户名：`h5user`

### 关于配置
- 应用端口：`8080`（内部）
- Nginx端口：`80`（外部）
- 配置文件：`deploy/h5project.service`（修改JWT密钥和数据库密码）

---

## 常见问题

### 图片不显示
```bash
# 检查图片是否已导入数据库
./scripts/check_images.sh

# 如果未导入，运行初始化脚本
./scripts/init_server.sh
```

### 服务启动失败
```bash
# 查看错误日志
sudo journalctl -u h5project -n 50

# 检查数据库是否运行
docker ps | grep h5project_db
```

### 数据库连接失败
```bash
# 重启数据库
docker-compose -f deploy/docker-compose.prod.yml restart

# 检查数据库日志
docker logs h5project_db
```

---

## 快速命令参考

```bash
# 启动数据库
docker-compose -f deploy/docker-compose.prod.yml up -d

# 初始化数据库和图片
./scripts/init_server.sh

# 一键部署
./deploy/deploy.sh

# 重启服务
sudo systemctl restart h5project

# 查看日志
sudo journalctl -u h5project -f

# 检查状态
sudo systemctl status h5project
```

