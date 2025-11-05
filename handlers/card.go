package handlers

import (
	"database/sql"
	"encoding/json"
	"math/rand"
	"net/http"
	"time"

	"h5project/auth"
	"h5project/database"
	"h5project/models"
)

// 检查今天是否已抽卡（GET方法）
func CheckTodayDraw(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	today := time.Now().Format("2006-01-02")
	var existingDraw models.DailyDraw
	err = database.DB.QueryRow(
		"SELECT id, user_id, card_id, draw_date, is_new_card FROM daily_draws WHERE user_id = $1 AND draw_date = $2",
		userID, today,
	).Scan(
		&existingDraw.ID, &existingDraw.UserID, &existingDraw.CardID,
		&existingDraw.DrawDate, &existingDraw.IsNewCard,
	)

	if err != nil {
		// 今天还没抽卡
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"has_drawn": false,
		})
		return
	}

	// 今天已抽卡，返回卡片信息
	var card models.Card
	err = database.DB.QueryRow(
		"SELECT id, name, image_url, rarity, description, created_at FROM cards WHERE id = $1",
		existingDraw.CardID,
	).Scan(
		&card.ID, &card.Name, &card.ImageURL, &card.Rarity,
		&card.Description, &card.CreatedAt,
	)
	if err != nil {
		sendError(w, "获取卡片信息失败", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"has_drawn":   true,
		"card":        card,
		"is_new_card": existingDraw.IsNewCard,
	})
}

func DrawCard(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	// 检查今天是否已经抽过卡
	today := time.Now().Format("2006-01-02")
	var existingDraw models.DailyDraw
	err = database.DB.QueryRow(
		"SELECT id, user_id, card_id, draw_date, is_new_card FROM daily_draws WHERE user_id = $1 AND draw_date = $2",
		userID, today,
	).Scan(
		&existingDraw.ID, &existingDraw.UserID, &existingDraw.CardID,
		&existingDraw.DrawDate, &existingDraw.IsNewCard,
	)

	if err == nil {
		// 今天已经抽过卡，返回今天的卡片
		var card models.Card
		err = database.DB.QueryRow(
			"SELECT id, name, image_url, rarity, description, created_at FROM cards WHERE id = $1",
			existingDraw.CardID,
		).Scan(
			&card.ID, &card.Name, &card.ImageURL, &card.Rarity,
			&card.Description, &card.CreatedAt,
		)
		if err != nil {
			sendError(w, "获取卡片信息失败", http.StatusInternalServerError)
			return
		}

		response := models.DrawResponse{
			Card:      card,
			IsNewCard: existingDraw.IsNewCard,
			Message:   "今天已经抽过卡了，这是你今天的卡片",
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
		return
	}

	// 获取用户已拥有的卡片ID列表
	rows, err := database.DB.Query(
		"SELECT card_id FROM user_cards WHERE user_id = $1",
		userID,
	)
	if err != nil && err != sql.ErrNoRows {
		sendError(w, "查询用户卡包失败", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	ownedCardIDs := make(map[int]bool)
	for rows.Next() {
		var cardID int
		if err := rows.Scan(&cardID); err == nil {
			ownedCardIDs[cardID] = true
		}
	}

	// 获取所有卡片
	allRows, err := database.DB.Query(
		"SELECT id, name, image_url, rarity, description, created_at FROM cards ORDER BY id",
	)
	if err != nil {
		sendError(w, "获取卡片列表失败", http.StatusInternalServerError)
		return
	}
	defer allRows.Close()

	var allCards []models.Card
	var newCards []models.Card
	var oldCards []models.Card

	for allRows.Next() {
		var card models.Card
		err := allRows.Scan(
			&card.ID, &card.Name, &card.ImageURL, &card.Rarity,
			&card.Description, &card.CreatedAt,
		)
		if err != nil {
			continue
		}

		allCards = append(allCards, card)
		if ownedCardIDs[card.ID] {
			oldCards = append(oldCards, card)
		} else {
			newCards = append(newCards, card)
		}
	}

	if len(allCards) == 0 {
		sendError(w, "暂无可用卡片", http.StatusNotFound)
		return
	}

	// 抽卡逻辑：新卡70%，旧卡30%
	var selectedCard models.Card
	var isNewCard bool

	rand.Seed(time.Now().UnixNano())
	random := rand.Float64()

	if random < 0.7 && len(newCards) > 0 {
		// 70%概率抽新卡
		selectedCard = newCards[rand.Intn(len(newCards))]
		isNewCard = true
	} else if len(oldCards) > 0 {
		// 30%概率或没有新卡时抽旧卡
		selectedCard = oldCards[rand.Intn(len(oldCards))]
		isNewCard = false
	} else {
		// 如果没有旧卡，只能抽新卡
		selectedCard = newCards[rand.Intn(len(newCards))]
		isNewCard = true
	}

	// 记录每日抽卡
	_, err = database.DB.Exec(
		"INSERT INTO daily_draws (user_id, card_id, draw_date, is_new_card) VALUES ($1, $2, $3, $4)",
		userID, selectedCard.ID, today, isNewCard,
	)
	if err != nil {
		sendError(w, "记录抽卡结果失败", http.StatusInternalServerError)
		return
	}

	// 如果是新卡，添加到用户卡包
	if isNewCard {
		_, err = database.DB.Exec(
			"INSERT INTO user_cards (user_id, card_id) VALUES ($1, $2) ON CONFLICT (user_id, card_id) DO NOTHING",
			userID, selectedCard.ID,
		)
		if err != nil {
			// 记录错误但不影响返回结果
			_ = err
		}

		// 更新用户打卡次数
		_, _ = database.DB.Exec(
			"UPDATE users SET checkin_count = checkin_count + 1 WHERE id = $1",
			userID,
		)
	}

	message := "恭喜你抽到了新卡！"
	if !isNewCard {
		message = "抽到了重复的卡片"
	}

	response := models.DrawResponse{
		Card:      selectedCard,
		IsNewCard: isNewCard,
		Message:   message,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 初始化卡片数据（如果卡片表为空）
func InitCards() error {
	var count int
	err := database.DB.QueryRow("SELECT COUNT(*) FROM cards").Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		return nil // 已有卡片，不需要初始化
	}

	// 插入默认卡片（基于images目录中的图片）
	// 从list.json读取，如果没有则使用默认列表
	cards := []struct {
		name     string
		imageURL string
		rarity   string
	}{
		{"卡片1", "/images/image1.jpg", "common"},
		{"卡片2", "/images/image2.jpg", "common"},
		{"卡片3", "/images/image3.jpg", "common"},
	}

	// 如果list.json存在，可以读取更多卡片
	// 这里先使用基本的三张卡片

	for i, card := range cards {
		_, err := database.DB.Exec(
			"INSERT INTO cards (name, image_url, rarity) VALUES ($1, $2, $3)",
			card.name, card.imageURL, card.rarity,
		)
		if err != nil {
			// 如果插入失败（可能是图片不存在），继续插入下一个
			continue
		}
		_ = i // 避免未使用变量警告
	}

	return nil
}
