#!/bin/bash
# 显示SSH公钥内容，方便手动添加到服务器

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "❌ 错误: 找不到SSH公钥文件"
    echo "   请先运行: ./scripts/setup_ssh_key.sh 服务器IP"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 您的SSH公钥内容："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat ~/.ssh/id_rsa.pub
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 复制上面的公钥内容，然后在服务器上执行："
echo ""
echo "   mkdir -p ~/.ssh"
echo "   chmod 700 ~/.ssh"
echo "   echo '上面的公钥内容' >> ~/.ssh/authorized_keys"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "💡 或者通过服务器控制台（Web终端）直接粘贴执行"
echo ""

