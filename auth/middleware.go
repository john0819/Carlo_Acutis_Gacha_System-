package auth

import (
	"context"
	"net/http"
	"strings"
)

type contextKey string

const userIDKey contextKey = "userID"
const usernameKey contextKey = "username"

func JWTMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "未授权", http.StatusUnauthorized)
			return
		}

		// Bearer token
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, "无效的授权格式", http.StatusUnauthorized)
			return
		}

		tokenString := parts[1]
		claims, err := ValidateToken(tokenString)
		if err != nil {
			http.Error(w, "无效的token", http.StatusUnauthorized)
			return
		}

		// 将用户信息存储到请求上下文
		ctx := context.WithValue(r.Context(), userIDKey, claims.UserID)
		ctx = context.WithValue(ctx, usernameKey, claims.Username)
		r = r.WithContext(ctx)

		next(w, r)
	}
}

func GetUserIDFromRequest(r *http.Request) (int, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return 0, ErrTokenMissing
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 {
		return 0, ErrTokenInvalid
	}

	claims, err := ValidateToken(parts[1])
	if err != nil {
		return 0, err
	}

	return claims.UserID, nil
}

var (
	ErrTokenMissing = &AuthError{Message: "token缺失"}
	ErrTokenInvalid = &AuthError{Message: "token无效"}
)

type AuthError struct {
	Message string
}

func (e *AuthError) Error() string {
	return e.Message
}
