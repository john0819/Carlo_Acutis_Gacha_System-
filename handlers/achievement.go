package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"h5project/auth"
	"h5project/database"
	"h5project/models"
)

// CheckAchievements 检查用户成就（在获得新卡后调用）
func CheckAchievements(userID int) ([]models.AchievementStatus, error) {
	var newAchievements []models.AchievementStatus

	// 获取用户拥有的所有不重复卡片数量
	var cardCount int
	err := database.DB.QueryRow(
		"SELECT COUNT(DISTINCT card_id) FROM user_cards WHERE user_id = $1",
		userID,
	).Scan(&cardCount)
	if err != nil {
		return nil, err
	}

	// 检查成就1: 一点星星之光 - 获得第一张卡
	if cardCount >= 1 {
		err = checkAndUnlockAchievement(userID, "first_card")
		if err == nil {
			ach, _ := getAchievementStatus(userID, "first_card")
			if ach != nil && !ach.Claimed {
				newAchievements = append(newAchievements, *ach)
			}
		}
	}

	// 检查成就2: 朝圣新星 - 累计在3个不同的教堂打卡成功
	// 这里暂时用累计打卡3次来模拟（实际应该是3个不同地点）
	var checkinCount int
	database.DB.QueryRow(
		"SELECT COUNT(DISTINCT draw_date) FROM daily_draws WHERE user_id = $1",
		userID,
	).Scan(&checkinCount)
	if checkinCount >= 3 {
		err = checkAndUnlockAchievement(userID, "pilgrim_nova")
		if err == nil {
			ach, _ := getAchievementStatus(userID, "pilgrim_nova")
			if ach != nil && !ach.Claimed {
				newAchievements = append(newAchievements, *ach)
			}
		}
	}

	// 检查成就3: 收集天上的宝藏 - 每7张不同卡片就会点亮一次（自动领取）
	// 条件：卡片数 >= 7 且卡片数是7的倍数
	// 这个成就是自动领取的，每达到7的倍数就自动获得奖励
	if cardCount >= 7 && cardCount%7 == 0 {
		// 检查这个里程碑是否已经领取过（使用milestone_claims表追踪）
		var alreadyClaimed bool
		err = database.DB.QueryRow(
			"SELECT EXISTS(SELECT 1 FROM milestone_claims WHERE user_id = $1 AND card_count = $2)",
			userID, cardCount,
		).Scan(&alreadyClaimed)

		if !alreadyClaimed {
			// 获取奖励点数
			var rewardPoints int
			database.DB.QueryRow(
				"SELECT reward_points FROM achievement_types WHERE code = 'milestone_7'",
			).Scan(&rewardPoints)

			// 记录这次里程碑领取
			_, err = database.DB.Exec(
				"INSERT INTO milestone_claims (user_id, card_count) VALUES ($1, $2)",
				userID, cardCount,
			)
			if err == nil {
				// 自动增加兑换点
				database.DB.Exec(
					"UPDATE users SET exchange_points = exchange_points + $1 WHERE id = $2",
					rewardPoints, userID,
				)

				// 确保成就已解锁（用于显示）
				var achievementTypeID int
				database.DB.QueryRow(
					"SELECT id FROM achievement_types WHERE code = 'milestone_7'",
				).Scan(&achievementTypeID)

				var exists bool
				database.DB.QueryRow(
					"SELECT EXISTS(SELECT 1 FROM user_achievements WHERE user_id = $1 AND achievement_type_id = $2)",
					userID, achievementTypeID,
				).Scan(&exists)

				if !exists {
					database.DB.Exec(
						"INSERT INTO user_achievements (user_id, achievement_type_id, unlocked_at, claimed_at) VALUES ($1, $2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
						userID, achievementTypeID,
					)
				} else {
					// 更新领取时间
					database.DB.Exec(
						"UPDATE user_achievements SET claimed_at = CURRENT_TIMESTAMP WHERE user_id = $1 AND achievement_type_id = $2",
						userID, achievementTypeID,
					)
				}

				ach, _ := getAchievementStatus(userID, "milestone_7")
				if ach != nil {
					newAchievements = append(newAchievements, *ach)
				}
			}
		}
	}

	// 检查成就4: 圣卡洛的圣体奇迹集 - 集齐所有打卡图片
	var totalCardCount int
	database.DB.QueryRow("SELECT COUNT(*) FROM cards").Scan(&totalCardCount)
	if cardCount >= totalCardCount && totalCardCount > 0 {
		err = checkAndUnlockAchievement(userID, "complete_all")
		if err == nil {
			ach, _ := getAchievementStatus(userID, "complete_all")
			if ach != nil && !ach.Claimed {
				newAchievements = append(newAchievements, *ach)
			}
		}
	}

	return newAchievements, nil
}

