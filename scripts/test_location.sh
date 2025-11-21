#!/bin/bash
# 快速测试位置校验功能

echo "🧪 位置校验功能测试工具"
echo ""

# 检查当前状态
./scripts/verify_location_setting.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "选择操作：
1) 启用位置校验
2) 禁用位置校验（测试模式）
3) 查看当前状态
4) 退出

请输入选项 (1-4): " choice

case $choice in
    1)
        echo ""
        ./scripts/update_location_setting.sh true
        echo ""
        echo "✅ 已启用位置校验"
        echo "💡 请刷新浏览器页面测试"
        ;;
    2)
        echo ""
        ./scripts/update_location_setting.sh false
        echo ""
        echo "✅ 已禁用位置校验（测试模式）"
        echo "💡 请刷新浏览器页面测试"
        ;;
    3)
        echo ""
        ./scripts/verify_location_setting.sh
        ;;
    4)
        echo "退出"
        exit 0
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac

