package middleware

import (
	"net/http"
	"sync"
	"time"
)

// RateLimiter 限流器
type RateLimiter struct {
	visitors map[string]*visitor
	mu       sync.RWMutex
	rate     int           // 每秒允许的请求数
	burst    int           // 突发请求数
	cleanup  time.Duration // 清理过期访问者的间隔
}

type visitor struct {
	lastSeen time.Time
	tokens   int
	mu       sync.Mutex
}

// NewRateLimiter 创建新的限流器
// rate: 每秒允许的请求数
// burst: 突发请求数（令牌桶容量）
func NewRateLimiter(rate, burst int) *RateLimiter {
	rl := &RateLimiter{
		visitors: make(map[string]*visitor),
		rate:     rate,
		burst:    burst,
		cleanup:  5 * time.Minute, // 每5分钟清理一次过期访问者
	}

	// 启动清理协程
	go rl.cleanupVisitors()

	return rl
}

// Limit 限流中间件
func (rl *RateLimiter) Limit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 获取客户端IP
		ip := r.RemoteAddr
		if forwarded := r.Header.Get("X-Forwarded-For"); forwarded != "" {
			ip = forwarded
		}

		// 检查是否超过限制
		if !rl.allow(ip) {
			http.Error(w, "请求过于频繁，请稍后再试", http.StatusTooManyRequests)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// allow 检查是否允许请求（令牌桶算法）
func (rl *RateLimiter) allow(ip string) bool {
	rl.mu.Lock()
	v, exists := rl.visitors[ip]
	if !exists {
		v = &visitor{
			lastSeen: time.Now(),
			tokens:   rl.burst, // 初始化为突发容量
		}
		rl.visitors[ip] = v
	}
	rl.mu.Unlock()

	v.mu.Lock()
	defer v.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(v.lastSeen)

	// 根据时间间隔补充令牌
	tokensToAdd := int(elapsed.Seconds() * float64(rl.rate))
	if tokensToAdd > 0 {
		v.tokens = min(v.tokens+tokensToAdd, rl.burst)
		v.lastSeen = now
	}

	// 检查是否有可用令牌
	if v.tokens > 0 {
		v.tokens--
		return true
	}

	return false
}

// cleanupVisitors 清理过期的访问者记录
func (rl *RateLimiter) cleanupVisitors() {
	for {
		time.Sleep(rl.cleanup)
		rl.mu.Lock()
		now := time.Now()
		for ip, v := range rl.visitors {
			v.mu.Lock()
			if now.Sub(v.lastSeen) > rl.cleanup {
				delete(rl.visitors, ip)
			}
			v.mu.Unlock()
		}
		rl.mu.Unlock()
	}
}

// min 返回两个整数中的较小值
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
