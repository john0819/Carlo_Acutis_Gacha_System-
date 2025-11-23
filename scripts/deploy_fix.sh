#!/bin/bash
# 部署修复脚本 - 修复兑换查询失败问题

set -e

echo "🔧 开始部署修复..."

# 获取项目目录
PROJECT_DIR="/opt/h5project"
if [ ! -d "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(pwd)"
fi

cd "$PROJECT_DIR"

# 1. 备份当前版本
echo "📦 备份当前版本..."
if [ -f "h5project" ]; then
    cp h5project h5project.backup.$(date +%Y%m%d_%H%M%S)
fi

# 2. 拉取最新代码（如果在git仓库中）
if [ -d ".git" ]; then
    echo "📥 拉取最新代码..."
    git pull || echo "⚠️  Git拉取失败，继续使用当前代码"
fi

# 3. 重新编译
echo "🔨 编译Go程序..."
go build -o h5project main.go
if [ ! -f "h5project" ]; then
    echo "❌ 编译失败"
    exit 1
fi

# 4. 修复数据库（如果还没修复）
echo "🗄️  检查数据库..."
if docker ps | grep -q h5project_db; then
    echo "修复数据库NULL值..."
    docker exec -i h5project_db psql -U h5user -d h5project << 'SQL'
UPDATE users SET exchange_points = 0 WHERE exchange_points IS NULL;
ALTER TABLE users ALTER COLUMN exchange_points SET NOT NULL;
ALTER TABLE users ALTER COLUMN exchange_points SET DEFAULT 0;
SQL
    echo "✅ 数据库修复完成"
else
    echo "⚠️  数据库容器未运行，跳过数据库修复"
fi

# 5. 复制文件到部署目录
echo "📋 复制文件..."
sudo cp h5project "$PROJECT_DIR/"
sudo chmod +x "$PROJECT_DIR/h5project"

# 6. 重启服务
echo "🔄 重启服务..."
sudo systemctl restart h5project
sleep 2

# 7. 检查服务状态
if sudo systemctl is-active --quiet h5project; then
    echo "✅ 服务启动成功"
    echo ""
    echo "📋 检查服务日志:"
    echo "   sudo journalctl -u h5project -n 50 --no-pager"
    echo ""
    echo "🧪 测试接口:"
    echo "   curl http://localhost/health"
else
    echo "❌ 服务启动失败，查看日志:"
    echo "   sudo journalctl -u h5project -n 50 --no-pager"
    exit 1
fi

echo ""
echo "✅ 部署完成！"