// verifyAchievementCondition 验证成就条件是否满足
func verifyAchievementCondition(userID int, achievementCode string) bool {
	switch achievementCode {
	case "first_card":
		var count int
		database.DB.QueryRow(
			"SELECT COUNT(*) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&count)
		return count >= 1
	case "pilgrim_nova":
		// 朝圣新星 - 累计在3个不同的教堂打卡成功
		var checkinCount int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT draw_date) FROM daily_draws WHERE user_id = $1",
			userID,
		).Scan(&checkinCount)
		return checkinCount >= 3
	case "complete_series":
		// 检查是否集齐一个系列
		var rarities []string
		rows, err := database.DB.Query("SELECT DISTINCT rarity FROM cards")
		if err != nil {
			return false
		}
		defer rows.Close()

		for rows.Next() {
			var rarity string
			if err := rows.Scan(&rarity); err == nil {
				rarities = append(rarities, rarity)
			}
		}

		for _, rarity := range rarities {
			var seriesCardIDs []int
			seriesRows, err := database.DB.Query(
				"SELECT id FROM cards WHERE rarity = $1",
				rarity,
			)
			if err != nil {
				continue
			}
			for seriesRows.Next() {
				var cardID int
				if err := seriesRows.Scan(&cardID); err == nil {
					seriesCardIDs = append(seriesCardIDs, cardID)
				}
			}
			seriesRows.Close()

			if len(seriesCardIDs) == 0 {
				continue
			}

			var userOwnedCount int
			placeholders := ""
			args := []interface{}{userID}
			for i, cardID := range seriesCardIDs {
				if i > 0 {
					placeholders += ","
				}
				placeholders += fmt.Sprintf("$%d", i+2)
				args = append(args, cardID)
			}
			query := fmt.Sprintf(
				`SELECT COUNT(DISTINCT card_id) FROM user_cards 
				 WHERE user_id = $1 AND card_id IN (%s)`,
				placeholders,
			)
			err = database.DB.QueryRow(query, args...).Scan(&userOwnedCount)

			if err == nil && userOwnedCount == len(seriesCardIDs) {
				return true
			}
		}
		return false
	case "milestone_7":
		var count int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT card_id) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&count)
		// 必须是7的倍数且>=7
		return count >= 7 && count%7 == 0
	case "location_a_15", "location_b_15", "location_c_15":
		// 地点成就：检查用户在对应地点打卡次数
		var locationID int
		err := database.DB.QueryRow(
			"SELECT id FROM checkin_locations WHERE achievement_code = $1",
			achievementCode,
		).Scan(&locationID)
		if err != nil {
			return false
		}

		var checkinCount int
		database.DB.QueryRow(
			"SELECT COUNT(*) FROM location_checkins WHERE user_id = $1 AND location_id = $2",
			userID, locationID,
		).Scan(&checkinCount)
		return checkinCount >= 15
	case "complete_all":
		// 圣卡洛的圣体奇迹集 - 集齐所有打卡图片
		var userCardCount int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT card_id) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&userCardCount)
		var totalCardCount int
		database.DB.QueryRow("SELECT COUNT(*) FROM cards").Scan(&totalCardCount)
		return totalCardCount > 0 && userCardCount >= totalCardCount
	default:
		return false
	}
}

