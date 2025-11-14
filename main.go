package main

import (
	"log"
	"net/http"

	"h5project/auth"
	"h5project/config"
	"h5project/database"
	"h5project/handlers"
	"h5project/middleware"
)

func main() {
	// 加载配置
	cfg := config.LoadConfig()

	// 初始化数据库
	if err := database.InitDB(); err != nil {
		log.Fatal("数据库初始化失败:", err)
	}
	defer database.CloseDB()

	// 初始化卡片数据
	if err := handlers.InitCards(); err != nil {
		log.Printf("⚠️  卡片初始化失败: %v", err)
	} else {
		log.Println("✅ 卡片数据已初始化")
	}

	// 创建限流器（每秒10个请求，突发20个）
	rateLimiter := middleware.NewRateLimiter(10, 20)

	// 辅助函数：组合限流和JWT中间件
	withAuthAndRateLimit := func(handler http.HandlerFunc) http.HandlerFunc {
		return rateLimiter.Limit(auth.JWTMiddleware(handler)).ServeHTTP
	}

	// 健康检查端点（不需要认证和限流）
	http.HandleFunc("/health", handlers.HealthCheck)
	http.HandleFunc("/api/health", handlers.HealthCheck)

	// API路由（使用明确路径，避免被静态文件覆盖）
	// 公开接口（限流保护）
	http.HandleFunc("/api/register", rateLimiter.Limit(http.HandlerFunc(handlers.Register)).ServeHTTP)
	http.HandleFunc("/api/login", rateLimiter.Limit(http.HandlerFunc(handlers.Login)).ServeHTTP)
	http.HandleFunc("/api/daily-quote", rateLimiter.Limit(http.HandlerFunc(handlers.GetDailyQuote)).ServeHTTP)

	// 需要认证的接口（限流 + JWT认证）
	http.HandleFunc("/api/user/profile", withAuthAndRateLimit(handlers.GetProfile))
	http.HandleFunc("/api/user/profile/update", withAuthAndRateLimit(handlers.UpdateProfile))
	http.HandleFunc("/api/draw/check", withAuthAndRateLimit(handlers.CheckTodayDraw))
	http.HandleFunc("/api/draw", withAuthAndRateLimit(handlers.DrawCard))
	http.HandleFunc("/api/user/cards", withAuthAndRateLimit(handlers.GetUserCards))
	http.HandleFunc("/api/card/", withAuthAndRateLimit(handlers.HandleCardRequest))
	http.HandleFunc("/api/achievements", withAuthAndRateLimit(handlers.GetAchievements))
	http.HandleFunc("/api/claim-reward", withAuthAndRateLimit(handlers.ClaimReward))
	http.HandleFunc("/api/redeem", withAuthAndRateLimit(handlers.Redeem))
	http.HandleFunc("/api/redemption-info", withAuthAndRateLimit(handlers.GetRedemptionInfo))
	http.HandleFunc("/api/feedback", withAuthAndRateLimit(handlers.SubmitFeedback))
	http.HandleFunc("/api/feedbacks", withAuthAndRateLimit(handlers.GetFeedbacks))

	// 图片目录
	imageFs := http.FileServer(http.Dir("./images"))
	http.Handle("/images/", http.StripPrefix("/images/", imageFs))

	// 静态文件服务（放在最后）
	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", fs)

	// 使用配置中的端口
	port := ":" + cfg.Port
	log.Printf("🚀 服务器启动在 http://localhost%s", port)
	log.Printf("📱 H5页面地址: http://localhost%s/login.html", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("服务器启动失败:", err)
	}
}
