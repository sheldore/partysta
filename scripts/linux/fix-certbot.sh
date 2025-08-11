#!/bin/bash

# Certbot 修复脚本
# 解决 OpenSSL 兼容性问题

DOMAIN="deapps.huihys.ip-ddns.com"

echo "🔧 修复 Certbot SSL 证书问题..."
echo "域名: $DOMAIN"
echo "================================"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 用户身份运行此脚本"
    exit 1
fi

# 方案1: 更新系统和重新安装 Certbot
echo "📦 方案1: 更新系统和重新安装 Certbot..."
apt-get update
apt-get upgrade -y

# 卸载旧版本
apt-get remove -y certbot python3-certbot-nginx

# 使用 snap 安装最新版本的 Certbot
echo "📦 使用 snap 安装最新版 Certbot..."
if ! command -v snap >/dev/null 2>&1; then
    apt-get install -y snapd
    systemctl enable snapd
    systemctl start snapd
    # 等待 snapd 启动
    sleep 5
fi

# 安装 Certbot
snap install core; snap refresh core
snap install --classic certbot

# 创建符号链接
ln -sf /snap/bin/certbot /usr/bin/certbot

# 验证安装
echo "🔍 验证 Certbot 安装..."
if /snap/bin/certbot --version; then
    echo "✅ Certbot 安装成功"
else
    echo "❌ Certbot 安装失败，尝试方案2"
    exit 1
fi

# 获取 SSL 证书
echo "🔐 获取 SSL 证书..."
/snap/bin/certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

if [ $? -eq 0 ]; then
    echo "✅ SSL 证书获取成功！"
    
    # 测试 HTTPS 连接
    echo "🧪 测试 HTTPS 连接..."
    sleep 5
    if curl -s --connect-timeout 10 https://$DOMAIN > /dev/null; then
        echo "✅ HTTPS 连接测试成功！"
    else
        echo "⚠️ HTTPS 连接测试失败，但证书可能已安装"
    fi
    
    # 设置自动续期
    echo "🔄 设置证书自动续期..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /snap/bin/certbot renew --quiet") | crontab -
    
    echo ""
    echo "🎉 SSL 配置完成！"
    echo "现在可以通过以下地址访问："
    echo "  HTTP:  http://$DOMAIN/partysta"
    echo "  HTTPS: https://$DOMAIN/partysta"
    
else
    echo "❌ SSL 证书获取仍然失败，使用自签名证书作为备选方案"
    echo "🔄 切换到自签名证书方案..."
    
    # 调用自签名证书脚本
    if [ -f "./create-self-signed-cert.sh" ]; then
        chmod +x create-self-signed-cert.sh
        ./create-self-signed-cert.sh
    else
        echo "❌ 找不到自签名证书脚本"
        exit 1
    fi
fi