#!/bin/bash
# 快速启动脚本 - 不需要Nginx和systemd，直接运行
# 使用方法: ./scripts/quick_start.sh

set -e

echo "🚀 快速启动 H5Project..."
echo ""

# 获取脚本所在目录的父目录（项目根目录）
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 检查并启动数据库
echo "🗄️  步骤1: 检查数据库..."
if command -v docker &> /dev/null; then
    if docker ps | grep -q h5project_db; then
        echo "✅ 数据库已在运行"
    else
        echo "启动数据库..."
        # 兼容新旧版本的docker-compose命令
        if command -v docker-compose &> /dev/null; then
            docker-compose -f deploy/docker-compose.prod.yml up -d
        elif docker compose version &> /dev/null; then
            docker compose -f deploy/docker-compose.prod.yml up -d
        else
            echo "❌ 错误: 未找到docker-compose或docker compose命令"
            echo "   请安装: yum install -y docker-compose"
            echo "   或者使用新版本Docker（自带docker compose）"
            exit 1
        fi
        echo "⏳ 等待数据库启动..."
        sleep 5
        echo "✅ 数据库已启动"
    fi
else
    echo "❌ 错误: 未检测到Docker"
    echo "   请先安装Docker: yum install -y docker"
    exit 1
fi

# 2. 检查数据库连接
echo ""
echo "🔍 步骤2: 检查数据库连接..."
if ! PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -c "SELECT 1;" > /dev/null 2>&1; then
    echo "⚠️  数据库连接失败，等待数据库完全启动..."
    sleep 5
    if ! PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -c "SELECT 1;" > /dev/null 2>&1; then
        echo "❌ 数据库连接失败，请检查："
        echo "   1. Docker容器是否运行: docker ps | grep h5project_db"
        echo "   2. 数据库日志: docker logs h5project_db"
        exit 1
    fi
fi
echo "✅ 数据库连接正常"

# 3. 初始化数据库表结构（如果需要）
echo ""
echo "📊 步骤3: 检查数据库表结构..."
TABLE_EXISTS=$(PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users');" 2>/dev/null | tr -d ' ')
if [ "$TABLE_EXISTS" != "t" ]; then
    echo "初始化数据库表结构..."
    if [ -f "init.sql" ]; then
        PGPASSWORD=h5pass123 psql -h localhost -U h5user -d h5project -f init.sql > /dev/null 2>&1
        echo "✅ 数据库表结构初始化完成"
    else
        echo "⚠️  未找到 init.sql 文件"
    fi
else
    echo "✅ 数据库表已存在"
fi

# 4. 编译Go程序
echo ""
echo "📦 步骤4: 编译Go程序..."
if [ ! -f "go.mod" ]; then
    echo "❌ 错误: 未找到 go.mod 文件"
    exit 1
fi

# 下载依赖
if [ ! -f "go.sum" ]; then
    echo "下载Go依赖..."
    go mod download
fi

# 编译
go build -o h5project main.go
if [ ! -f "h5project" ]; then
    echo "❌ 编译失败"
    exit 1
fi
echo "✅ 编译完成"

# 5. 检查端口是否被占用
echo ""
echo "🔍 步骤5: 检查端口8080..."
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
    echo "⚠️  端口8080已被占用"
    PID=$(lsof -ti :8080 2>/dev/null || netstat -tlnp 2>/dev/null | grep ":8080 " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    if [ -n "$PID" ]; then
        echo "   占用进程PID: $PID"
        read -p "是否停止该进程？(y/N): " kill_confirm
        if [ "$kill_confirm" = "y" ] || [ "$kill_confirm" = "Y" ]; then
            kill $PID 2>/dev/null || kill -9 $PID 2>/dev/null
            sleep 1
            echo "✅ 进程已停止"
        else
            echo "❌ 请手动停止占用8080端口的进程"
            exit 1
        fi
    fi
fi

# 6. 启动服务
echo ""
echo "🚀 步骤6: 启动服务..."
echo "   服务将在端口 8080 运行"
echo "   访问地址: http://$(hostname -I | awk '{print $1}'):8080"
echo "   或: http://localhost:8080"
echo ""
echo "   按 Ctrl+C 停止服务"
echo ""

# 设置环境变量
export PORT=8080
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=h5user
export DB_PASSWORD=h5pass123
export DB_NAME=h5project
export DB_SSLMODE=disable

# 前台运行（可以看到日志）
./h5project

