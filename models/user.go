package models

import (
	"time"
)

type User struct {
	ID             int        `json:"id" db:"id"`
	Username       string     `json:"username" db:"username"`
	PasswordHash   string     `json:"-" db:"password_hash"`
	HolyName       *string    `json:"holy_name" db:"holy_name"`
	Nickname       *string    `json:"nickname" db:"nickname"`
	Birthday       *time.Time `json:"birthday" db:"birthday"`
	CheckinCount   int        `json:"checkin_count" db:"checkin_count"`
	ExchangePoints int        `json:"exchange_points" db:"exchange_points"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at" db:"updated_at"`
}

type RegisterRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type UpdateProfileRequest struct {
	HolyName *string    `json:"holy_name"`
	Nickname *string    `json:"nickname"`
	Birthday *time.Time `json:"birthday"`
}
