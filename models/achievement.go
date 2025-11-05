package models

import (
	"time"
)

type AchievementType struct {
	ID           int       `json:"id" db:"id"`
	Code         string    `json:"code" db:"code"`
	Name         string    `json:"name" db:"name"`
	Description  string    `json:"description" db:"description"`
	RewardPoints int       `json:"reward_points" db:"reward_points"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

type UserAchievement struct {
	ID                int        `json:"id" db:"id"`
	UserID            int        `json:"user_id" db:"user_id"`
	AchievementTypeID int        `json:"achievement_type_id" db:"achievement_type_id"`
	UnlockedAt        time.Time  `json:"unlocked_at" db:"unlocked_at"`
	ClaimedAt         *time.Time `json:"claimed_at" db:"claimed_at"`
}

type AchievementStatus struct {
	AchievementType AchievementType `json:"achievement_type"`
	Unlocked        bool            `json:"unlocked"`
	UnlockedAt      *time.Time      `json:"unlocked_at"`
	Claimed         bool            `json:"claimed"`
	ClaimedAt       *time.Time      `json:"claimed_at"`
	Progress        interface{}     `json:"progress"` // 进度信息，根据成就类型不同
}

type ClaimRewardRequest struct {
	AchievementTypeID int `json:"achievement_type_id"`
}

type RedemptionRequest struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
