#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
二维码生成脚本
使用前需要安装: pip3 install --break-system-packages qrcode[pil]
或者使用 generate_qrcode.html 网页版工具（推荐，无需安装）
"""

import qrcode
import sys
import socket

def get_local_ip():
    """获取本机局域网IP"""
    try:
        # 连接到一个远程地址（不会实际发送数据）
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "localhost"

def generate_qrcode(url, filename="qrcode.png"):
    """生成二维码"""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(filename)
    print(f"✅ 二维码已生成: {filename}")
    print(f"📱 访问地址: {url}")

if __name__ == "__main__":
    # 默认使用本地IP和8080端口
    local_ip = get_local_ip()
    default_url = f"http://{local_ip}:8080/index.html"
    
    if len(sys.argv) > 1:
        url = sys.argv[1]
    else:
        url = default_url
        print(f"💡 未指定URL，使用默认地址: {url}")
        print(f"💡 如需自定义，请运行: python generate_qrcode.py <your-url>")
    
    generate_qrcode(url)

