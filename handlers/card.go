package handlers

import (
	"database/sql"
	"encoding/json"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"image/png"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"h5project/auth"
	"h5project/database"
	"h5project/models"

	"golang.org/x/image/font"
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
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
	var newAchievements []models.AchievementStatus
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

		// 检查成就
		newAchievements, _ = CheckAchievements(userID)
	}

	message := "恭喜你抽到了新卡！"
	if !isNewCard {
		message = "抽到了重复的卡片"
	}

	response := models.DrawResponse{
		Card:            selectedCard,
		IsNewCard:       isNewCard,
		Message:         message,
		NewAchievements: newAchievements,
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

// GetUserCards 获取用户所有卡片
func GetUserCards(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	// 查询用户拥有的所有卡片，按系列（rarity）和编号（id）排序
	rows, err := database.DB.Query(`
		SELECT c.id, c.name, c.image_url, c.rarity, c.description, c.created_at, uc.obtained_at
		FROM user_cards uc
		INNER JOIN cards c ON uc.card_id = c.id
		WHERE uc.user_id = $1
		ORDER BY c.rarity, c.id
	`, userID)
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var cards []models.UserCardDetail
	for rows.Next() {
		var card models.UserCardDetail
		err := rows.Scan(
			&card.ID, &card.Name, &card.ImageURL, &card.Rarity,
			&card.Description, &card.CreatedAt, &card.ObtainedAt,
		)
		if err != nil {
			continue
		}
		cards = append(cards, card)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"cards": cards,
		"count": len(cards),
	})
}

// HandleCardRequest 处理卡片相关请求（详情或下载）
func HandleCardRequest(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	// 判断是下载还是详情查询
	if strings.HasSuffix(path, "/download") {
		cardID := strings.TrimPrefix(strings.TrimSuffix(path, "/download"), "/api/card/")
		DownloadCardWithWatermark(w, r, cardID)
	} else {
		cardID := strings.TrimPrefix(path, "/api/card/")
		GetCardDetail(w, r, cardID)
	}
}

// GetCardDetail 获取单张卡片信息
func GetCardDetail(w http.ResponseWriter, r *http.Request, cardID string) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	cardIDInt, err := strconv.Atoi(cardID)
	if err != nil {
		sendError(w, "无效的卡片ID", http.StatusBadRequest)
		return
	}

	var card models.Card
	err = database.DB.QueryRow(
		"SELECT id, name, image_url, rarity, description, created_at FROM cards WHERE id = $1",
		cardIDInt,
	).Scan(
		&card.ID, &card.Name, &card.ImageURL, &card.Rarity,
		&card.Description, &card.CreatedAt,
	)
	if err == sql.ErrNoRows {
		sendError(w, "卡片不存在", http.StatusNotFound)
		return
	}
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}

	// 检查用户是否拥有此卡片
	var hasCard bool
	err = database.DB.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM user_cards WHERE user_id = $1 AND card_id = $2)",
		userID, cardIDInt,
	).Scan(&hasCard)
	if err != nil {
		hasCard = false
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"card":     card,
		"has_card": hasCard,
	})
}

// DownloadCardWithWatermark 下载带水印的卡片
func DownloadCardWithWatermark(w http.ResponseWriter, r *http.Request, cardID string) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	cardIDInt, err := strconv.Atoi(cardID)
	if err != nil {
		sendError(w, "无效的卡片ID", http.StatusBadRequest)
		return
	}

	// 获取卡片信息
	var card models.Card
	err = database.DB.QueryRow(
		"SELECT id, name, image_url, rarity, description FROM cards WHERE id = $1",
		cardIDInt,
	).Scan(
		&card.ID, &card.Name, &card.ImageURL, &card.Rarity, &card.Description,
	)
	if err == sql.ErrNoRows {
		sendError(w, "卡片不存在", http.StatusNotFound)
		return
	}
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}

	// 检查用户是否拥有此卡片
	var hasCard bool
	err = database.DB.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM user_cards WHERE user_id = $1 AND card_id = $2)",
		userID, cardIDInt,
	).Scan(&hasCard)
	if err != nil || !hasCard {
		sendError(w, "您没有此卡片", http.StatusForbidden)
		return
	}

	// 获取用户信息（用于水印）
	var user models.User
	err = database.DB.QueryRow(
		"SELECT id, holy_name, nickname FROM users WHERE id = $1",
		userID,
	).Scan(&user.ID, &user.HolyName, &user.Nickname)
	if err != nil {
		sendError(w, "获取用户信息失败", http.StatusInternalServerError)
		return
	}

	// 构建水印文本
	watermarkText := ""
	if user.HolyName != nil && *user.HolyName != "" {
		watermarkText += *user.HolyName
	}
	if user.Nickname != nil && *user.Nickname != "" {
		if watermarkText != "" {
			watermarkText += " · "
		}
		watermarkText += *user.Nickname
	}
	if watermarkText == "" {
		watermarkText = "我的卡片"
	}

	// 读取原始图片
	imagePath := strings.TrimPrefix(card.ImageURL, "/images/")
	fullPath := filepath.Join("./images", imagePath)

	file, err := os.Open(fullPath)
	if err != nil {
		sendError(w, "读取图片失败", http.StatusInternalServerError)
		return
	}
	defer file.Close()

	// 解码图片
	img, format, err := image.Decode(file)
	if err != nil {
		sendError(w, "解码图片失败", http.StatusInternalServerError)
		return
	}

	// 添加水印
	watermarkedImg, err := addWatermark(img, watermarkText)
	if err != nil {
		sendError(w, "添加水印失败", http.StatusInternalServerError)
		return
	}

	// 设置响应头
	w.Header().Set("Content-Type", "image/"+format)
	w.Header().Set("Content-Disposition", `attachment; filename="card_`+cardID+`.`+format+`"`)
	w.Header().Set("Cache-Control", "no-cache")

	// 编码并发送图片
	if format == "png" {
		png.Encode(w, watermarkedImg)
	} else {
		jpeg.Encode(w, watermarkedImg, &jpeg.Options{Quality: 90})
	}
}

// addWatermark 在图片上添加文字水印
func addWatermark(img image.Image, text string) (image.Image, error) {
	bounds := img.Bounds()
	rgba := image.NewRGBA(bounds)

	// 复制原图
	draw.Draw(rgba, bounds, img, bounds.Min, draw.Src)

	// 使用basicfont绘制文字
	face := basicfont.Face7x13

	// 计算文字宽度和高度
	textWidth := len(text) * 7 // basicfont.Face7x13 每个字符约7像素宽
	textHeight := 13           // basicfont.Face7x13 高度约13像素

	// 计算文字位置（右下角，留出边距）
	margin := 15
	x := bounds.Max.X - textWidth - margin
	y := bounds.Max.Y - margin

	// 先绘制半透明黑色背景，让文字更清晰
	bgRect := image.Rect(x-5, y-textHeight-2, x+textWidth+5, y+3)
	bgColor := color.RGBA{R: 0, G: 0, B: 0, A: 180}
	draw.Draw(rgba, bgRect, &image.Uniform{bgColor}, image.Point{}, draw.Over)

	// 绘制白色文字
	d := &font.Drawer{
		Dst:  rgba,
		Src:  image.NewUniform(color.RGBA{R: 255, G: 255, B: 255, A: 255}),
		Face: face,
	}

	// 绘制文字（使用固定点，注意y坐标是基线位置）
	d.Dot = fixed.P(x, y)
	d.DrawString(text)

	return rgba, nil
}
