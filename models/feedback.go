package models

import (
	"time"
)

type Feedback struct {
	ID        int       `json:"id" db:"id"`
	UserID    int       `json:"user_id" db:"user_id"`
	Content   string    `json:"content" db:"content"`
	Type      string    `json:"type" db:"type"`     // bug, suggestion, other
	Status    string    `json:"status" db:"status"` // pending, resolved
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type FeedbackRequest struct {
	Content string `json:"content"`
	Type    string `json:"type"` // bug, suggestion, other
}
