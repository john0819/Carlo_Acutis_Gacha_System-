#!/bin/bash
# 下载示例图片脚本
# 使用占位图片服务生成示例图片

echo "正在下载示例图片..."

# 创建images目录（如果不存在）
mkdir -p images

# 下载5张示例图片（使用placeholder图片服务）
# 这些是占位图片，你可以替换成自己的图片
curl -o images/image1.jpg "https://picsum.photos/800/600?random=1" 2>/dev/null
curl -o images/image2.jpg "https://picsum.photos/800/600?random=2" 2>/dev/null
curl -o images/image3.jpg "https://picsum.photos/800/600?random=3" 2>/dev/null
curl -o images/image4.jpg "https://picsum.photos/800/600?random=4" 2>/dev/null
curl -o images/image5.jpg "https://picsum.photos/800/600?random=5" 2>/dev/null

echo "✅ 示例图片下载完成！"
echo "💡 你可以将 images/ 目录中的图片替换成你自己的图片"

