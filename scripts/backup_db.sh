#!/bin/bash
# 数据库备份脚本
# 使用方法: ./scripts/backup_db.sh
# 建议添加到crontab: 0 2 * * * /opt/h5project/scripts/backup_db.sh

set -e

BACKUP_DIR="/opt/h5project/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/h5project_backup_$DATE.sql"
RETENTION_DAYS=7

# 创建备份目录
mkdir -p "$BACKUP_DIR"

echo "📦 开始备份数据库..."
echo "   时间: $(date)"
echo "   文件: $BACKUP_FILE"

# 检查数据库容器是否运行
if ! docker ps | grep -q h5project_db; then
    echo "❌ 错误: 数据库容器未运行"
    exit 1
fi

# 执行备份
if docker exec h5project_db pg_dump -U h5user h5project > "$BACKUP_FILE"; then
    # 压缩备份文件
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
    
    echo "✅ 备份完成: $BACKUP_FILE"
    echo "   大小: $(du -h "$BACKUP_FILE" | cut -f1)"
    
    # 删除旧备份（保留最近7天）
    echo "🧹 清理旧备份（保留最近${RETENTION_DAYS}天）..."
    find "$BACKUP_DIR" -name "h5project_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    
    echo "✅ 备份任务完成"
else
    echo "❌ 备份失败"
    exit 1
fi

