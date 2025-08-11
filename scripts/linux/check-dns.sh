#!/bin/bash

# DNS 解析检查脚本

DOMAIN="deapps.huihys.ip-ddns.com"
TARGET="rrubgtslrkjg.eu-central-1.clawcloudrun.com"

echo "🔍 检查域名 DNS 解析状态..."
echo "域名: $DOMAIN"
echo "目标: $TARGET"
echo "================================"

# 检查 CNAME 记录
echo "📋 CNAME 记录查询:"
nslookup $DOMAIN

echo ""
echo "📋 使用不同 DNS 服务器查询:"

# 使用 Google DNS
echo "🌐 Google DNS (8.8.8.8):"
nslookup $DOMAIN 8.8.8.8

echo ""
# 使用 Cloudflare DNS  
echo "🌐 Cloudflare DNS (1.1.1.1):"
nslookup $DOMAIN 1.1.1.1

echo ""
echo "📋 Ping 测试:"
ping -c 4 $DOMAIN

echo ""
echo "📋 HTTP 连接测试:"
curl -I http://$DOMAIN --connect-timeout 10

echo ""
echo "💡 如果解析失败，请等待 DNS 传播完成（通常需要几分钟到几小时）"