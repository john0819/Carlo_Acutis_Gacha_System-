package database

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"h5project/config"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func InitDB() error {
	cfg := config.GetConfig()

	// 构建数据库连接字符串
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBSSLMode)

	var err error
	DB, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	// 测试连接
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	// 设置连接池参数（使用配置中的值）
	DB.SetMaxOpenConns(cfg.DBMaxOpenConns)
	DB.SetMaxIdleConns(cfg.DBMaxIdleConns)
	DB.SetConnMaxLifetime(time.Duration(cfg.DBConnMaxLifetime) * time.Minute)

	log.Printf("✅ 数据库连接成功 (连接池: MaxOpen=%d, MaxIdle=%d, MaxLifetime=%d分钟)",
		cfg.DBMaxOpenConns, cfg.DBMaxIdleConns, cfg.DBConnMaxLifetime)
	return nil
}

func CloseDB() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}