// checkAndUnlockAchievement 检查并解锁成就
func checkAndUnlockAchievement(userID int, achievementCode string) error {
	// 获取成就类型ID
	var achievementTypeID int
	err := database.DB.QueryRow(
		"SELECT id FROM achievement_types WHERE code = $1",
		achievementCode,
	).Scan(&achievementTypeID)
	if err != nil {
		return err
	}

	// 检查是否已解锁
	var exists bool
	err = database.DB.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM user_achievements WHERE user_id = $1 AND achievement_type_id = $2)",
		userID, achievementTypeID,
	).Scan(&exists)
	if err != nil {
		return err
	}

	// 如果未解锁，则解锁
	if !exists {
		_, err = database.DB.Exec(
			"INSERT INTO user_achievements (user_id, achievement_type_id) VALUES ($1, $2)",
			userID, achievementTypeID,
		)
		return err
	}

	return nil
}

// checkCompleteSeries 检查是否集齐一个系列
func checkCompleteSeries(userID int) error {
	// 获取所有系列（rarity）
	var rarities []string
	rows, err := database.DB.Query("SELECT DISTINCT rarity FROM cards")
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var rarity string
		if err := rows.Scan(&rarity); err == nil {
			rarities = append(rarities, rarity)
		}
	}

	// 检查用户是否集齐了某个系列的所有卡片
	for _, rarity := range rarities {
		// 获取该系列的所有卡片ID
		var seriesCardIDs []int
		seriesRows, err := database.DB.Query(
			"SELECT id FROM cards WHERE rarity = $1",
			rarity,
		)
		if err != nil {
			continue
		}
		for seriesRows.Next() {
			var cardID int
			if err := seriesRows.Scan(&cardID); err == nil {
				seriesCardIDs = append(seriesCardIDs, cardID)
			}
		}
		seriesRows.Close()

		if len(seriesCardIDs) == 0 {
			continue
		}

		// 检查用户是否拥有该系列的所有卡片
		var userOwnedCount int
		placeholders := ""
		args := []interface{}{userID}
		for i, cardID := range seriesCardIDs {
			if i > 0 {
				placeholders += ","
			}
			placeholders += fmt.Sprintf("$%d", i+2)
			args = append(args, cardID)
		}
		query := fmt.Sprintf(
			`SELECT COUNT(DISTINCT card_id) FROM user_cards 
			 WHERE user_id = $1 AND card_id IN (%s)`,
			placeholders,
		)
		err = database.DB.QueryRow(query, args...).Scan(&userOwnedCount)

		// 如果集齐了，解锁成就
		if err == nil && userOwnedCount == len(seriesCardIDs) {
			return checkAndUnlockAchievement(userID, "complete_series")
		}
	}

	return nil
}

// GetAchievements 获取用户所有成就状态
func GetAchievements(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	// 先检查并解锁应该解锁的成就（避免用户已有卡片但成就未解锁的情况）
	_, _ = CheckAchievements(userID)

	// 获取所有成就类型（排除complete_series）
	rows, err := database.DB.Query(
		"SELECT id, code, name, description, reward_points FROM achievement_types WHERE code != 'complete_series' ORDER BY id",
	)
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var achievements []models.AchievementStatus
	for rows.Next() {
		var achType models.AchievementType
		err := rows.Scan(
			&achType.ID, &achType.Code, &achType.Name,
			&achType.Description, &achType.RewardPoints,
		)
		if err != nil {
			continue
		}

		// 如果是地点成就，动态更新描述为实际地点名称
		if achType.Code == "location_a_15" || achType.Code == "location_b_15" || achType.Code == "location_c_15" {
			var locationName string
			err := database.DB.QueryRow(
				"SELECT name FROM checkin_locations WHERE achievement_code = $1 LIMIT 1",
				achType.Code,
			).Scan(&locationName)
			if err == nil && locationName != "" {
				achType.Description = "在" + locationName + "累计打卡15次"
			}
		}

		// 获取用户该成就的状态
		status, _ := getAchievementStatus(userID, achType.Code)
		if status == nil {
			status = &models.AchievementStatus{
				AchievementType: achType,
				Unlocked:        false,
				Claimed:         false,
			}
		} else {
			// 更新描述（使用动态获取的地点名称）
			status.AchievementType.Description = achType.Description
		}

		// 设置进度信息
		status.Progress = getAchievementProgress(userID, achType.Code)

		// 验证：如果成就已解锁但条件不满足，清除解锁状态（修复历史错误数据）
		if status.Unlocked && !status.Claimed {
			if !verifyAchievementCondition(userID, achType.Code) {
				// 条件不满足，清除解锁状态
				status.Unlocked = false
				status.UnlockedAt = nil
				// 从数据库中删除错误的解锁记录
				var achievementTypeID int
				if err := database.DB.QueryRow(
					"SELECT id FROM achievement_types WHERE code = $1",
					achType.Code,
				).Scan(&achievementTypeID); err == nil {
					database.DB.Exec(
						"DELETE FROM user_achievements WHERE user_id = $1 AND achievement_type_id = $2 AND claimed_at IS NULL",
						userID, achievementTypeID,
					)
				}
			}
		}

		achievements = append(achievements, *status)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"achievements": achievements,
	})
}

