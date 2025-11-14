package handlers

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"h5project/auth"
	"h5project/database"
	"h5project/models"

	"golang.org/x/crypto/bcrypt"
)

func sendError(w http.ResponseWriter, message string, statusCode int) {
	// 记录错误日志（只记录服务器错误，不记录客户端错误）
	if statusCode >= 500 {
		log.Printf("❌ [ERROR] HTTP %d: %s", statusCode, message)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}

func Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "无效的请求数据", http.StatusBadRequest)
		return
	}

	// 验证输入
	if req.Username == "" || req.Password == "" {
		sendError(w, "用户名和密码不能为空", http.StatusBadRequest)
		return
	}

	if len(req.Password) < 6 {
		sendError(w, "密码长度至少6位", http.StatusBadRequest)
		return
	}

	// 检查用户名是否已存在
	var exists bool
	err := database.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)", req.Username).Scan(&exists)
	if err != nil {
		sendError(w, "数据库查询失败", http.StatusInternalServerError)
		return
	}
	if exists {
		sendError(w, "用户名已存在", http.StatusConflict)
		return
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		sendError(w, "密码加密失败", http.StatusInternalServerError)
		return
	}

	// 创建用户
	var userID int
	err = database.DB.QueryRow(
		"INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id",
		req.Username, string(hashedPassword),
	).Scan(&userID)
	if err != nil {
		sendError(w, "用户创建失败", http.StatusInternalServerError)
		return
	}

	// 生成token
	token, err := auth.GenerateToken(userID, req.Username)
	if err != nil {
		sendError(w, "Token生成失败", http.StatusInternalServerError)
		return
	}

	// 获取用户信息
	user := getUserByID(userID)
	if user == nil {
		sendError(w, "获取用户信息失败", http.StatusInternalServerError)
		return
	}

	response := models.LoginResponse{
		Token: token,
		User:  *user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "无效的请求数据", http.StatusBadRequest)
		return
	}

	// 查询用户
	var user models.User
	err := database.DB.QueryRow(
		"SELECT id, username, password_hash, holy_name, nickname, birthday, checkin_count, exchange_points FROM users WHERE username = $1",
		req.Username,
	).Scan(
		&user.ID, &user.Username, &user.PasswordHash,
		&user.HolyName, &user.Nickname, &user.Birthday,
		&user.CheckinCount, &user.ExchangePoints,
	)

	if err == sql.ErrNoRows {
		sendError(w, "用户名或密码错误", http.StatusUnauthorized)
		return
	}
	if err != nil {
		sendError(w, "数据库查询失败", http.StatusInternalServerError)
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		sendError(w, "用户名或密码错误", http.StatusUnauthorized)
		return
	}

	// 生成token
	token, err := auth.GenerateToken(user.ID, user.Username)
	if err != nil {
		sendError(w, "Token生成失败", http.StatusInternalServerError)
		return
	}

	// 清除密码哈希
	user.PasswordHash = ""

	response := models.LoginResponse{
		Token: token,
		User:  user,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func GetProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	user := getUserByID(userID)
	if user == nil {
		sendError(w, "用户不存在", http.StatusNotFound)
		return
	}

	user.PasswordHash = ""
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func UpdateProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	// 先解析为map来处理birthday字符串
	var rawData map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&rawData); err != nil {
		sendError(w, "无效的请求数据: "+err.Error(), http.StatusBadRequest)
		return
	}

	var req models.UpdateProfileRequest

	// 处理holy_name
	if holyName, ok := rawData["holy_name"].(string); ok && holyName != "" {
		req.HolyName = &holyName
	}

	// 处理nickname
	if nickname, ok := rawData["nickname"].(string); ok && nickname != "" {
		req.Nickname = &nickname
	}

	// 处理birthday（前端发送的是字符串格式 YYYY-MM-DD）
	if birthdayStr, ok := rawData["birthday"].(string); ok && birthdayStr != "" {
		birthday, err := time.Parse("2006-01-02", birthdayStr)
		if err != nil {
			sendError(w, "日期格式错误，请使用 YYYY-MM-DD 格式", http.StatusBadRequest)
			return
		}
		req.Birthday = &birthday
	}

	// 更新用户信息
	_, err = database.DB.Exec(
		"UPDATE users SET holy_name = COALESCE($1, holy_name), nickname = COALESCE($2, nickname), birthday = COALESCE($3, birthday), updated_at = CURRENT_TIMESTAMP WHERE id = $4",
		req.HolyName, req.Nickname, req.Birthday, userID,
	)
	if err != nil {
		sendError(w, "更新失败", http.StatusInternalServerError)
		return
	}

	user := getUserByID(userID)
	if user == nil {
		sendError(w, "获取用户信息失败", http.StatusInternalServerError)
		return
	}

	user.PasswordHash = ""
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func getUserByID(userID int) *models.User {
	var user models.User
	err := database.DB.QueryRow(
		"SELECT id, username, holy_name, nickname, birthday, checkin_count, exchange_points, created_at, updated_at FROM users WHERE id = $1",
		userID,
	).Scan(
		&user.ID, &user.Username, &user.HolyName, &user.Nickname,
		&user.Birthday, &user.CheckinCount, &user.ExchangePoints,
		&user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		return nil
	}
	return &user
}
