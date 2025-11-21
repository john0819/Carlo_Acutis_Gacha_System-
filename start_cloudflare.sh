#!/bin/bash
# Cloudflare Tunnel 启动脚本

echo "🚀 启动 Cloudflare Tunnel 内网穿透服务..."
echo ""

# 检查 cloudflared 是否安装
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared 未安装"
    echo ""
    echo "📥 安装方法："
    echo "brew install cloudflared"
    echo ""
    exit 1
fi

# 检查服务器是否运行在8080端口
if ! lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  警告: 端口 8080 未被占用，请先启动服务器:"
    echo "   go run main.go"
    echo ""
    read -p "是否继续启动 Cloudflare Tunnel? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ 正在启动 Cloudflare Tunnel，将本地 8080 端口映射到公网..."
echo "📱 Cloudflare 会提供一个公网地址，将其输入到二维码生成器即可"
echo ""

# 启动 Cloudflare Tunnel
cloudflared tunnel --url http://localhost:8080

