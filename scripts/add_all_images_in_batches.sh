#!/bin/bash
# 分批添加所有图片到Git的辅助脚本
# 使用方法: ./scripts/add_all_images_in_batches.sh
# 这个脚本会提示你每次添加多少张图片

set -e

echo "📸 分批添加图片到Git"
echo ""
echo "当前images目录下的图片："
ls images/card*.png 2>/dev/null | wc -l | xargs echo "   共找到:"
echo ""

read -p "每次添加多少张图片？(建议20-50张): " BATCH_SIZE
BATCH_SIZE=${BATCH_SIZE:-20}

read -p "从第几张开始？(默认1): " START_NUM
START_NUM=${START_NUM:-1}

read -p "到第几张结束？(默认160): " END_NUM
END_NUM=${END_NUM:-160}

echo ""
echo "📋 计划："
echo "   每次添加: $BATCH_SIZE 张"
echo "   范围: card$(printf %03d $START_NUM) 到 card$(printf %03d $END_NUM)"
echo ""

CURRENT=$START_NUM
BATCH=1

while [ $CURRENT -le $END_NUM ]; do
    BATCH_END=$((CURRENT + BATCH_SIZE - 1))
    if [ $BATCH_END -gt $END_NUM ]; then
        BATCH_END=$END_NUM
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 批次 $BATCH: card$(printf %03d $CURRENT) 到 card$(printf %03d $BATCH_END)"
    echo ""
    
    # 调用添加脚本
    ./scripts/add_images_batch.sh $CURRENT $BATCH_END
    
    echo ""
    read -p "是否提交这一批？(y/n，默认y): " COMMIT
    COMMIT=${COMMIT:-y}
    
    if [ "$COMMIT" = "y" ] || [ "$COMMIT" = "Y" ]; then
        git commit -m "feat: 添加图片 card$(printf %03d $CURRENT)-card$(printf %03d $BATCH_END)"
        echo "✅ 已提交"
        
        read -p "是否推送到远程？(y/n，默认n): " PUSH
        PUSH=${PUSH:-n}
        
        if [ "$PUSH" = "y" ] || [ "$PUSH" = "Y" ]; then
            git push
            echo "✅ 已推送"
        fi
    fi
    
    CURRENT=$((BATCH_END + 1))
    BATCH=$((BATCH + 1))
    
    if [ $CURRENT -le $END_NUM ]; then
        echo ""
        read -p "继续下一批？(y/n，默认y): " CONTINUE
        CONTINUE=${CONTINUE:-y}
        if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
            echo "⏸️  已暂停，可以稍后继续"
            break
        fi
    fi
done

echo ""
echo "✅ 所有批次处理完成！"

