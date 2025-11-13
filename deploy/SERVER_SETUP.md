# 服务器部署步骤

## 完整操作流程

### 1. 克隆代码
```bash
cd ~
git clone https://github.com/john0819/Carlo_Acutis_Gacha_System-.git
cd Carlo_Acutis_Gacha_System-
```

### 2. 安装PostgreSQL客户端（如果还没安装）
```bash
yum install -y postgresql
```

### 3. 生成JWT密钥并修改配置
```bash
# 生成密钥
openssl rand -base64 32

# 修改systemd服务文件中的JWT_SECRET
nano deploy/h5project.service
# 找到第23行，把 JWT_SECRET=... 改为刚才生成的密钥
```

### 4. 修改Nginx配置（如果需要域名）
```bash
nano deploy/nginx.conf
# 第6行 server_name _; 可以不改（用IP访问）
```

### 5. 运行部署脚本
```bash
chmod +x deploy/*.sh scripts/*.sh
./deploy/deploy.sh
```

### 6. 检查服务状态
```bash
# 检查Go服务
systemctl status h5project

# 检查Nginx
systemctl status nginx

# 测试访问
curl http://localhost/health
```

### 7. 开放防火墙端口
```bash
# 开放80端口
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# 或者使用iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```

## 如果部署脚本失败，手动步骤

### 1. 启动数据库
```bash
cd ~/Carlo_Acutis_Gacha_System-
docker-compose -f deploy/docker-compose.prod.yml up -d
```

### 2. 初始化数据库
```bash
./scripts/init_server.sh
```

### 3. 启动服务
```bash
sudo systemctl start h5project
sudo systemctl enable h5project
```

## 常见问题

### 数据库连接失败
检查Docker是否运行：
```bash
docker ps
```

### 图片没有导入
手动运行：
```bash
./scripts/update_cards_server.sh
```

