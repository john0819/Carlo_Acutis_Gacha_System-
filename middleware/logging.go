package middleware

import (
	"log"
	"net/http"
	"time"
)

// LoggingMiddleware 记录HTTP请求和响应
func LoggingMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// 创建响应写入器包装器，用于捕获状态码
		wrapped := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		// 执行下一个处理器
		next(wrapped, r)

		// 记录请求信息
		duration := time.Since(start)
		log.Printf("[%s] %s %s - %d - %v - %s",
			r.Method,
			r.URL.Path,
			r.RemoteAddr,
			wrapped.statusCode,
			duration,
			r.UserAgent(),
		)
	}
}

// responseWriter 包装http.ResponseWriter以捕获状态码
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}
