#!/bin/bash
# 查找服务器IP地址脚本
# 在服务器上运行

echo "🔍 查找服务器IP地址..."
echo ""

# 方法1: 公网IP
echo "📡 公网IP地址:"
curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "无法获取"
echo ""

# 方法2: 所有网络接口
echo "🌐 所有网络接口:"
ip addr show | grep -E "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1
echo ""

# 方法3: 阿里云ECS实例元数据（如果在阿里云）
if curl -s http://100.100.100.200/latest/meta-data/public-ipv4 > /dev/null 2>&1; then
    echo "☁️  阿里云公网IP:"
    curl -s http://100.100.100.200/latest/meta-data/public-ipv4
    echo ""
fi

echo "💡 提示:"
echo "   使用公网IP访问: http://你的公网IP/login.html"
echo "   使用公网IP生成二维码: http://你的公网IP/qrcode.html"

