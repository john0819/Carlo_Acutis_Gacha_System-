#!/bin/bash
# ngrok 内网穿透启动脚本

echo "🚀 启动 ngrok 内网穿透服务..."
echo ""

# 检查 ngrok 是否安装
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok 未安装"
    echo ""
    echo "📥 安装方法："
    echo "1. 访问 https://ngrok.com/download 下载"
    echo "2. 或者使用 Homebrew: brew install ngrok/ngrok/ngrok"
    echo ""
    echo "🔑 首次使用需要注册并获取 authtoken："
    echo "1. 访问 https://dashboard.ngrok.com/signup 注册账号"
    echo "2. 获取 authtoken"
    echo "3. 运行: ngrok config add-authtoken YOUR_TOKEN"
    echo ""
    exit 1
fi

# 检查服务器是否运行在8080端口
if ! lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  警告: 端口 8080 未被占用，请先启动服务器:"
    echo "   go run main.go"
    echo ""
    read -p "是否继续启动 ngrok? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ 正在启动 ngrok，将本地 8080 端口映射到公网..."
echo "📱 ngrok 会提供一个公网地址，将其输入到二维码生成器即可"
echo ""

# 启动 ngrok
ngrok http 8080

