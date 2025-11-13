#!/bin/bash
# 上传图片到服务器脚本
# 在本地运行，将images目录上传到服务器
# 使用方法: ./scripts/upload_images.sh 服务器IP [用户名] [密码]

# 不使用 set -e，需要手动处理错误

if [ -z "$1" ]; then
    echo "❌ 错误: 请提供服务器IP地址"
    echo "使用方法: ./scripts/upload_images.sh 服务器IP [用户名] [密码]"
    echo "示例: ./scripts/upload_images.sh 47.111.226.140 admin 你的密码"
    exit 1
fi

SERVER_IP=$1
SERVER_USER=${2:-admin}
SERVER_PASS=$3
# 自动检测项目目录（优先使用 /opt/h5project，然后是 /home/admin/h5project）
if ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "test -d /opt/h5project" 2>/dev/null; then
    SERVER_DIR="/opt/h5project"
elif ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "test -d /home/$SERVER_USER/h5project" 2>/dev/null; then
    SERVER_DIR="/home/$SERVER_USER/h5project"
elif ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "test -d /home/$SERVER_USER/Carlo_Acutis_Gacha_System-" 2>/dev/null; then
    SERVER_DIR="/home/$SERVER_USER/Carlo_Acutis_Gacha_System-"
else
    # 默认使用新目录
    SERVER_DIR="/home/$SERVER_USER/h5project"
fi

echo "📤 上传图片到服务器..."
echo "   服务器: $SERVER_USER@$SERVER_IP"
echo "   目标目录: $SERVER_DIR/images/"
echo ""

# 检查images目录
if [ ! -d "images" ]; then
    echo "❌ 错误: 找不到 images 目录"
    exit 1
fi

# 统计图片数量
IMAGE_COUNT=$(find images -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" \) | wc -l | tr -d ' ')
SIZE=$(du -sh images | awk '{print $1}')

echo "📊 准备上传:"
echo "   图片数量: $IMAGE_COUNT 张"
echo "   总大小: $SIZE"
echo ""

read -p "确认上传？(y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "❌ 已取消"
    exit 0
fi

echo ""
echo "🚀 开始上传..."
echo "   （这可能需要几分钟，请耐心等待）"
echo ""

# 先创建目标目录（如果不存在）
echo "📁 检查并创建目标目录..."
if [ -z "$SERVER_PASS" ]; then
    # 使用SSH密钥
    if ! ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "mkdir -p $SERVER_DIR/images" 2>/dev/null; then
        echo "❌ 错误: 无法连接到服务器或创建目录"
        echo "   可能原因: SSH密钥未正确配置"
        echo "   请先运行: ./scripts/setup_ssh_key.sh $SERVER_IP $SERVER_USER"
        echo "   或者提供密码: ./scripts/upload_images.sh $SERVER_IP $SERVER_USER 你的密码"
        exit 1
    fi
else
    # 使用密码
    if command -v sshpass &> /dev/null; then
        if ! sshpass -p "$SERVER_PASS" ssh -o StrictHostKeyChecking=no $SERVER_USER@$SERVER_IP "mkdir -p $SERVER_DIR/images" 2>/dev/null; then
            echo "❌ 错误: 无法连接到服务器或创建目录"
            echo "   请检查密码是否正确"
            exit 1
        fi
    else
        echo "❌ 错误: 需要安装sshpass来使用密码上传"
        echo "   安装方法: brew install hudochenkov/sshpass/sshpass (macOS)"
        exit 1
    fi
fi
echo "✅ 目标目录已准备就绪"

# 上传文件 - 使用rsync（更快，支持断点续传）
echo "📤 开始上传文件..."
echo "   💡 使用rsync传输（速度更快，支持断点续传）"
echo ""

# 检查是否安装了rsync
if ! command -v rsync &> /dev/null; then
    echo "⚠️  rsync未安装，使用scp（速度较慢）"
    echo "   建议安装rsync: brew install rsync (macOS)"
    USE_RSYNC=false
else
    USE_RSYNC=true
fi

if [ "$USE_RSYNC" = true ]; then
    # 使用rsync（推荐，速度快）
    # -a: 归档模式（保留权限、时间戳等）
    # -v: 详细输出
    # -z: 压缩传输（虽然图片已压缩，但传输时压缩可能仍有帮助）
    # --progress: 显示进度
    # --partial: 保留部分传输的文件（支持断点续传）
    RSYNC_OPTS="-avz --progress --partial"
    
    if [ -z "$SERVER_PASS" ]; then
        # 使用SSH密钥
        if ! rsync $RSYNC_OPTS -e "ssh -o StrictHostKeyChecking=no" images/ $SERVER_USER@$SERVER_IP:$SERVER_DIR/images/; then
            echo "❌ 错误: 上传失败"
            echo "   可能原因: SSH密钥未正确配置"
            echo "   请先运行: ./scripts/setup_ssh_key.sh $SERVER_IP $SERVER_USER"
            exit 1
        fi
    else
        # 使用密码（通过sshpass）
        if command -v sshpass &> /dev/null; then
            if ! sshpass -p "$SERVER_PASS" rsync $RSYNC_OPTS -e "sshpass -p '$SERVER_PASS' ssh -o StrictHostKeyChecking=no" images/ $SERVER_USER@$SERVER_IP:$SERVER_DIR/images/; then
                echo "❌ 错误: 上传失败"
                echo "   请检查密码是否正确"
                exit 1
            fi
        else
            echo "❌ 错误: 需要安装sshpass来使用密码上传"
            echo "   安装方法: brew install hudochenkov/sshpass/sshpass (macOS)"
            exit 1
        fi
    fi
else
    # 使用scp（备用方案）
    SCP_OPTS="-r -C -o StrictHostKeyChecking=no"
    # -C 启用压缩
    
    if [ -z "$SERVER_PASS" ]; then
        if ! scp $SCP_OPTS images/ $SERVER_USER@$SERVER_IP:$SERVER_DIR/images/; then
            echo "❌ 错误: 上传失败"
            echo "   可能原因: SSH密钥未正确配置"
            echo "   请先运行: ./scripts/setup_ssh_key.sh $SERVER_IP $SERVER_USER"
            exit 1
        fi
    else
        if command -v sshpass &> /dev/null; then
            if ! sshpass -p "$SERVER_PASS" scp $SCP_OPTS images/ $SERVER_USER@$SERVER_IP:$SERVER_DIR/images/; then
                echo "❌ 错误: 上传失败"
                echo "   请检查密码是否正确"
                exit 1
            fi
        else
            echo "❌ 错误: 需要安装sshpass来使用密码上传"
            echo "   安装方法: brew install hudochenkov/sshpass/sshpass (macOS)"
            exit 1
        fi
    fi
fi

echo ""
echo "✅ 上传完成！"
echo ""
echo "💡 下一步:"
echo "   在服务器上运行: cd ~/Carlo_Acutis_Gacha_System- && ./scripts/init_server.sh"

