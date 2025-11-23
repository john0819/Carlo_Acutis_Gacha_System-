package middleware

import (
	"net/http"
	"strconv"
	"time"
)

// SetCacheHeaders 设置缓存头
func SetCacheHeaders(maxAge int) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// 设置缓存控制头
			w.Header().Set("Cache-Control", "public, max-age="+strconv.Itoa(maxAge))
			w.Header().Set("Expires", time.Now().Add(time.Duration(maxAge)*time.Second).Format(http.TimeFormat))

			next.ServeHTTP(w, r)
		})
	}
}

// SetNoCacheHeaders 设置不缓存头（用于API接口）
func SetNoCacheHeaders(w http.ResponseWriter) {
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "0")
}

// SetStaticCacheHeaders 为静态资源设置长期缓存
func SetStaticCacheHeaders(w http.ResponseWriter) {
	// 静态资源缓存1年
	w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	w.Header().Set("Expires", time.Now().Add(365*24*time.Hour).Format(http.TimeFormat))
}
