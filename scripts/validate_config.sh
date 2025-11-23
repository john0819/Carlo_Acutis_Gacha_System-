#!/bin/bash
# 配置验证脚本

echo "🔍 验证系统配置..."

# 检查必需的环境变量
check_env_var() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        echo "⚠️  环境变量 $var_name 未设置"
        return 1
    else
        echo "✅ $var_name: 已设置"
        return 0
    fi
}

# 检查数据库连接
check_database() {
    echo "🗄️  检查数据库连接..."
    
    local db_host=${DB_HOST:-localhost}
    local db_port=${DB_PORT:-5432}
    local db_user=${DB_USER:-h5user}
    local db_name=${DB_NAME:-h5project}
    
    if command -v psql &> /dev/null; then
        if PGPASSWORD="$DB_PASSWORD" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT 1;" &> /dev/null; then
            echo "✅ 数据库连接正常"
            return 0
        else
            echo "❌ 数据库连接失败"
            return 1
        fi
    else
        echo "⚠️  psql 未安装，跳过数据库连接检查"
        return 0
    fi
}

# 检查端口是否可用
check_port() {
    local port=${PORT:-8080}
    
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep ":$port " &> /dev/null; then
            echo "⚠️  端口 $port 已被占用"
            return 1
        else
            echo "✅ 端口 $port 可用"
            return 0
        fi
    else
        echo "⚠️  netstat 未安装，跳过端口检查"
        return 0
    fi
}

# 检查文件权限
check_permissions() {
    echo "📁 检查文件权限..."
    
    local errors=0
    
    # 检查静态文件目录
    if [ ! -r "static/" ]; then
        echo "❌ static/ 目录不可读"
        ((errors++))
    fi
    
    # 检查图片目录
    if [ ! -r "images/" ]; then
        echo "❌ images/ 目录不可读"
        ((errors++))
    fi
    
    # 检查可执行文件
    if [ -f "h5project" ] && [ ! -x "h5project" ]; then
        echo "❌ h5project 可执行文件没有执行权限"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "✅ 文件权限正常"
        return 0
    else
        echo "❌ 发现 $errors 个权限问题"
        return 1
    fi
}

# 主检查流程
main() {
    local errors=0
    
    echo "开始配置验证..."
    echo "===================="
    
    # 检查JWT密钥
    if [ -z "$JWT_SECRET" ]; then
        echo "⚠️  JWT_SECRET 未设置，将使用随机生成的密钥"
    else
        if [ ${#JWT_SECRET} -lt 32 ]; then
            echo "❌ JWT_SECRET 长度不足32字符"
            ((errors++))
        else
            echo "✅ JWT_SECRET: 长度符合要求"
        fi
    fi
    
    # 检查数据库配置
    check_database || ((errors++))
    
    # 检查端口
    check_port || ((errors++))
    
    # 检查文件权限
    check_permissions || ((errors++))
    
    echo "===================="
    
    if [ $errors -eq 0 ]; then
        echo "✅ 所有检查通过，系统配置正常"
        exit 0
    else
        echo "❌ 发现 $errors 个问题，请检查配置"
        exit 1
    fi
}

# 运行主函数
main "$@"
