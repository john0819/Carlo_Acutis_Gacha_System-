package handlers

import (
	"encoding/json"
	"hash/fnv"
	"net/http"
	"os"
	"time"
)

type QuoteResponse struct {
	Quote string `json:"quote"`
	Date  string `json:"date"`
}

// GetDailyQuote 获取每日语录（每天固定同一句）
func GetDailyQuote(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		sendError(w, "方法不允许", http.StatusMethodNotAllowed)
		return
	}

	// 读取语录文件
	file, err := os.Open("./static/quotes.json")
	if err != nil {
		sendError(w, "读取语录失败", http.StatusInternalServerError)
		return
	}
	defer file.Close()

	var data struct {
		Quotes []string `json:"quotes"`
	}
	if err := json.NewDecoder(file).Decode(&data); err != nil {
		sendError(w, "解析语录失败", http.StatusInternalServerError)
		return
	}

	if len(data.Quotes) == 0 {
		sendError(w, "语录库为空", http.StatusInternalServerError)
		return
	}

	// 根据日期选择语录（确保每天都是同一句，所有人看到的都一样）
	today := time.Now().Format("2006-01-02")

	// 使用日期字符串的哈希值来选择语录，确保同一天总是选择同一句
	h := fnv.New32a()
	h.Write([]byte(today))
	hashValue := h.Sum32()

	// 使用哈希值模语录数量来选择语录
	selectedIndex := int(hashValue) % len(data.Quotes)
	selectedQuote := data.Quotes[selectedIndex]

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(QuoteResponse{
		Quote: selectedQuote,
		Date:  today,
	})
}
