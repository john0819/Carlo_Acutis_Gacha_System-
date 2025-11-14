package utils

import (
	"log"
	"runtime"
	"strings"
)

// LogError 记录错误日志，包含文件名和行号
func LogError(err error, context string) {
	if err == nil {
		return
	}

	// 获取调用者的文件名和行号
	_, file, line, ok := runtime.Caller(1)
	if ok {
		// 只取文件名，不包含完整路径
		parts := strings.Split(file, "/")
		file = parts[len(parts)-1]
		log.Printf("❌ [ERROR] %s:%d - %s: %v", file, line, context, err)
	} else {
		log.Printf("❌ [ERROR] %s: %v", context, err)
	}
}

// LogWarning 记录警告日志
func LogWarning(message string, args ...interface{}) {
	log.Printf("⚠️  [WARN] "+message, args...)
}

// LogInfo 记录信息日志
func LogInfo(message string, args ...interface{}) {
	log.Printf("ℹ️  [INFO] "+message, args...)
}

// LogDebug 记录调试日志（生产环境可以关闭）
func LogDebug(message string, args ...interface{}) {
	// 可以通过环境变量控制是否输出调试日志
	log.Printf("🔍 [DEBUG] "+message, args...)
}
