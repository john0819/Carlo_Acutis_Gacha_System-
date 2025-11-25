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

# 获取项目根目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. 编译Go程序
echo "📦 步骤1: 编译Go程序..."
cd "$ROOT_DIR"
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

# 3. 停止服务（如果正在运行）
echo ""
echo "🛑 步骤3: 停止服务（如果正在运行）..."
if sudo systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
    echo "   服务正在运行，正在停止..."
    sudo systemctl stop $SERVICE_NAME
    sleep 2
    echo "✅ 服务已停止"
else
    echo "   服务未运行，跳过"
fi

# 确保没有残留进程
sudo pkill -f "$PROJECT_DIR/h5project" 2>/dev/null || true
sleep 1

# 4. 复制文件
echo ""
echo "📋 步骤4: 复制文件..."
sudo cp "$ROOT_DIR/h5project" $PROJECT_DIR/
sudo cp -r "$ROOT_DIR/static"/* $PROJECT_DIR/static/
sudo mkdir -p $PROJECT_DIR/images
sudo cp -r "$ROOT_DIR/images"/* $PROJECT_DIR/images/ 2>/dev/null || true
sudo cp "$ROOT_DIR/docker-compose.yml" $PROJECT_DIR/ 2>/dev/null || true
sudo cp "$ROOT_DIR/deploy/docker-compose.prod.yml" $PROJECT_DIR/ 2>/dev/null || true
sudo cp "$ROOT_DIR/init.sql" $PROJECT_DIR/
[ -f "$ROOT_DIR/migrate_db.sh" ] && sudo cp "$ROOT_DIR/migrate_db.sh" $PROJECT_DIR/ || true
[ -f "$ROOT_DIR/update_cards_safe.sh" ] && sudo cp "$ROOT_DIR/update_cards_safe.sh" $PROJECT_DIR/ || true
sudo mkdir -p $PROJECT_DIR/scripts
sudo cp -r "$ROOT_DIR/scripts"/* $PROJECT_DIR/scripts/ 2>/dev/null || true
sudo chmod +x $PROJECT_DIR/h5project
[ -f $PROJECT_DIR/*.sh ] && sudo chmod +x $PROJECT_DIR/*.sh 2>/dev/null || true
[ -d $PROJECT_DIR/scripts ] && sudo chmod +x $PROJECT_DIR/scripts/*.sh 2>/dev/null || true

# 3.5 生成 list.json 文件（如果图片目录存在）
echo ""
echo "📝 步骤3.5: 生成图片列表文件..."
if [ -d "$PROJECT_DIR/images" ] && [ -f "$PROJECT_DIR/scripts/generate_list_json.sh" ]; then
    cd $PROJECT_DIR
    sudo chmod +x scripts/generate_list_json.sh
    sudo -E scripts/generate_list_json.sh || echo "⚠️  生成list.json失败，继续部署..."
    # 确保list.json权限正确
    sudo chmod 644 $PROJECT_DIR/images/list.json 2>/dev/null || true
    echo "✅ 图片列表文件生成完成"
else
    echo "⚠️  跳过生成list.json（图片目录或脚本不存在）"
fi

echo "✅ 文件复制完成"

# 5. 配置systemd服务
echo ""
echo "⚙️  步骤5: 配置systemd服务..."
sudo cp "$ROOT_DIR/deploy/h5project.service" /etc/systemd/system/
sudo systemctl daemon-reload
echo "✅ 服务配置完成"

# 6. 配置Nginx
echo ""
echo "🌐 步骤6: 配置Nginx..."
# 检查是否已经配置了HTTPS（存在SSL证书文件）
if [ -f "/etc/nginx/ssl/nginx-selfsigned.crt" ] || [ -d "/etc/letsencrypt/live" ]; then
    echo "   检测到已配置HTTPS，保持HTTPS配置不变"
    # 如果存在HTTPS配置文件，使用它；否则保持现有配置
    if [ -f "$ROOT_DIR/deploy/nginx-https.conf" ]; then
        echo "   更新HTTPS配置文件..."
        sudo cp "$ROOT_DIR/deploy/nginx-https.conf" /etc/nginx/sites-available/$NGINX_SITE
    else
        echo "   ⚠️  未找到nginx-https.conf，保持现有配置"
    fi
else
    echo "   使用HTTP配置..."
    sudo cp "$ROOT_DIR/deploy/nginx.conf" /etc/nginx/sites-available/$NGINX_SITE
fi

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

# 7. 启动数据库（如果使用Docker）
echo ""
echo "🗄️  步骤7: 检查数据库..."
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

# 7.5 初始化数据库和导入图片
echo ""
echo "📊 步骤7.5: 初始化数据库..."
cd $PROJECT_DIR
if [ -f "scripts/init_server.sh" ]; then
    chmod +x scripts/init_server.sh
    ./scripts/init_server.sh
else
    echo "⚠️  未找到初始化脚本，请手动运行: ./scripts/init_server.sh"
fi

# 8. 启动服务
echo ""
echo "🚀 步骤8: 启动服务..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME
sleep 2

if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败，查看日志: sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

# 9. 重启Nginx
echo ""
echo "🔄 步骤9: 重启Nginx..."
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

