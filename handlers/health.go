package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"h5project/database"
)

// HealthCheck 健康检查端点
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	// 检查数据库连接
	var dbStatus string
	var dbHealthy bool
	err := database.DB.Ping()
	if err != nil {
		dbStatus = "unhealthy"
		dbHealthy = false
	} else {
		// 执行简单查询验证数据库可用性
		var count int
		err = database.DB.QueryRow("SELECT 1").Scan(&count)
		if err != nil {
			dbStatus = "unhealthy"
			dbHealthy = false
		} else {
			dbStatus = "healthy"
			dbHealthy = true
		}
	}

	// 检查数据库连接池状态
	dbStats := database.DB.Stats()

	// 构建响应
	response := map[string]interface{}{
		"status":    "ok",
		"timestamp": time.Now().Format(time.RFC3339),
		"database": map[string]interface{}{
			"status":           dbStatus,
			"open_connections": dbStats.OpenConnections,
			"in_use":           dbStats.InUse,
			"idle":             dbStats.Idle,
		},
		"version": "1.0.0",
	}

	// 设置状态码
	statusCode := http.StatusOK
	if !dbHealthy {
		statusCode = http.StatusServiceUnavailable
		response["status"] = "degraded"
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}
