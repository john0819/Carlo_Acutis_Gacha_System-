# Nginx 配置指南

## 是否需要 Nginx？

### 当前情况（不使用 Nginx）
- ✅ Go 服务器直接处理所有请求（API + 静态文件 + 图片）
- ✅ 简单，适合小规模使用
- ⚠️  Go 服务器需要处理静态文件，占用资源
- ⚠️  没有反向代理保护，直接暴露 Go 服务器

### 使用 Nginx 的优势
- ✅ **性能提升**: Nginx 直接服务静态文件，Go 只处理 API
- ✅ **安全性**: Nginx 作为反向代理，隐藏 Go 服务器
- ✅ **SSL/HTTPS**: 更容易配置 HTTPS
- ✅ **负载均衡**: 未来可以轻松扩展多个 Go 实例
- ✅ **缓存**: 可以缓存静态文件，减少服务器压力

### 使用 Nginx 的复杂度
- 📊 **复杂度**: 中等（需要配置，但不复杂）
- ⏱️ **时间**: 约 30-60 分钟配置
- 📚 **学习成本**: 低（主要是配置文件）

## 推荐方案

### 方案一：不使用 Nginx（适合初期）
**适用场景:**
- 用户量 < 100 人
- 测试阶段
- 快速上线

**优点:**
- 简单，无需额外配置
- 当前代码即可运行

**缺点:**
- 性能不是最优
- 静态文件占用 Go 服务器资源

### 方案二：使用 Nginx（推荐生产环境）
**适用场景:**
- 用户量 > 100 人
- 生产环境部署
- 需要 HTTPS

**优点:**
- 性能更好
- 更安全
- 支持 HTTPS
- 易于扩展

**缺点:**
- 需要额外配置
- 需要学习 Nginx 基础

## Nginx 配置示例

### 基本配置（生产环境）

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 替换为你的域名或IP

    # 静态文件（HTML, CSS, JS）
    location / {
        root /opt/h5project/static;
        try_files $uri $uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    # 图片文件
    location /images/ {
        root /opt/h5project;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # API 请求转发到 Go 服务器
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

### HTTPS 配置（使用 Let's Encrypt）

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL 配置（安全最佳实践）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 静态文件
    location / {
        root /opt/h5project/static;
        try_files $uri $uri/ /index.html;
    }

    # 图片
    location /images/ {
        root /opt/h5project;
        expires 7d;
    }

    # API
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 部署步骤（使用 Nginx）

### 1. 安装 Nginx
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx -y

# CentOS/RHEL
sudo yum install nginx -y
```

### 2. 创建配置文件
```bash
sudo nano /etc/nginx/sites-available/h5project
# 复制上面的配置，修改路径和域名
```

### 3. 启用配置
```bash
sudo ln -s /etc/nginx/sites-available/h5project /etc/nginx/sites-enabled/
sudo nginx -t  # 测试配置
sudo systemctl restart nginx
```

### 4. 配置 SSL（可选）
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

## 性能对比

| 指标 | 不使用 Nginx | 使用 Nginx |
|------|-------------|-----------|
| 静态文件响应 | Go 处理 | Nginx 直接服务（更快） |
| API 响应 | 直接 | 反向代理（略慢 1-2ms） |
| 并发能力 | 依赖 Go | Nginx 处理静态，Go 专注 API |
| 内存占用 | Go 较高 | 分散到 Nginx + Go |
| 配置复杂度 | 简单 | 中等 |

## 建议

### 初期（现在）
- ✅ **不使用 Nginx**，先测试功能
- ✅ 使用当前的 Go 服务器直接运行
- ✅ 验证所有功能正常

### 生产环境（部署时）
- ✅ **使用 Nginx**，提升性能和安全性
- ✅ 配置 HTTPS
- ✅ 优化静态文件缓存

## 总结

**是否需要 Nginx？**
- 测试阶段：**不需要**
- 生产环境：**推荐使用**

**复杂度？**
- 配置 Nginx：**中等**（30-60分钟）
- 维护成本：**低**（配置一次即可）

**建议：**
1. 现在先不用 Nginx，专注功能测试
2. 部署到服务器时再配置 Nginx
3. 我会提供完整的 Nginx 配置文件

