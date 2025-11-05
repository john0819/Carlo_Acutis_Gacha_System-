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

	// API路由
	http.HandleFunc("/api/register", handlers.Register)
	http.HandleFunc("/api/login", handlers.Login)
	http.HandleFunc("/api/user/profile", auth.JWTMiddleware(handlers.GetProfile))
	http.HandleFunc("/api/user/profile/update", auth.JWTMiddleware(handlers.UpdateProfile))

	// 静态文件服务
	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", fs)

	// 图片目录
	imageFs := http.FileServer(http.Dir("./images"))
	http.Handle("/images/", http.StripPrefix("/images/", imageFs))

	port := ":8080"
	log.Printf("🚀 服务器启动在 http://localhost%s", port)
	log.Printf("📱 H5页面地址: http://localhost%s/login.html", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("服务器启动失败:", err)
	}
}
