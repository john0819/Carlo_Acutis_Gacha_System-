#!/bin/bash
# 更新脚本 - 在服务器上运行
# 使用方法: ./deploy/update.sh
# 或者: cd /opt/h5project && ./deploy/update.sh

set -e

PROJECT_DIR="/opt/h5project"
SERVICE_NAME="h5project"

echo "🔄 开始更新 H5Project..."
echo ""

# 检查是否在服务器上
if [ ! -d "/etc/nginx" ]; then
    echo "❌ 错误: 未检测到Nginx，请确保在服务器上运行此脚本"
    exit 1
fi

# 获取当前目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 如果是在代码仓库目录运行
if [ -f "$REPO_DIR/main.go" ]; then
    echo "📦 检测到代码仓库目录: $REPO_DIR"
    cd "$REPO_DIR"
    
    # 1. 拉取最新代码（如果使用Git）
    if [ -d ".git" ]; then
        echo ""
        echo "📥 步骤1: 拉取最新代码..."
        git pull || {
            echo "⚠️  Git pull 失败，继续使用当前代码..."
        }
        echo "✅ 代码更新完成"
    else
        echo "⚠️  未检测到Git仓库，跳过代码拉取"
    fi
    
    # 2. 编译Go程序
    echo ""
    echo "🔨 步骤2: 编译Go程序..."
    go build -o h5project main.go
    if [ ! -f "h5project" ]; then
        echo "❌ 编译失败"
        exit 1
    fi
    echo "✅ 编译完成"
    
    # 3. 复制更新的文件
    echo ""
    echo "📋 步骤3: 复制更新的文件..."
    sudo cp h5project $PROJECT_DIR/
    sudo cp -r static/* $PROJECT_DIR/static/
    sudo cp -r images/* $PROJECT_DIR/images/ 2>/dev/null || true
    sudo cp init.sql $PROJECT_DIR/ 2>/dev/null || true
    
    # 复制脚本文件（如果有更新）
    if [ -d "scripts" ]; then
        sudo mkdir -p $PROJECT_DIR/scripts
        sudo cp -r scripts/* $PROJECT_DIR/scripts/ 2>/dev/null || true
        sudo chmod +x $PROJECT_DIR/scripts/*.sh 2>/dev/null || true
    fi
    
    sudo chmod +x $PROJECT_DIR/h5project
    echo "✅ 文件复制完成"
    
# 如果是在部署目录运行（/opt/h5project）
elif [ -f "$PROJECT_DIR/h5project" ]; then
    echo "📦 检测到部署目录: $PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # 如果部署目录是Git仓库，可以拉取更新
    if [ -d ".git" ]; then
        echo ""
        echo "📥 步骤1: 拉取最新代码..."
        git pull || {
            echo "⚠️  Git pull 失败，请手动检查"
            exit 1
        }
        echo "✅ 代码更新完成"
        
        # 编译Go程序
        echo ""
        echo "🔨 步骤2: 编译Go程序..."
        go build -o h5project main.go
        if [ ! -f "h5project" ]; then
            echo "❌ 编译失败"
            exit 1
        fi
        echo "✅ 编译完成"
        
        # 复制更新的静态文件
        echo ""
        echo "📋 步骤3: 更新静态文件..."
        # 静态文件已经在仓库中，不需要额外复制
        sudo chmod +x h5project
        echo "✅ 文件更新完成"
    else
        echo "❌ 错误: 部署目录不是Git仓库"
        echo "   请从代码仓库目录运行此脚本，或手动更新文件"
        exit 1
    fi
else
    echo "❌ 错误: 未找到项目目录"
    echo "   请确保在代码仓库目录或部署目录运行此脚本"
    exit 1
fi

# 4. 检查数据库是否需要更新
echo ""
echo "🗄️  步骤4: 检查数据库更新..."
cd $PROJECT_DIR

# 检查是否有数据库迁移脚本需要运行
if [ -f "scripts/update_docker_db.sh" ]; then
    echo "   发现数据库更新脚本，是否运行？(y/n)"
    read -t 10 -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x scripts/update_docker_db.sh
        ./scripts/update_docker_db.sh || {
            echo "⚠️  数据库更新脚本执行失败，请手动检查"
        }
    fi
fi

# 5. 重启服务
echo ""
echo "🚀 步骤5: 重启服务..."
sudo systemctl restart $SERVICE_NAME
sleep 2

if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ 服务重启成功"
else
    echo "❌ 服务重启失败，查看日志: sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

# 6. 重启Nginx（确保配置更新生效）
echo ""
echo "🔄 步骤6: 重启Nginx..."
sudo systemctl reload nginx
echo "✅ Nginx已重新加载配置"

echo ""
echo "=================================================="
echo "✅ 更新完成！"
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

