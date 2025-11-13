#!/bin/bash
# 部署脚本 - 在服务器上运行
# 使用方法: ./deploy/deploy.sh

set -e

PROJECT_DIR="/opt/h5project"
SERVICE_NAME="h5project"
NGINX_SITE="h5project"

echo "🚀 开始部署 H5Project..."
echo ""

# 检查是否在服务器上
if [ ! -d "/etc/nginx" ]; then
    echo "❌ 错误: 未检测到Nginx，请确保在服务器上运行此脚本"
    exit 1
fi

# 1. 编译Go程序
echo "📦 步骤1: 编译Go程序..."
cd "$(dirname "$0")/.."
go build -o h5project main.go
if [ ! -f "h5project" ]; then
    echo "❌ 编译失败"
    exit 1
fi
echo "✅ 编译完成"

# 2. 创建项目目录
echo ""
echo "📁 步骤2: 创建项目目录..."
sudo mkdir -p $PROJECT_DIR
sudo mkdir -p $PROJECT_DIR/static
sudo mkdir -p $PROJECT_DIR/images
echo "✅ 目录创建完成"

# 3. 复制文件
echo ""
echo "📋 步骤3: 复制文件..."
sudo cp h5project $PROJECT_DIR/
sudo cp -r static/* $PROJECT_DIR/static/
sudo cp -r images/* $PROJECT_DIR/images/ 2>/dev/null || true
sudo cp docker-compose.yml $PROJECT_DIR/
sudo cp docker-compose.prod.yml $PROJECT_DIR/
sudo cp init.sql $PROJECT_DIR/
sudo cp migrate_db.sh $PROJECT_DIR/
sudo cp update_cards_safe.sh $PROJECT_DIR/
sudo mkdir -p $PROJECT_DIR/scripts
sudo cp -r scripts/* $PROJECT_DIR/scripts/ 2>/dev/null || true
sudo chmod +x $PROJECT_DIR/h5project
sudo chmod +x $PROJECT_DIR/*.sh
sudo chmod +x $PROJECT_DIR/scripts/*.sh 2>/dev/null || true
echo "✅ 文件复制完成"

# 4. 配置systemd服务
echo ""
echo "⚙️  步骤4: 配置systemd服务..."
sudo cp deploy/h5project.service /etc/systemd/system/
sudo systemctl daemon-reload
echo "✅ 服务配置完成"

# 5. 配置Nginx
echo ""
echo "🌐 步骤5: 配置Nginx..."
sudo cp deploy/nginx.conf /etc/nginx/sites-available/$NGINX_SITE
if [ ! -L "/etc/nginx/sites-enabled/$NGINX_SITE" ]; then
    sudo ln -s /etc/nginx/sites-available/$NGINX_SITE /etc/nginx/sites-enabled/
fi

# 测试Nginx配置
if sudo nginx -t; then
    echo "✅ Nginx配置正确"
else
    echo "❌ Nginx配置错误，请检查"
    exit 1
fi

# 6. 启动数据库（如果使用Docker）
echo ""
echo "🗄️  步骤6: 检查数据库..."
if command -v docker &> /dev/null; then
    cd $PROJECT_DIR
    if ! docker ps | grep -q h5project_db; then
        echo "启动数据库..."
        # 兼容新旧版本的docker-compose命令
        if command -v docker-compose &> /dev/null; then
            docker-compose -f docker-compose.prod.yml up -d
        elif docker compose version &> /dev/null; then
            docker compose -f docker-compose.prod.yml up -d
        else
            echo "❌ 错误: 未找到docker-compose或docker compose命令"
            echo "   请安装docker-compose或使用新版本Docker"
            exit 1
        fi
        sleep 5
    fi
    echo "✅ 数据库运行中"
else
    echo "⚠️  未检测到Docker，请手动启动数据库"
fi

# 6.5 初始化数据库和导入图片
echo ""
echo "📊 步骤6.5: 初始化数据库..."
cd $PROJECT_DIR
if [ -f "scripts/init_server.sh" ]; then
    chmod +x scripts/init_server.sh
    ./scripts/init_server.sh
else
    echo "⚠️  未找到初始化脚本，请手动运行: ./scripts/init_server.sh"
fi

# 7. 启动服务
echo ""
echo "🚀 步骤7: 启动服务..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME
sleep 2

if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败，查看日志: sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

# 8. 重启Nginx
echo ""
echo "🔄 步骤8: 重启Nginx..."
sudo systemctl restart nginx
echo "✅ Nginx重启完成"

echo ""
echo "=================================================="
echo "✅ 部署完成！"
echo ""
echo "📋 检查服务状态:"
echo "   sudo systemctl status $SERVICE_NAME"
echo ""
echo "📋 查看日志:"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "📋 测试访问:"
echo "   curl http://localhost/health"
echo ""

