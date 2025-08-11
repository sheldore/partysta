#!/bin/bash

# 创建自签名 SSL 证书脚本
# 仅用于测试，生产环境请使用 Let's Encrypt

DOMAIN="deapps.huihys.ip-ddns.com"
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"

echo "🔐 创建自签名 SSL 证书..."
echo "域名: $DOMAIN"
echo "⚠️ 注意：自签名证书会显示安全警告，仅用于测试"
echo "================================"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 用户身份运行此脚本"
    exit 1
fi

# 创建证书目录
mkdir -p $CERT_DIR $KEY_DIR

# 生成私钥
echo "🔑 生成私钥..."
openssl genrsa -out $KEY_DIR/$DOMAIN.key 2048

# 生成证书签名请求
echo "📝 生成证书签名请求..."
openssl req -new -key $KEY_DIR/$DOMAIN.key -out /tmp/$DOMAIN.csr -subj "/C=CN/ST=Beijing/L=Beijing/O=Party System/CN=$DOMAIN"

# 生成自签名证书
echo "📜 生成自签名证书..."
openssl x509 -req -days 365 -in /tmp/$DOMAIN.csr -signkey $KEY_DIR/$DOMAIN.key -out $CERT_DIR/$DOMAIN.crt

# 设置权限
chmod 600 $KEY_DIR/$DOMAIN.key
chmod 644 $CERT_DIR/$DOMAIN.crt

# 创建 Nginx 配置
echo "⚙️ 创建 Nginx SSL 配置..."
cat > /etc/nginx/sites-available/default << EOF
# 上游服务器配置
upstream party_backend {
    server 127.0.0.1:3000;
}

# HTTP 服务器
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS 服务器
server {
    listen 443 ssl;
    server_name $DOMAIN;
    
    # SSL 证书配置
    ssl_certificate $CERT_DIR/$DOMAIN.crt;
    ssl_certificate_key $KEY_DIR/$DOMAIN.key;
    
    # SSL 基本配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    
    # 文件上传大小限制
    client_max_body_size 50M;
    
    # 党员统计系统
    location /partysta {
        proxy_pass http://party_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 根路径重定向
    location = / {
        return 301 https://\$server_name/partysta;
    }
}
EOF

# 测试 Nginx 配置
echo "🧪 测试 Nginx 配置..."
if nginx -t; then
    echo "✅ Nginx 配置测试通过"
    
    # 重启 Nginx
    systemctl reload nginx
    echo "✅ Nginx 已重新加载"
    
    # 清理临时文件
    rm -f /tmp/$DOMAIN.csr
    
    echo ""
    echo "🎉 自签名证书配置完成！"
    echo ""
    echo "📍 访问地址："
    echo "  HTTP:  http://$DOMAIN/partysta"
    echo "  HTTPS: https://$DOMAIN/partysta"
    echo ""
    echo "⚠️ 重要提示："
    echo "1. 浏览器会显示安全警告，点击'高级' -> '继续访问'"
    echo "2. 这是自签名证书，仅用于测试"
    echo "3. 生产环境请使用 Let's Encrypt 证书"
    echo ""
    echo "🔧 如需 Let's Encrypt 证书，请运行："
    echo "   ./setup-ssl.sh"
    
else
    echo "❌ Nginx 配置测试失败"
    exit 1
fi