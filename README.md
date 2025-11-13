# H5抽卡系统项目

一个基于Go开发的H5抽卡系统，支持用户注册、登录、每日抽卡等功能。

## 功能特点

- 📱 响应式设计，适配手机和桌面端
- 🎲 每日抽卡系统，随机获得卡片
- 👤 用户注册登录系统
- 🎨 现代化的UI设计
- 🚀 高性能Go服务器
- 🔐 JWT认证
- 📊 PostgreSQL数据库

## 📚 快速开始

**👉 详细启动指南请查看：[QUICK_START.md](./QUICK_START.md)**

### 本地开发（快速）

```bash
# 1. 启动数据库
./start_db.sh

# 2. 启动开发服务器
./dev.sh
```

访问：http://localhost:8080

### 本地 + 公网访问 + 二维码（一键启动）⭐推荐

```bash
# 一键启动：数据库 + 服务器 + 内网穿透 + 自动打开二维码页面
./start_with_tunnel.sh
```

### 本地 + 公网访问（手动分步）

```bash
# 终端1：启动服务
./start_db.sh && ./dev.sh

# 终端2：启动内网穿透
./start_ngrok.sh  # 或 ./start_cloudflare.sh

# 然后访问: 公网地址/qrcode.html 生成二维码
```

### 服务器部署

```bash
# 快速测试模式
./scripts/quick_start.sh

# 完整部署（生产环境）
./deploy/deploy.sh
```

## 项目结构

```
h5Project/
├── main.go              # Go服务器主文件
├── go.mod              # Go模块文件
├── static/             # 静态文件目录
│   ├── *.html          # H5页面
│   └── *.json          # 配置文件
├── images/             # 图片目录
│   └── card*.png       # 卡片图片
├── handlers/           # 请求处理器
├── models/             # 数据模型
├── database/           # 数据库相关
├── auth/               # 认证相关
├── config/             # 配置相关
├── deploy/             # 部署相关
├── scripts/            # 脚本文件
└── QUICK_START.md      # 快速启动指南
```

## 主要脚本说明

### 本地开发脚本
- `start_db.sh` - 启动数据库
- `dev.sh` - 开发模式启动（显示日志）
- `stop.sh` - 停止所有服务
- `start_with_tunnel.sh` - **一键启动（数据库+服务器+内网穿透+二维码）** ⭐推荐
- `start_ngrok.sh` - ngrok内网穿透（单独使用）
- `start_cloudflare.sh` - Cloudflare内网穿透（单独使用）

### 服务器部署脚本
- `scripts/quick_start.sh` - 快速启动（测试模式）
- `scripts/start_db_server.sh` - 启动数据库
- `scripts/init_server.sh` - 初始化服务器
- `scripts/upload_images.sh` - 上传图片到服务器
- `scripts/setup_ssh_key.sh` - 配置SSH密钥
- `deploy/deploy.sh` - 完整部署（生产环境）

## 文档

- **[QUICK_START.md](./QUICK_START.md)** - 详细的快速启动指南（本地和服务器）
- **README.md** - 项目说明（本文件）

## 技术栈

- **后端**: Go 1.19+
- **数据库**: PostgreSQL 15
- **容器**: Docker & Docker Compose
- **认证**: JWT
- **前端**: HTML/CSS/JavaScript

## 注意事项

- 确保已安装 Docker（用于运行数据库）
- 确保已安装 Go 1.19+
- 服务器部署需要安装 Docker 和 Go
- 图片文件建议使用png格式，命名规范：card001.png, card002.png...

## 获取帮助

遇到问题？查看 [QUICK_START.md](./QUICK_START.md) 中的"常见问题"部分。

