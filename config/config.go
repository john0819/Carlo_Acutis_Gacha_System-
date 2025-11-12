package config

import (
	"log"
	"os"
	"strconv"
)

// Config 应用配置结构
type Config struct {
	// 服务器配置
	Port string

	// 数据库配置
	DBHost     string
	DBPort     int
	DBUser     string
	DBPassword string
	DBName     string
	DBSSLMode  string

	// 数据库连接池配置
	DBMaxOpenConns    int
	DBMaxIdleConns    int
	DBConnMaxLifetime int // 分钟

	// JWT配置
	JWTSecret string
}

var AppConfig *Config

// LoadConfig 加载配置（从环境变量读取，有默认值）
func LoadConfig() *Config {
	config := &Config{
		// 服务器配置
		Port: getEnv("PORT", "8080"),

		// 数据库配置
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnvAsInt("DB_PORT", 5432),
		DBUser:     getEnv("DB_USER", "h5user"),
		DBPassword: getEnv("DB_PASSWORD", "h5pass123"),
		DBName:     getEnv("DB_NAME", "h5project"),
		DBSSLMode:  getEnv("DB_SSLMODE", "disable"),

		// 数据库连接池配置（优化后）
		DBMaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 100),
		DBMaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 10),
		DBConnMaxLifetime: getEnvAsInt("DB_CONN_MAX_LIFETIME", 5), // 5分钟

		// JWT配置
		JWTSecret: getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
	}

	AppConfig = config
	log.Println("✅ 配置加载完成")
	return config
}

// GetConfig 获取配置（如果未加载则先加载）
func GetConfig() *Config {
	if AppConfig == nil {
		return LoadConfig()
	}
	return AppConfig
}

// getEnv 获取环境变量，如果不存在则返回默认值
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt 获取环境变量并转换为int，如果不存在则返回默认值
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
		log.Printf("⚠️  环境变量 %s 的值 '%s' 不是有效的整数，使用默认值 %d", key, value, defaultValue)
	}
	return defaultValue
}
