package models

import "time"

type CheckinLocation struct {
	ID              int       `json:"id" db:"id"`
	Name            string    `json:"name" db:"name"`
	Latitude        float64   `json:"latitude" db:"latitude"`
	Longitude       float64   `json:"longitude" db:"longitude"`
	RadiusMeters    int       `json:"radius_meters" db:"radius_meters"`
	AchievementCode string    `json:"achievement_code" db:"achievement_code"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
}

type LocationCheckin struct {
	ID          int       `json:"id" db:"id"`
	UserID      int       `json:"user_id" db:"user_id"`
	LocationID  int       `json:"location_id" db:"location_id"`
	CheckinDate time.Time `json:"checkin_date" db:"checkin_date"`
	Latitude    *float64  `json:"latitude" db:"latitude"`
	Longitude   *float64  `json:"longitude" db:"longitude"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type DrawCardRequest struct {
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
}