// getAchievementStatus 获取单个成就的状态
func getAchievementStatus(userID int, achievementCode string) (*models.AchievementStatus, error) {
	var achType models.AchievementType
	var unlockedAt, claimedAt sql.NullTime

	err := database.DB.QueryRow(
		`SELECT at.id, at.code, at.name, at.description, at.reward_points,
			ua.unlocked_at, ua.claimed_at
		 FROM achievement_types at
		 LEFT JOIN user_achievements ua ON at.id = ua.achievement_type_id AND ua.user_id = $1
		 WHERE at.code = $2`,
		userID, achievementCode,
	).Scan(
		&achType.ID, &achType.Code, &achType.Name, &achType.Description, &achType.RewardPoints,
		&unlockedAt, &claimedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	status := &models.AchievementStatus{
		AchievementType: achType,
		Unlocked:        unlockedAt.Valid,
		Claimed:         claimedAt.Valid,
	}

	if unlockedAt.Valid {
		status.UnlockedAt = &unlockedAt.Time
	}
	if claimedAt.Valid {
		status.ClaimedAt = &claimedAt.Time
	}

	return status, nil
}

// getAchievementProgress 获取成就进度
func getAchievementProgress(userID int, achievementCode string) interface{} {
	switch achievementCode {
	case "first_card":
		var count int
		database.DB.QueryRow(
			"SELECT COUNT(*) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&count)
		return map[string]interface{}{
			"current": count,
			"target":  1,
		}
	case "complete_series":
		// 返回用户拥有的卡片数和总系列数
		var cardCount int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT card_id) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&cardCount)
		var seriesCount int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT rarity) FROM cards",
		).Scan(&seriesCount)
		return map[string]interface{}{
			"card_count":   cardCount,
			"series_count": seriesCount,
		}
	case "milestone_7":
		var count int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT card_id) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&count)
		nextMilestone := ((count-1)/7 + 1) * 7
		return map[string]interface{}{
			"current":        count,
			"next_milestone": nextMilestone,
		}
	case "complete_all":
		// 圣卡洛的圣体奇迹集 - 集齐所有打卡图片
		var userCardCount int
		database.DB.QueryRow(
			"SELECT COUNT(DISTINCT card_id) FROM user_cards WHERE user_id = $1",
			userID,
		).Scan(&userCardCount)
		var totalCardCount int
		database.DB.QueryRow("SELECT COUNT(*) FROM cards").Scan(&totalCardCount)
		return map[string]interface{}{
			"current": userCardCount,
			"target":  totalCardCount,
		}
	case "location_a_15", "location_b_15", "location_c_15":
		// 地点成就：显示打卡进度
		var locationID int
		err := database.DB.QueryRow(
			"SELECT id FROM checkin_locations WHERE achievement_code = $1",
			achievementCode,
		).Scan(&locationID)
		if err != nil {
			return nil
		}

		var checkinCount int
		database.DB.QueryRow(
			"SELECT COUNT(*) FROM location_checkins WHERE user_id = $1 AND location_id = $2",
			userID, locationID,
		).Scan(&checkinCount)
		return map[string]interface{}{
			"current": checkinCount,
			"target":  15,
		}
	default:
		return nil
	}
}

