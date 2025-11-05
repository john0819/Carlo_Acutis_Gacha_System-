package main

import (
	"log"
	"net/http"
	"os"

	"h5project/auth"
	"h5project/database"
	"h5project/handlers"
)

func main() {
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

	// API路由（使用明确路径，避免被静态文件覆盖）
	http.HandleFunc("/api/register", handlers.Register)
	http.HandleFunc("/api/login", handlers.Login)
	http.HandleFunc("/api/user/profile", auth.JWTMiddleware(handlers.GetProfile))
	http.HandleFunc("/api/user/profile/update", auth.JWTMiddleware(handlers.UpdateProfile))
	http.HandleFunc("/api/draw/check", auth.JWTMiddleware(handlers.CheckTodayDraw))
	http.HandleFunc("/api/draw", auth.JWTMiddleware(handlers.DrawCard))
	http.HandleFunc("/api/user/cards", auth.JWTMiddleware(handlers.GetUserCards))
	http.HandleFunc("/api/card/", auth.JWTMiddleware(handlers.HandleCardRequest))
	http.HandleFunc("/api/achievements", auth.JWTMiddleware(handlers.GetAchievements))
	http.HandleFunc("/api/claim-reward", auth.JWTMiddleware(handlers.ClaimReward))
	http.HandleFunc("/api/redeem", auth.JWTMiddleware(handlers.Redeem))
	http.HandleFunc("/api/redemption-info", auth.JWTMiddleware(handlers.GetRedemptionInfo))
	http.HandleFunc("/api/feedback", auth.JWTMiddleware(handlers.SubmitFeedback))
	http.HandleFunc("/api/feedbacks", auth.JWTMiddleware(handlers.GetFeedbacks))

	// 图片目录
	imageFs := http.FileServer(http.Dir("./images"))
	http.Handle("/images/", http.StripPrefix("/images/", imageFs))

	// 静态文件服务（放在最后）
	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", fs)

	// 从环境变量获取端口，默认8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	port = ":" + port
	log.Printf("🚀 服务器启动在 http://localhost%s", port)
	log.Printf("📱 H5页面地址: http://localhost%s/login.html", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("服务器启动失败:", err)
	}
}
