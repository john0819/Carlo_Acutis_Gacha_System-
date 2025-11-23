package auth

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"log"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret []byte

func init() {
	// 从环境变量获取JWT密钥，如果没有则生成一个随机密钥
	secretStr := os.Getenv("JWT_SECRET")
	if secretStr == "" {
		log.Println("⚠️  警告: 未设置JWT_SECRET环境变量，使用随机生成的密钥")
		// 生成32字节的随机密钥
		randomBytes := make([]byte, 32)
		if _, err := rand.Read(randomBytes); err != nil {
			log.Fatal("生成JWT密钥失败:", err)
		}
		jwtSecret = randomBytes
		log.Printf("🔑 已生成随机JWT密钥: %s", base64.StdEncoding.EncodeToString(jwtSecret))
	} else {
		// 如果是base64编码的密钥，先解码
		if decoded, err := base64.StdEncoding.DecodeString(secretStr); err == nil && len(decoded) >= 32 {
			jwtSecret = decoded
		} else {
			// 否则直接使用字符串（但长度至少32字符）
			if len(secretStr) < 32 {
				log.Fatal("JWT_SECRET长度至少需要32字符")
			}
			jwtSecret = []byte(secretStr)
		}
		log.Println("✅ JWT密钥已从环境变量加载")
	}
}

type Claims struct {
	UserID   int    `json:"user_id"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

func GenerateToken(userID int, username string) (string, error) {
	expirationTime := time.Now().Add(24 * 7 * time.Hour) // 7天过期
	claims := &Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

func ValidateToken(tokenString string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}
