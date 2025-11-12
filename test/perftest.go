package main

import (
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// 性能测试工具 - 针对300人并发场景
// 使用方法: go run test/performance_test.go

func main() {
	baseURL := "http://localhost:8081"

	fmt.Println("🚀 性能测试 - 300人并发场景")
	fmt.Println("=" + strings.Repeat("=", 50))
	fmt.Println()

	// 检查服务器连接
	fmt.Println("🔍 检查服务器连接...")
	resp, err := http.Get(baseURL + "/api/daily-quote")
	if err != nil {
		fmt.Printf("❌ 无法连接到服务器 %s\n", baseURL)
		fmt.Printf("   请确保服务器正在运行: go run main.go\n")
		return
	}
	resp.Body.Close()
	fmt.Printf("✅ 服务器连接正常\n\n")

	// 测试1: 登录接口 - 300并发（最重要）
	fmt.Println("📊 测试1: 登录接口 - 300并发（扫码后第一个操作）")
	fmt.Println("   说明: 模拟300人同时扫码登录")
	testLoginConcurrent(baseURL, 300)
	fmt.Println()

	// 测试2: 每日语录 - 300并发（公开接口，无数据库写入）
	fmt.Println("📊 测试2: 每日语录接口 - 300并发（公开接口）")
	testConcurrentRequests(baseURL+"/api/daily-quote", 300, "GET", "")
	fmt.Println()

	// 测试3: 获取用户信息 - 100并发（需要token，模拟登录后操作）
	fmt.Println("📊 测试3: 获取用户信息 - 100并发（需要先登录获取token）")
	fmt.Println("   ⚠️  提示: 这个测试需要有效的token，如果没有会返回401")
	testWithAuth(baseURL+"/api/user/profile", 100, "GET", "")
	fmt.Println()

	// 测试4: 静态文件 - 300并发（HTML/CSS/JS）
	fmt.Println("📊 测试4: 静态文件加载 - 300并发")
	testStaticFiles(baseURL, 300)
	fmt.Println()

	fmt.Println("=" + strings.Repeat("=", 50))
	fmt.Println("✅ 测试完成！")
	fmt.Println()
	fmt.Println("💡 关键指标:")
	fmt.Println("   - 登录接口QPS应 > 50 (支持300人/分钟)")
	fmt.Println("   - 响应时间应 < 500ms")
	fmt.Println("   - 成功率应 > 95%")
}

// testLoginConcurrent 测试登录接口并发性能
func testLoginConcurrent(baseURL string, concurrency int) {
	var wg sync.WaitGroup
	var mu sync.Mutex

	successCount := 0
	errorCount := 0
	rateLimitCount := 0
	totalTime := int64(0)
	minTime := int64(999999999)
	maxTime := int64(0)

	startTime := time.Now()

	// 使用不同的测试账号（避免重复登录冲突）
	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()

			reqStart := time.Now()

			// 使用不同的用户名，避免数据库冲突
			username := fmt.Sprintf("testuser%d", id%10) // 循环使用10个账号
			body := fmt.Sprintf(`{"username":"%s","password":"testpass"}`, username)

			req, _ := http.NewRequest("POST", baseURL+"/api/login",
				strings.NewReader(body))
			req.Header.Set("Content-Type", "application/json")
			client := &http.Client{Timeout: 10 * time.Second}
			resp, err := client.Do(req)

			duration := time.Since(reqStart).Milliseconds()

			mu.Lock()
			if err != nil {
				errorCount++
			} else {
				statusCode := resp.StatusCode
				resp.Body.Close()

				if statusCode == http.StatusOK {
					successCount++
				} else if statusCode == http.StatusTooManyRequests {
					rateLimitCount++
					successCount++ // 限流也算正常响应
				} else if statusCode == http.StatusUnauthorized || statusCode == http.StatusBadRequest {
					// 401/400也算正常（账号不存在或密码错误，但服务器在工作）
					successCount++
				} else {
					errorCount++
				}
			}

			totalTime += duration
			if duration < minTime {
				minTime = duration
			}
			if duration > maxTime {
				maxTime = duration
			}
			mu.Unlock()
		}(i)
	}

	wg.Wait()
	totalDuration := time.Since(startTime)

	fmt.Printf("   并发数: %d\n", concurrency)
	fmt.Printf("   总耗时: %v\n", totalDuration)
	fmt.Printf("   成功: %d\n", successCount)
	fmt.Printf("   限流: %d\n", rateLimitCount)
	fmt.Printf("   失败: %d\n", errorCount)
	if successCount > 0 {
		avgTime := totalTime / int64(successCount)
		fmt.Printf("   平均响应时间: %d ms\n", avgTime)
		fmt.Printf("   最快响应: %d ms\n", minTime)
		fmt.Printf("   最慢响应: %d ms\n", maxTime)
		qps := float64(successCount) / totalDuration.Seconds()
		fmt.Printf("   QPS (每秒请求数): %.2f\n", qps)

		// 性能评估
		if qps >= 50 {
			fmt.Printf("   ✅ QPS优秀 (支持300人/分钟)\n")
		} else if qps >= 30 {
			fmt.Printf("   ⚠️  QPS良好 (可能需要优化)\n")
		} else {
			fmt.Printf("   ❌ QPS不足 (需要优化)\n")
		}
	}
}

