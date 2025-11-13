#!/bin/bash
# 部署到新目录的自动化脚本
# 使用方法: ./scripts/deploy_to_new_dir.sh [目标目录] [git_url]
# 示例: ./scripts/deploy_to_new_dir.sh /home/admin/h5project

set -e

# 默认值
TARGET_DIR=${1:-/home/admin/h5project}
GIT_URL=${2:-https://github.com/john0819/Carlo_Acutis_Gacha_System-.git}
PROJECT_NAME=$(basename "$GIT_URL" .git)

echo "🚀 开始部署到新目录..."
echo "   目标目录: $TARGET_DIR"
echo "   Git仓库: $GIT_URL"
echo ""

# 检查是否在服务器上
if [ ! -d "/etc/nginx" ] && [ ! -d "/etc/systemd" ]; then
    echo "⚠️  警告: 未检测到Nginx或systemd，可能不在服务器上"
    read -p "继续执行？(y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        exit 0
    fi
fi

# 1. 创建目标目录的父目录
echo "📁 步骤1: 创建目录..."
PARENT_DIR=$(dirname "$TARGET_DIR")
sudo mkdir -p "$PARENT_DIR"
echo "✅ 目录准备完成"
echo ""

# 2. 克隆或更新项目
echo "📥 步骤2: 克隆/更新项目..."
if [ -d "$TARGET_DIR/.git" ]; then
    echo "   项目已存在，更新中..."
    cd "$TARGET_DIR"
    git pull
else
    echo "   克隆项目中..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone "$GIT_URL" "$PROJECT_NAME"
    sudo mv "$PROJECT_NAME" "$TARGET_DIR"
    cd "$TARGET_DIR"
    rm -rf "$TEMP_DIR"
fi
echo "✅ 项目代码准备完成"
echo ""

# 3. 更新部署配置中的路径
echo "⚙️  步骤3: 更新配置文件..."
cd "$TARGET_DIR"

# 更新 deploy.sh
if [ -f "deploy/deploy.sh" ]; then
    sed -i.bak "s|PROJECT_DIR=\".*\"|PROJECT_DIR=\"$TARGET_DIR\"|g" deploy/deploy.sh
    echo "   ✅ 已更新 deploy/deploy.sh"
fi

# 更新 h5project.service
if [ -f "deploy/h5project.service" ]; then
    sed -i.bak "s|WorkingDirectory=.*|WorkingDirectory=$TARGET_DIR|g" deploy/h5project.service
    sed -i.bak "s|ExecStart=.*|ExecStart=$TARGET_DIR/h5project|g" deploy/h5project.service
    echo "   ✅ 已更新 deploy/h5project.service"
fi

# 更新 nginx.conf
if [ -f "deploy/nginx.conf" ]; then
    sed -i.bak "s|root /opt/h5project|root $TARGET_DIR|g" deploy/nginx.conf
    echo "   ✅ 已更新 deploy/nginx.conf"
fi

echo "✅ 配置更新完成"
echo ""

# 4. 设置权限
echo "🔐 步骤4: 设置权限..."
sudo chown -R www-data:www-data "$TARGET_DIR" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"
# images目录设置为可写（用于文件管理器上传）
sudo chmod 775 "$TARGET_DIR/images" 2>/dev/null || true
echo "✅ 权限设置完成"
echo ""

# 5. 编译Go程序
echo "📦 步骤5: 编译Go程序..."
if command -v go &> /dev/null; then
    go build -o h5project main.go
    sudo chmod +x h5project
    echo "✅ 编译完成"
else
    echo "⚠️  未检测到Go，跳过编译"
fi
echo ""

# 6. 询问是否运行部署脚本
read -p "是否运行完整部署脚本？(y/N): " run_deploy
if [ "$run_deploy" = "y" ] || [ "$run_deploy" = "Y" ]; then
    echo ""
    echo "🚀 运行部署脚本..."
    sudo chmod +x deploy/*.sh scripts/*.sh
    sudo ./deploy/deploy.sh
else
    echo ""
    echo "📋 手动部署步骤："
    echo "   1. cd $TARGET_DIR"
    echo "   2. sudo chmod +x deploy/*.sh scripts/*.sh"
    echo "   3. sudo ./deploy/deploy.sh"
fi

echo ""
echo "=================================================="
echo "✅ 部署准备完成！"
echo ""
echo "📋 项目位置: $TARGET_DIR"
echo ""
echo "💡 下一步："
echo "   1. 上传图片到: $TARGET_DIR/images"
echo "   2. 运行初始化: cd $TARGET_DIR && ./scripts/init_server.sh"
echo "   3. 检查服务: sudo systemctl status h5project"
echo ""

