# H5随机图片展示项目

通过扫描二维码访问H5页面，随机展示图片集中的图片。

## 功能特点

- 📱 响应式设计，适配手机和桌面端
- 🎲 每次访问随机展示不同图片
- 🎨 现代化的UI设计
- 🚀 轻量级Go服务器

## 快速开始

### 1. 准备图片

将你的图片放入 `images/` 目录，命名为 `image1.jpg`, `image2.jpg`, `image3.jpg` 等。

或者修改 `images/list.json` 文件，添加你的图片路径：

```json
{
  "images": [
    "/images/your-image1.jpg",
    "/images/your-image2.jpg",
    "/images/your-image3.jpg"
  ]
}
```

### 2. 运行服务器

```bash
go run main.go
```

服务器将在 `http://localhost:8080` 启动。

### 3. 生成二维码

#### 方法一：使用在线工具
1. 访问 https://cli.im/ 或 https://www.qrcode-monkey.com/
2. 输入你的地址：`http://your-ip:8080/index.html`
   - 如果手机和电脑在同一网络，使用电脑的局域网IP（如：`http://192.168.1.100:8080/index.html`）
   - 如果需要在公网访问，需要使用内网穿透工具（如ngrok、frp等）

#### 方法二：使用命令行工具（需要安装qrencode）
```bash
# macOS
brew install qrencode

# 生成二维码
qrencode -o qrcode.png "http://your-ip:8080/index.html"
```

#### 方法三：使用Python脚本（需要安装qrcode库）
```bash
pip install qrcode[pil]
python generate_qrcode.py
```

### 4. 测试

1. 用手机扫描生成的二维码
2. 手机浏览器会自动打开H5页面
3. 页面会随机显示一张图片
4. 点击"换一张"按钮可以切换图片

## 项目结构

```
h5Project/
├── main.go              # Go服务器主文件
├── go.mod              # Go模块文件
├── static/             # 静态文件目录
│   └── index.html      # H5页面
├── images/             # 图片目录
│   ├── list.json       # 图片列表配置
│   └── image*.jpg      # 图片文件
└── README.md           # 说明文档
```

## 部署到公网

### 使用ngrok（推荐用于测试）

1. 下载ngrok：https://ngrok.com/
2. 注册并获取authtoken
3. 运行：
```bash
ngrok http 8080
```
4. 使用ngrok提供的公网地址生成二维码

### 使用frp（推荐用于生产环境）

配置frp客户端和服务器，将本地8080端口映射到公网。

## 注意事项

- 确保防火墙允许8080端口访问
- 如果使用局域网IP，确保手机和电脑在同一网络
- 图片文件建议使用jpg或png格式
- 图片大小建议控制在2MB以内，以确保加载速度

## 自定义配置

### 修改端口

编辑 `main.go`，修改 `port` 变量：
```go
port := ":8080"  // 改为你想要的端口
```

### 修改图片路径

编辑 `images/list.json`，添加或修改图片路径。

### 修改页面样式

编辑 `static/index.html`，修改CSS样式部分。

