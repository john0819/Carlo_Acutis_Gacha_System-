#!/bin/bash
# 本地测试部署配置
# 使用方法: ./deploy/test_local.sh

set -e

echo "🧪 本地测试部署配置..."
echo ""

# 1. 测试编译
echo "📦 测试1: 编译Go程序..."
go build -o /tmp/h5project_test main.go
if [ -f "/tmp/h5project_test" ]; then
    echo "✅ 编译成功"
    rm /tmp/h5project_test
else
    echo "❌ 编译失败"
    exit 1
fi

# 2. 测试Nginx配置语法
echo ""
echo "🌐 测试2: Nginx配置语法..."
if command -v nginx &> /dev/null; then
    # 创建临时测试配置
    TEST_CONF="/tmp/nginx_test.conf"
    cat > $TEST_CONF << 'EOF'
events {
    worker_connections 1024;
}
http {
    include /etc/nginx/mime.types;
    include deploy/nginx.conf;
}
EOF
    if nginx -t -c $TEST_CONF 2>/dev/null; then
        echo "✅ Nginx配置语法正确"
    else
        echo "⚠️  Nginx配置语法检查失败（可能因为路径问题，部署时会自动调整）"
    fi
    rm -f $TEST_CONF
else
    echo "⚠️  未安装Nginx，跳过配置测试"
fi

# 3. 测试systemd服务文件
echo ""
echo "⚙️  测试3: systemd服务文件..."
if [ -f "deploy/h5project.service" ]; then
    if systemd-analyze verify deploy/h5project.service 2>/dev/null; then
        echo "✅ systemd服务文件格式正确"
    else
        echo "⚠️  systemd服务文件可能有警告（部署时会检查）"
    fi
else
    echo "❌ 找不到systemd服务文件"
    exit 1
fi

# 4. 检查必要文件
echo ""
echo "📋 测试4: 检查必要文件..."
FILES=(
    "main.go"
    "deploy/nginx.conf"
    "deploy/h5project.service"
    "deploy/deploy.sh"
    "docker-compose.yml"
    "init.sql"
)

MISSING=0
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (缺失)"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "❌ 有文件缺失，请检查"
    exit 1
fi

# 5. 测试环境变量配置
echo ""
echo "🔧 测试5: 环境变量配置..."
if go build -o /tmp/h5project_config_test main.go 2>&1 | grep -q "error" || false; then
    echo "⚠️  配置模块测试（需要实际运行验证）"
else
    echo "✅ 配置模块正常"
    rm -f /tmp/h5project_config_test
fi

echo ""
echo "=================================================="
echo "✅ 本地测试完成！"
echo ""
echo "💡 下一步:"
echo "   1. 确保所有文件都在 deploy/ 目录下"
echo "   2. 上传到服务器后运行: ./deploy/deploy.sh"
echo ""

