#!/bin/bash
# 分批添加图片到Git
# 使用方法: ./scripts/add_images_batch.sh <起始编号> <结束编号>
# 例如: ./scripts/add_images_batch.sh 21 40  # 添加card021到card040

set -e

if [ $# -lt 2 ]; then
    echo "❌ 错误: 需要提供起始和结束编号"
    echo "使用方法: $0 <起始编号> <结束编号>"
    echo "例如: $0 21 40  # 添加card021到card040"
    exit 1
fi

START=$1
END=$2

if [ $START -gt $END ]; then
    echo "❌ 错误: 起始编号不能大于结束编号"
    exit 1
fi

echo "📸 准备添加图片 card$(printf %03d $START) 到 card$(printf %03d $END)..."
echo ""

# 检查是否在项目根目录
if [ ! -f "main.go" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 检查.gitignore是否允许图片
if grep -q "^images/$" .gitignore; then
    echo "⚠️  警告: .gitignore中images/被忽略，需要临时修改"
    echo "📋 备份.gitignore..."
    cp .gitignore .gitignore.backup
    
    echo "✏️  临时修改.gitignore..."
    sed -i.bak 's|^images/$|#images/|' .gitignore
    echo "✅ .gitignore已临时修改"
fi

# 添加指定范围的图片
ADDED=0
MISSING=0

for i in $(seq $START $END); do
    num=$(printf %03d $i)
    if [ -f "images/card${num}.png" ]; then
        git add "images/card${num}.png" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✅ 添加 images/card${num}.png"
            ADDED=$((ADDED + 1))
        else
            echo "  ⚠️  images/card${num}.png 已在暂存区"
        fi
    else
        echo "  ❌ images/card${num}.png 不存在"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "✅ 完成！"
echo "   📊 成功添加: $ADDED 张"
if [ $MISSING -gt 0 ]; then
    echo "   ⚠️  缺失: $MISSING 张"
fi
echo ""
echo "📝 下一步操作："
echo "   1. 检查: git status"
echo "   2. 提交: git commit -m 'feat: 添加图片 card$(printf %03d $START)-card$(printf %03d $END)'"
echo "   3. 推送: git push"
echo ""
echo "💡 提示: 提交后可以恢复.gitignore（如果修改了）"
echo "   恢复命令: mv .gitignore.backup .gitignore"

