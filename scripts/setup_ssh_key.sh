#!/bin/bash
# 配置SSH密钥脚本
# 使用方法: ./scripts/setup_ssh_key.sh 服务器IP [用户名] [密码]

# 不使用 set -e，因为我们需要在失败时继续执行以显示手动添加说明

if [ -z "$1" ]; then
    echo "❌ 错误: 请提供服务器IP地址"
    echo "使用方法: ./scripts/setup_ssh_key.sh 服务器IP [用户名] [密码]"
    exit 1
fi

SERVER_IP=$1
SERVER_USER=${2:-admin}
SERVER_PASS=$3

echo "🔑 配置SSH密钥..."
echo ""

# 检查是否已有SSH密钥
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "📝 生成SSH密钥..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "h5project_deploy"
    echo "✅ SSH密钥已生成"
else
    echo "✅ 使用现有SSH密钥"
fi

echo ""
echo "📤 尝试复制公钥到服务器..."
echo "   服务器: $SERVER_USER@$SERVER_IP"
echo ""

# 读取公钥内容
PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

# 尝试使用ssh-copy-id
if [ -n "$SERVER_PASS" ]; then
    # 如果提供了密码，尝试使用sshpass
    if command -v sshpass &> /dev/null; then
        echo "🔐 使用密码认证..."
        sshpass -p "$SERVER_PASS" ssh-copy-id -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ SSH密钥配置完成！"
            echo ""
            echo "💡 现在可以使用以下命令上传图片："
            echo "   ./scripts/upload_images.sh $SERVER_IP"
            exit 0
        fi
    else
        echo "⚠️  需要安装sshpass来使用密码认证"
        echo "   安装方法: brew install hudochenkov/sshpass/sshpass (macOS)"
    fi
else
    # 尝试不使用密码（需要服务器已配置密码认证）
    echo "⚠️  尝试使用密码认证（如果服务器支持）..."
    if ssh-copy-id -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP 2>&1; then
        echo ""
        echo "✅ SSH密钥配置完成！"
        echo ""
        echo "💡 现在可以使用以下命令上传图片："
        echo "   ./scripts/upload_images.sh $SERVER_IP"
        exit 0
    fi
fi

# 如果自动复制失败，显示手动添加说明
echo ""
echo "❌ 自动复制公钥失败（服务器可能禁用了密码认证）"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 请手动将以下公钥添加到服务器："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$PUBLIC_KEY"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔧 手动添加方法（选择其中一种）："
echo ""
echo "方法1: 通过服务器控制台（推荐）"
echo "   1. 登录服务器控制台（如阿里云、腾讯云等）"
echo "   2. 执行以下命令："
echo ""
echo "      mkdir -p ~/.ssh"
echo "      chmod 700 ~/.ssh"
echo "      echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys"
echo "      chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "方法2: 如果服务器支持密码登录"
echo "   1. 运行: ./scripts/setup_ssh_key.sh $SERVER_IP $SERVER_USER 你的密码"
echo "   2. 或者安装sshpass后重试"
echo ""
echo "方法3: 使用临时密码认证（如果服务器支持）"
echo "   1. 确保服务器 /etc/ssh/sshd_config 中 PasswordAuthentication yes"
echo "   2. 重启SSH服务: sudo systemctl restart sshd"
echo "   3. 然后重新运行此脚本"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