// ClaimReward 领取成就奖励
func ClaimReward(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	var req models.ClaimRewardRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "无效的请求数据", http.StatusBadRequest)
		return
	}

	// 获取成就类型代码
	var achievementCode string
	err = database.DB.QueryRow(
		"SELECT code FROM achievement_types WHERE id = $1",
		req.AchievementTypeID,
	).Scan(&achievementCode)
	if err != nil {
		sendError(w, "成就不存在", http.StatusNotFound)
		return
	}

	// milestone_7是自动领取的，不允许手动领取
	if achievementCode == "milestone_7" {
		sendError(w, "此成就奖励已自动领取，无需手动操作", http.StatusForbidden)
		return
	}

	// 验证成就条件是否仍然满足（防止之前错误解锁的成就被领取）
	if !verifyAchievementCondition(userID, achievementCode) {
		sendError(w, "成就条件不满足，无法领取奖励", http.StatusForbidden)
		return
	}

	// 检查成就是否已解锁且未领取
	var unlocked bool
	var claimed bool
	var rewardPoints int
	err = database.DB.QueryRow(
		`SELECT 
			COALESCE(ua.unlocked_at IS NOT NULL, false) as unlocked,
			COALESCE(ua.claimed_at IS NOT NULL, false) as claimed,
			at.reward_points
		 FROM achievement_types at
		 LEFT JOIN user_achievements ua ON at.id = ua.achievement_type_id AND ua.user_id = $1
		 WHERE at.id = $2`,
		userID, req.AchievementTypeID,
	).Scan(&unlocked, &claimed, &rewardPoints)
	if err != nil {
		sendError(w, "成就不存在", http.StatusNotFound)
		return
	}

	if !unlocked {
		sendError(w, "成就未解锁", http.StatusForbidden)
		return
	}

	if claimed {
		sendError(w, "奖励已领取", http.StatusConflict)
		return
	}

	// 更新领取时间
	_, err = database.DB.Exec(
		"UPDATE user_achievements SET claimed_at = CURRENT_TIMESTAMP WHERE user_id = $1 AND achievement_type_id = $2",
		userID, req.AchievementTypeID,
	)
	if err != nil {
		sendError(w, "更新失败", http.StatusInternalServerError)
		return
	}

	// 增加用户兑换点
	_, err = database.DB.Exec(
		"UPDATE users SET exchange_points = exchange_points + $1 WHERE id = $2",
		rewardPoints, userID,
	)
	if err != nil {
		sendError(w, "更新兑换点失败", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":       true,
		"reward_points": rewardPoints,
		"message":       fmt.Sprintf("成功领取 %d 兑换点", rewardPoints),
	})
}

// RedeemRequest 兑换请求
type RedeemRequest struct {
	Type string `json:"type"` // "basic" 或 "premium"
}

