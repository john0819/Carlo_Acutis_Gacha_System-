# 🌐 公网访问配置指南

要让其他人也能扫描二维码访问你的H5页面，需要使用**内网穿透**服务。以下是几种方案：

## 方案一：ngrok（推荐，最简单）⭐

### 优点
- ✅ 免费版可用（有限制）
- ✅ 设置简单，几分钟搞定
- ✅ 自动提供HTTPS
- ✅ 适合测试和小规模使用

### 使用步骤

#### 1. 安装 ngrok

**macOS:**
```bash
brew install ngrok/ngrok/ngrok
```

**或手动安装:**
1. 访问 https://ngrok.com/download
2. 下载 macOS 版本
3. 解压并放到 `/usr/local/bin/` 或添加到 PATH

#### 2. 注册并配置

1. 访问 https://dashboard.ngrok.com/signup 注册账号（免费）
2. 登录后获取你的 authtoken
3. 运行配置命令：
```bash
ngrok config add-authtoken YOUR_AUTHTOKEN
```

#### 3. 启动服务

**方法一：使用脚本（推荐）**
```bash
chmod +x start_ngrok.sh
./start_ngrok.sh
```

**方法二：手动启动**
```bash
# 在第一个终端启动服务器
go run main.go

# 在第二个终端启动 ngrok
ngrok http 8080
```

#### 4. 获取公网地址

ngrok 启动后会显示类似信息：
```
Forwarding   https://xxxx-xxx-xxx-xxx.ngrok-free.app -> http://localhost:8080
```

**复制这个 https 地址**（例如：`https://abc123.ngrok-free.app`）

#### 5. 生成二维码

1. 打开 `generate_qrcode.html`
2. 输入地址：`https://你的ngrok地址/index.html`
3. 生成二维码
4. 现在任何人都可以扫描访问了！

---

## 方案二：Cloudflare Tunnel（免费，稳定）⭐

### 优点
- ✅ 完全免费
- ✅ 无流量限制
- ✅ 速度较快
- ✅ 无需注册账号

### 使用步骤

#### 1. 安装 cloudflared

```bash
brew install cloudflared
```

#### 2. 启动隧道

```bash
cloudflared tunnel --url http://localhost:8080
```

#### 3. 获取公网地址

会显示类似：
```
+--------------------------------------------------------------------------------------------+
|  Your quick Tunnel has been created! Visit it at (it may take some time to be reachable): |
|  https://xxxx-xxx-xxx.trycloudflare.com                                                    |
+--------------------------------------------------------------------------------------------+
```

使用这个地址生成二维码即可。

---

## 方案三：localtunnel（最简单，无需注册）

### 优点
- ✅ 无需注册
- ✅ 一条命令搞定
- ⚠️ 免费版地址随机

### 使用步骤

#### 1. 安装

```bash
npm install -g localtunnel
```

#### 2. 启动

```bash
lt --port 8080
```

#### 3. 获取地址

会显示类似：
```
your url is: https://xxx.loca.lt
```

使用这个地址生成二维码。

---

## 方案四：frp（适合生产环境）

### 优点
- ✅ 完全自主控制
- ✅ 适合长期使用
- ⚠️ 需要有自己的服务器

### 使用步骤

1. 需要一台有公网IP的服务器
2. 在服务器上运行 frp 服务端
3. 在本地运行 frp 客户端
4. 配置端口映射

详细配置请参考：https://github.com/fatedier/frp

---

## 📱 二维码生成

配置好公网地址后：

1. 打开 `generate_qrcode.html`
2. 输入完整的公网地址（例如：`https://abc123.ngrok-free.app/index.html`）
3. 生成二维码
4. 分享给任何人扫描即可访问

---

## 🔒 安全提示

1. **免费服务限制：**
   - ngrok 免费版：连接数有限，每次重启地址会变
   - Cloudflare Tunnel：完全免费，但地址每次启动会变
   - localtunnel：完全免费，但地址随机

2. **生产环境建议：**
   - 使用固定域名的付费服务
   - 或使用自己的服务器 + frp
   - 考虑添加访问密码保护

3. **图片大小：**
   - 公网访问时，建议图片控制在 1-2MB 以内
   - 大图片会影响加载速度

---

## 🚀 快速开始（推荐流程）

1. **安装 ngrok:**
   ```bash
   brew install ngrok/ngrok/ngrok
   ```

2. **注册并配置:**
   - 访问 https://dashboard.ngrok.com/signup
   - 获取 authtoken
   - 运行: `ngrok config add-authtoken YOUR_TOKEN`

3. **启动服务器:**
   ```bash
   go run main.go
   ```

4. **启动 ngrok（新终端）:**
   ```bash
   ./start_ngrok.sh
   # 或直接: ngrok http 8080
   ```

5. **生成二维码:**
   - 复制 ngrok 提供的 https 地址
   - 打开 `generate_qrcode.html`
   - 输入地址并生成二维码

6. **分享二维码**，现在任何人都可以扫描访问了！

---

## ❓ 常见问题

**Q: ngrok 地址每次重启都会变吗？**
A: 免费版是的。付费版可以绑定固定域名。

**Q: 哪个方案最快？**
A: Cloudflare Tunnel 通常速度较快，且完全免费。

**Q: 有流量限制吗？**
A: ngrok 免费版有连接数限制。Cloudflare Tunnel 无限制。

**Q: 可以自定义域名吗？**
A: ngrok 付费版可以。frp 完全自主控制。

