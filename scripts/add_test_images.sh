#!/bin/bash
# 临时添加20张图片到Git用于测试
# 使用方法: ./scripts/add_test_images.sh

set -e

echo "📸 准备添加20张测试图片到Git..."
echo ""

# 检查是否在项目根目录
if [ ! -f "main.go" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 备份.gitignore
echo "📋 备份.gitignore..."
cp .gitignore .gitignore.backup

# 临时修改.gitignore，允许图片文件
echo "✏️  临时修改.gitignore..."
# 注释掉 images/ 这一行
sed -i.bak 's|^images/$|#images/|' .gitignore

# 只添加前20张图片
echo "📤 添加前20张图片到Git..."
for i in {1..20}; do
    num=$(printf %03d $i)
    if [ -f "images/card${num}.png" ]; then
        git add "images/card${num}.png"
        echo "  ✅ 添加 images/card${num}.png"
    fi
done

echo ""
echo "✅ 图片已添加到Git暂存区"
echo ""
echo "📝 下一步操作："
echo "   1. 检查添加的文件: git status"
echo "   2. 提交: git commit -m 'feat: 添加20张测试图片'"
echo "   3. 推送: git push"
echo ""
echo "⚠️  注意: .gitignore已临时修改，提交后记得恢复"
echo "   恢复命令: mv .gitignore.backup .gitignore"

