#!/bin/bash

# SSL 证书配置脚本
# 使用 Let's Encrypt 免费证书

DOMAIN="deapps.huihys.ip-ddns.com"

echo "🔐 开始配置 SSL 证书..."
echo "域名: $DOMAIN"
echo "================================"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 用户身份运行此脚本"
    exit 1
fi

# 检查域名解析
echo "📡 检查域名解析..."
if ! nslookup $DOMAIN > /dev/null 2>&1; then
    echo "❌ 域名解析失败，请确保域名已正确解析到此服务器"
    exit 1
fi

echo "✅ 域名解析正常"

# 安装 Certbot
echo "📦 安装 Certbot..."
if command -v apt-get >/dev/null 2>&1; then
    # Ubuntu/Debian
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL
    yum install -y certbot python3-certbot-nginx
else
    echo "❌ 不支持的操作系统"
    exit 1
fi

# 检查 Nginx 配置
echo "🔍 检查 Nginx 配置..."
if ! nginx -t; then
    echo "❌ Nginx 配置有误，请先修复配置"
    exit 1
fi

# 获取 SSL 证书
echo "🔐 获取 SSL 证书..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

if [ $? -eq 0 ]; then
    echo "✅ SSL 证书获取成功！"
    
    # 测试 HTTPS 连接
    echo "🧪 测试 HTTPS 连接..."
    if curl -s --connect-timeout 10 https://$DOMAIN > /dev/null; then
        echo "✅ HTTPS 连接测试成功！"
    else
        echo "⚠️ HTTPS 连接测试失败，但证书可能已安装"
    fi
    
    # 设置自动续期
    echo "🔄 设置证书自动续期..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    echo ""
    echo "🎉 SSL 配置完成！"
    echo "现在可以通过以下地址访问："
    echo "  HTTP:  http://$DOMAIN/partysta"
    echo "  HTTPS: https://$DOMAIN/partysta"
    
else
    echo "❌ SSL 证书获取失败"
    echo "可能的原因："
    echo "1. 域名未正确解析到此服务器"
    echo "2. 80 端口被防火墙阻止"
    echo "3. Nginx 配置问题"
    
    echo ""
    echo "🔧 手动排查步骤："
    echo "1. 检查域名解析: nslookup $DOMAIN"
    echo "2. 检查端口开放: netstat -tlnp | grep :80"
    echo "3. 检查防火墙: ufw status"
    echo "4. 检查 Nginx: nginx -t && systemctl status nginx"
fi