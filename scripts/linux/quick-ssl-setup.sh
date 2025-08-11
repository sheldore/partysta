#!/bin/bash

# 快速 SSL 设置脚本
# 优先使用自签名证书，避免 Certbot 问题

DOMAIN="deapps.huihys.ip-ddns.com"
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"

echo "🚀 快速 SSL 设置..."
echo "域名: $DOMAIN"
echo "================================"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 用户身份运行此脚本"
    exit 1
fi

# 创建证书目录
mkdir -p $CERT_DIR $KEY_DIR

echo "🔐 创建自签名 SSL 证书..."

# 生成私钥和证书（一步完成）
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $KEY_DIR/$DOMAIN.key \
    -out $CERT_DIR/$DOMAIN.crt \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=Party System/CN=$DOMAIN"

# 设置权限
chmod 600 $KEY_DIR/$DOMAIN.key
chmod 644 $CERT_DIR/$DOMAIN.crt

echo "✅ SSL 证书创建完成"

# 备份当前 Nginx 配置
echo "💾 备份当前 Nginx 配置..."
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)

# 创建新的 Nginx 配置
echo "⚙️ 配置 Nginx SSL..."
cat > /etc/nginx/sites-available/default << EOF
# 上游服务器配置
upstream party_backend {
    server 127.0.0.1:3000;
}

# HTTP 服务器 - 同时支持 HTTP 和重定向到 HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    
    # 党员统计系统 - HTTP 访问
    location /partysta {
        proxy_pass http://party_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 文件上传支持
        client_max_body_size 50M;
    }
    
    # 根路径重定向到党员统计系统
    location = / {
        return 301 http://\$server_name/partysta;
    }
    
    # 提示 HTTPS 可用
    location /ssl-info {
        return 200 'HTTPS is available at https://$DOMAIN/partysta';
        add_header Content-Type text/plain;
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
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # 文件上传大小限制
    client_max_body_size 50M;
    
    # 党员统计系统 - HTTPS 访问
    location /partysta {
        proxy_pass http://party_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 根路径重定向到党员统计系统
    location = / {
        return 301 https://\$server_name/partysta;
    }
    
    # 静态文件缓存
    location ~* ^/partysta/.*\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://party_backend;
        expires 1y;
        add_header Cache-Control "public, immutable";
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
    
    # 等待服务启动
    sleep 3
    
    # 测试连接
    echo "🧪 测试连接..."
    echo "HTTP 测试:"
    curl -I http://$DOMAIN/partysta --connect-timeout 5 2>/dev/null | head -1
    
    echo "HTTPS 测试:"
    curl -I -k https://$DOMAIN/partysta --connect-timeout 5 2>/dev/null | head -1
    
    echo ""
    echo "🎉 SSL 配置完成！"
    echo ""
    echo "📍 访问地址："
    echo "  HTTP:  http://$DOMAIN/partysta"
    echo "  HTTPS: https://$DOMAIN/partysta"
    echo ""
    echo "⚠️ 重要提示："
    echo "1. 使用的是自签名证书，浏览器会显示安全警告"
    echo "2. 点击浏览器的'高级' -> '继续访问'即可"
    echo "3. HTTP 和 HTTPS 都可以正常访问"
    echo "4. 如需正式证书，请联系域名提供商或使用其他 SSL 服务"
    
    # 显示证书信息
    echo ""
    echo "📜 证书信息："
    openssl x509 -in $CERT_DIR/$DOMAIN.crt -text -noout | grep -E "(Subject:|Not Before|Not After)"
    
else
    echo "❌ Nginx 配置测试失败"
    echo "🔄 恢复备份配置..."
    cp /etc/nginx/sites-available/default.backup.* /etc/nginx/sites-available/default 2>/dev/null
    exit 1
fi