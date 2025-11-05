package main

import (
	"log"
	"net/http"

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

	// 图片目录
	imageFs := http.FileServer(http.Dir("./images"))
	http.Handle("/images/", http.StripPrefix("/images/", imageFs))

	// 静态文件服务（放在最后）
	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", fs)

	port := ":8080"
	log.Printf("🚀 服务器启动在 http://localhost%s", port)
	log.Printf("📱 H5页面地址: http://localhost%s/login.html", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("服务器启动失败:", err)
	}
}
