#!/bin/bash
# HTTPS配置脚本
# 使用方法: ./deploy/setup_https.sh [domain|ip]
# domain: 如果有域名，使用Let's Encrypt免费证书
# ip: 如果只有IP，使用自签名证书

set -e

CONFIG_TYPE=${1:-ip}  # 默认使用IP方式

echo "🔒 HTTPS配置脚本"
echo "=================="
echo ""

if [ "$CONFIG_TYPE" = "domain" ]; then
    echo "📋 使用域名方式（Let's Encrypt免费证书）"
    echo ""
    read -p "请输入你的域名（例如: example.com）: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo "❌ 域名不能为空"
        exit 1
    fi
    
    echo ""
    echo "📦 步骤1: 安装Certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
    
    echo ""
    echo "📦 步骤2: 申请SSL证书..."
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    
    echo ""
    echo "✅ SSL证书配置完成！"
    echo "   证书位置: /etc/letsencrypt/live/$DOMAIN/"
    
elif [ "$CONFIG_TYPE" = "ip" ]; then
    echo "📋 使用IP方式（自签名证书）"
    echo "⚠️  注意：自签名证书会在浏览器显示安全警告，但功能正常"
    echo ""
    
    echo "📦 步骤1: 创建SSL证书目录..."
    sudo mkdir -p /etc/nginx/ssl
    
    echo ""
    echo "📦 步骤2: 生成自签名证书..."
    echo "   这将创建一个有效期1年的自签名证书"
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx-selfsigned.key \
        -out /etc/nginx/ssl/nginx-selfsigned.crt \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=47.111.226.140"
    
    echo ""
    echo "✅ 自签名证书生成完成！"
    echo "   证书位置: /etc/nginx/ssl/"
    
else
    echo "❌ 无效的参数: $CONFIG_TYPE"
    echo "   使用方法: $0 [domain|ip]"
    exit 1
fi

echo ""
echo "📦 步骤3: 更新Nginx配置..."
sudo cp deploy/nginx-https.conf /etc/nginx/sites-available/h5project

if [ "$CONFIG_TYPE" = "domain" ]; then
    # 替换域名
    sudo sed -i "s/server_name _;/server_name $DOMAIN;/g" /etc/nginx/sites-available/h5project
    # 取消注释Let's Encrypt证书配置
    sudo sed -i "s|# ssl_certificate /etc/letsencrypt/live/你的域名/fullchain.pem;|ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;|g" /etc/nginx/sites-available/h5project
    sudo sed -i "s|# ssl_certificate_key /etc/letsencrypt/live/你的域名/privkey.pem;|ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;|g" /etc/nginx/sites-available/h5project
    # 注释掉自签名证书配置
    sudo sed -i "s|ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;|# ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;|g" /etc/nginx/sites-available/h5project
    sudo sed -i "s|ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;|# ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;|g" /etc/nginx/sites-available/h5project
fi

echo ""
echo "📦 步骤4: 测试Nginx配置..."
if sudo nginx -t; then
    echo "✅ Nginx配置正确"
else
    echo "❌ Nginx配置错误，请检查"
    exit 1
fi

echo ""
echo "📦 步骤5: 重启Nginx..."
sudo systemctl restart nginx

echo ""
echo "=================================================="
echo "✅ HTTPS配置完成！"
echo ""
if [ "$CONFIG_TYPE" = "domain" ]; then
    echo "🌐 访问地址: https://$DOMAIN"
    echo "   证书有效期: 90天（Let's Encrypt会自动续期）"
else
    echo "🌐 访问地址: https://47.111.226.140"
    echo "⚠️  注意: 浏览器会显示安全警告，点击'高级' -> '继续访问'即可"
    echo "   证书有效期: 1年"
fi
echo ""
echo "📋 检查HTTPS状态:"
echo "   curl -I https://$(hostname -I | awk '{print $1}')"
echo ""