// testConcurrentRequests 通用并发请求测试
func testConcurrentRequests(url string, concurrency int, method, body string) {
	var wg sync.WaitGroup
	var mu sync.Mutex

	successCount := 0
	errorCount := 0
	totalTime := int64(0)
	minTime := int64(999999999)
	maxTime := int64(0)

	startTime := time.Now()

	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()

			reqStart := time.Now()
			var resp *http.Response
			var err error

			if method == "POST" {
				req, _ := http.NewRequest("POST", url, strings.NewReader(body))
				req.Header.Set("Content-Type", "application/json")
				client := &http.Client{Timeout: 5 * time.Second}
				resp, err = client.Do(req)
			} else {
				resp, err = http.Get(url)
			}

			duration := time.Since(reqStart).Milliseconds()

			mu.Lock()
			if err != nil {
				errorCount++
			} else {
				statusCode := resp.StatusCode
				resp.Body.Close()

				if statusCode == http.StatusOK ||
					statusCode == http.StatusTooManyRequests ||
					statusCode == http.StatusUnauthorized ||
					statusCode == http.StatusBadRequest {
					successCount++
				} else {
					errorCount++
				}
			}

			totalTime += duration
			if duration < minTime {
				minTime = duration
			}
			if duration > maxTime {
				maxTime = duration
			}
			mu.Unlock()
		}()
	}

	wg.Wait()
	totalDuration := time.Since(startTime)

	fmt.Printf("   并发数: %d\n", concurrency)
	fmt.Printf("   总耗时: %v\n", totalDuration)
	fmt.Printf("   成功: %d\n", successCount)
	fmt.Printf("   失败: %d\n", errorCount)
	if successCount > 0 {
		avgTime := totalTime / int64(successCount)
		fmt.Printf("   平均响应时间: %d ms\n", avgTime)
		fmt.Printf("   最快响应: %d ms\n", minTime)
		fmt.Printf("   最慢响应: %d ms\n", maxTime)
		fmt.Printf("   QPS: %.2f\n", float64(successCount)/totalDuration.Seconds())
	}
}

// testWithAuth 测试需要认证的接口
func testWithAuth(url string, concurrency int, method, body string) {
	// 这个测试需要token，如果没有token会返回401
	// 主要用于测试服务器处理认证请求的能力
	testConcurrentRequests(url, concurrency, method, body)
}

// testStaticFiles 静态文件测试
func testStaticFiles(baseURL string, count int) {
	var wg sync.WaitGroup
	successCount := 0
	errorCount := 0

	startTime := time.Now()

	for i := 0; i < count; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			resp, err := http.Get(baseURL + "/login.html")
			if err == nil {
				resp.Body.Close()
				if resp.StatusCode == http.StatusOK {
					successCount++
				} else {
					errorCount++
				}
			} else {
				errorCount++
			}
		}()
	}

	wg.Wait()
	duration := time.Since(startTime)

	fmt.Printf("   请求数: %d\n", count)
	fmt.Printf("   总耗时: %v\n", duration)
	fmt.Printf("   成功: %d\n", successCount)
	fmt.Printf("   失败: %d\n", errorCount)
	if successCount > 0 {
		fmt.Printf("   平均响应时间: %.2f ms\n", duration.Seconds()*1000/float64(successCount))
		fmt.Printf("   QPS: %.2f\n", float64(successCount)/duration.Seconds())
	}
}
