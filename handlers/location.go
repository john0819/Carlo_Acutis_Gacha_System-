package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"h5project/auth"
	"h5project/database"
)

// GetLocationSetting 获取位置校验设置
func GetLocationSetting(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	var enabled bool
	err := database.DB.QueryRow(
		"SELECT value = 'true' FROM system_config WHERE key = 'location_check_enabled'",
	).Scan(&enabled)
	if err != nil {
		enabled = false
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"enabled": enabled,
	})
}

// GetCheckinLocations 获取所有打卡地点
func GetCheckinLocations(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	rows, err := database.DB.Query(
		"SELECT id, name, latitude, longitude, radius_meters, achievement_code FROM checkin_locations ORDER BY id",
	)
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var locations []map[string]interface{}
	for rows.Next() {
		var id int
		var name string
		var latitude, longitude float64
		var radiusMeters int
		var achievementCode sql.NullString

		err := rows.Scan(&id, &name, &latitude, &longitude, &radiusMeters, &achievementCode)
		if err != nil {
			continue
		}

		loc := map[string]interface{}{
			"id":            id,
			"name":          name,
			"latitude":      latitude,
			"longitude":     longitude,
			"radius_meters": radiusMeters,
		}
		if achievementCode.Valid {
			loc["achievement_code"] = achievementCode.String
		}
		locations = append(locations, loc)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"locations": locations,
	})
}

// GetUserLocationCheckins 获取用户地点打卡统计
func GetUserLocationCheckins(w http.ResponseWriter, r *http.Request) {
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
		`SELECT lc.location_id, cl.name, COUNT(*) as checkin_count
		 FROM location_checkins lc
		 JOIN checkin_locations cl ON lc.location_id = cl.id
		 WHERE lc.user_id = $1
		 GROUP BY lc.location_id, cl.name
		 ORDER BY lc.location_id`,
		userID,
	)
	if err != nil {
		sendError(w, "查询失败", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var stats []map[string]interface{}
	for rows.Next() {
		var locationID, checkinCount int
		var locationName string
		err := rows.Scan(&locationID, &locationName, &checkinCount)
		if err != nil {
			continue
		}
		stats = append(stats, map[string]interface{}{
			"location_id":   locationID,
			"location_name": locationName,
			"checkin_count": checkinCount,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"stats": stats,
	})
}