// Redeem 兑换接口
func Redeem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	// 解析请求体
	var req RedeemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, "请求格式错误", http.StatusBadRequest)
		return
	}

	// 验证兑换类型
	if req.Type != "basic" && req.Type != "premium" {
		sendError(w, "无效的兑换类型，必须是 'basic' 或 'premium'", http.StatusBadRequest)
		return
	}

	// 确定兑换成本
	var cost int
	if req.Type == "basic" {
		cost = 1
	} else {
		cost = 5
	}

	// 获取当前月份
	currentMonth := time.Now().Format("2006-01")

	// 检查本月是否已兑换（不管哪种类型，一个月总共只能兑换一次）
	var alreadyRedeemed bool
	var redeemedAt time.Time
	var redeemedType string
	err = database.DB.QueryRow(
		"SELECT EXISTS(SELECT 1 FROM redemption_records WHERE user_id = $1 AND redemption_month = $2), COALESCE((SELECT redeemed_at FROM redemption_records WHERE user_id = $1 AND redemption_month = $2 LIMIT 1), CURRENT_TIMESTAMP), COALESCE((SELECT redemption_type FROM redemption_records WHERE user_id = $1 AND redemption_month = $2 LIMIT 1), '')",
		userID, currentMonth,
	).Scan(&alreadyRedeemed, &redeemedAt, &redeemedType)
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}

	if alreadyRedeemed {
		var previousTypeName string
		if redeemedType == "basic" {
			previousTypeName = "基础兑换（钓圣人徽章机会）"
		} else if redeemedType == "premium" {
			previousTypeName = "高级兑换（指定圣人徽章）"
		} else {
			previousTypeName = "兑换"
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error":       "本月已兑换",
			"message":     fmt.Sprintf("您已于 %s 兑换过%s，每月只能兑换一次，请下月再来", redeemedAt.Format("2006-01-02 15:04:05"), previousTypeName),
			"redeemed_at": redeemedAt.Format("2006-01-02 15:04:05"),
		})
		return
	}

	// 检查用户兑换点
	var exchangePoints int
	err = database.DB.QueryRow(
		"SELECT exchange_points FROM users WHERE id = $1",
		userID,
	).Scan(&exchangePoints)
	if err != nil {
		sendError(w, "查询用户信息失败", http.StatusInternalServerError)
		return
	}

	if exchangePoints < cost {
		sendError(w, fmt.Sprintf("兑换点不足，需要至少%d个兑换点", cost), http.StatusForbidden)
		return
	}

	// 记录兑换
	_, err = database.DB.Exec(
		"INSERT INTO redemption_records (user_id, redemption_month, redemption_type) VALUES ($1, $2, $3)",
		userID, currentMonth, req.Type,
	)
	if err != nil {
		sendError(w, "记录兑换失败", http.StatusInternalServerError)
		return
	}

	// 扣除兑换点
	_, err = database.DB.Exec(
		"UPDATE users SET exchange_points = exchange_points - $1 WHERE id = $2",
		cost, userID,
	)
	if err != nil {
		sendError(w, "扣除兑换点失败", http.StatusInternalServerError)
		return
	}

	now := time.Now()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":     true,
		"message":     fmt.Sprintf("兑换成功！请到罗源南门堂圣物部领取奖励"),
		"redeemed_at": now.Format("2006-01-02 15:04:05"),
		"type":        req.Type,
		"cost":        cost,
	})
}

// GetRedemptionInfo 获取兑换信息（包括兑换地点和本月兑换状态）
func GetRedemptionInfo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	userID, err := auth.GetUserIDFromRequest(r)
	if err != nil {
		sendError(w, "未授权", http.StatusUnauthorized)
		return
	}

	// 获取当前月份
	currentMonth := time.Now().Format("2006-01")

	// 检查本月是否已兑换（不管哪种类型，一个月总共只能兑换一次）
	var redeemedAt sql.NullTime
	var redeemedType sql.NullString
	database.DB.QueryRow(
		"SELECT redeemed_at, redemption_type FROM redemption_records WHERE user_id = $1 AND redemption_month = $2 LIMIT 1",
		userID, currentMonth,
	).Scan(&redeemedAt, &redeemedType)

	hasRedeemed := redeemedAt.Valid
	basicRedeemed := hasRedeemed && redeemedType.Valid && redeemedType.String == "basic"
	premiumRedeemed := hasRedeemed && redeemedType.Valid && redeemedType.String == "premium"

	// 获取用户兑换点
	var exchangePoints int
	database.DB.QueryRow(
		"SELECT exchange_points FROM users WHERE id = $1",
		userID,
	).Scan(&exchangePoints)

	// 兑换地点信息
	redemptionLocation := "罗源南门堂圣物部"

	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"has_redeemed":        hasRedeemed,
		"basic_redeemed":      basicRedeemed,
		"premium_redeemed":    premiumRedeemed,
		"exchange_points":     exchangePoints,
		"redemption_location": redemptionLocation,
		"current_month":       currentMonth,
	}

	if redeemedAt.Valid {
		response["redeemed_at"] = redeemedAt.Time.Format("2006-01-02 15:04:05")
		if redeemedType.Valid {
			response["redeemed_type"] = redeemedType.String
		}
	}

	json.NewEncoder(w).Encode(response)
}
