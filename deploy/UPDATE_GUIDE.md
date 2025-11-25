# 📋 服务端更新指南

## 🆕 首次配置HTTPS（只需要执行一次）

如果你还没有配置HTTPS，需要先执行一次：

```bash
cd /root/Carlo_Acutis_Gacha_System-

# 1. 配置HTTPS（选择一种方式）

# 方式A：使用IP地址（自签名证书，快速测试）
./deploy/setup_https.sh ip

# 方式B：使用域名（Let's Encrypt免费证书，推荐）
# 先确保域名已解析到服务器IP
./deploy/setup_https.sh domain
# 然后输入你的域名

# 2. 配置完成后，访问地址会变成 https://47.111.226.140
```

---

## 🔄 日常更新流程（每次代码更新后）

### 步骤1：拉取最新代码
```bash
cd /root/Carlo_Acutis_Gacha_System-
git pull
```

### 步骤2：执行部署脚本
```bash
./deploy/deploy.sh
```

**这个脚本会自动完成：**
- ✅ 编译Go程序
- ✅ 复制文件到 `/opt/h5project`
- ✅ 配置systemd服务
- ✅ 配置Nginx（如果已配置HTTPS，会保持HTTPS配置）
- ✅ 重启服务

### 步骤3：验证服务
```bash
# 检查服务状态
sudo systemctl status h5project

# 检查HTTPS是否正常（如果已配置）
curl -I https://47.111.226.140
```

---

## 📱 生成二维码（如果需要）

配置HTTPS后，访问地址变成 `https://47.111.226.140/login.html`

生成二维码的方法：
1. 使用在线工具：https://cli.im/ 或 https://www.qrcode-monkey.com/
2. 输入地址：`https://47.111.226.140/login.html`
3. 下载二维码图片

---

## ⚠️ 注意事项

1. **HTTPS配置只需要执行一次**，之后每次更新只需要执行 `deploy.sh` 即可
2. **如果使用自签名证书**，浏览器会显示安全警告，这是正常的，点击"高级" → "继续访问"即可
3. **如果使用域名+Let's Encrypt**，证书会自动续期，无需手动操作
4. **Nginx配置不会覆盖**：`deploy.sh` 会复制 `nginx.conf`，但如果已经配置了HTTPS，需要手动确保使用 `nginx-https.conf`

---

## 🔧 故障排查

### 如果HTTPS不工作：
```bash
# 检查Nginx配置
sudo nginx -t

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/h5project_error.log

# 检查443端口是否开放
sudo netstat -tlnp | grep 443
```

### 如果服务启动失败：
```bash
# 查看服务日志
sudo journalctl -u h5project -n 50

# 重启服务
sudo systemctl restart h5project
```

