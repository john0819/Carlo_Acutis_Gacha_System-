package models

import (
	"time"
)

type Card struct {
	ID          int       `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	ImageURL    string    `json:"image_url" db:"image_url"`
	Rarity      string    `json:"rarity" db:"rarity"`
	Description *string   `json:"description" db:"description"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type UserCard struct {
	ID         int       `json:"id" db:"id"`
	UserID     int       `json:"user_id" db:"user_id"`
	CardID     int       `json:"card_id" db:"card_id"`
	ObtainedAt time.Time `json:"obtained_at" db:"obtained_at"`
}

type DailyDraw struct {
	ID        int       `json:"id" db:"id"`
	UserID    int       `json:"user_id" db:"user_id"`
	CardID    int       `json:"card_id" db:"card_id"`
	DrawDate  time.Time `json:"draw_date" db:"draw_date"`
	IsNewCard bool      `json:"is_new_card" db:"is_new_card"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type DrawResponse struct {
	Card      Card   `json:"card"`
	IsNewCard bool   `json:"is_new_card"`
	Message   string `json:"message"`
}
