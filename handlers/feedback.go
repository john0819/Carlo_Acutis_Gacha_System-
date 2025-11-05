package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"h5project/auth"
	"h5project/database"
	"h5project/models"
)

// SubmitFeedback 提交反馈
func SubmitFeedback(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	var req models.FeedbackRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "无效的请求数据", http.StatusBadRequest)
		return
	}

	// 验证内容
	req.Content = strings.TrimSpace(req.Content)
	if req.Content == "" {
		sendError(w, "反馈内容不能为空", http.StatusBadRequest)
		return
	}

	if len(req.Content) > 2000 {
		sendError(w, "反馈内容不能超过2000字", http.StatusBadRequest)
		return
	}

	// 验证类型
	req.Type = strings.ToLower(strings.TrimSpace(req.Type))
	if req.Type == "" {
		req.Type = "other"
	}
	if req.Type != "bug" && req.Type != "suggestion" && req.Type != "other" {
		req.Type = "other"
	}

	// 插入反馈
	_, err = database.DB.Exec(
		"INSERT INTO feedbacks (user_id, content, type) VALUES ($1, $2, $3)",
		userID, req.Content, req.Type,
	)
	if err != nil {
		sendError(w, "提交失败", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "反馈提交成功，感谢您的反馈！",
	})
}

// GetFeedbacks 获取用户的反馈列表（可选，用于用户查看自己的反馈）
func GetFeedbacks(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	rows, err := database.DB.Query(
		"SELECT id, user_id, content, type, status, created_at FROM feedbacks WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50",
		userID,
	)
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var feedbacks []models.Feedback
	for rows.Next() {
		var feedback models.Feedback
		err := rows.Scan(
			&feedback.ID, &feedback.UserID, &feedback.Content,
			&feedback.Type, &feedback.Status, &feedback.CreatedAt,
		)
		if err != nil {
			continue
		}
		feedbacks = append(feedbacks, feedback)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"feedbacks": feedbacks,
		"count":     len(feedbacks),
	})
}
