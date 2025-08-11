#!/bin/bash

# 域名状态监控脚本

DOMAIN="deapps.huihys.ip-ddns.com"
TARGET="rrubgtslrkjg.eu-central-1.clawcloudrun.com"
CHECK_INTERVAL=60  # 检查间隔（秒）

echo "🔍 开始监控域名解析状态..."
echo "域名: $DOMAIN"
echo "目标: $TARGET"
echo "检查间隔: ${CHECK_INTERVAL}秒"
echo "按 Ctrl+C 停止监控"
echo "================================"

check_dns() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] 检查中..."
    
    # 检查 CNAME 解析
    local resolved=$(nslookup $DOMAIN 2>/dev/null | grep -A 1 "canonical name" | tail -n1 | awk '{print $4}' | sed 's/\.$//')
    
    if [ "$resolved" = "$TARGET" ]; then
        echo "✅ DNS 解析正常: $DOMAIN → $resolved"
        
        # 测试 HTTP 连接
        if curl -s --connect-timeout 5 http://$DOMAIN > /dev/null; then
            echo "✅ HTTP 连接正常"
            echo "🎉 域名已可正常访问！"
            return 0
        else
            echo "⚠️ DNS 解析正常，但 HTTP 连接失败"
        fi
    else
        echo "❌ DNS 解析未生效，当前解析: $resolved"
    fi
    
    return 1
}

# 持续监控
while true; do
    if check_dns; then
        echo ""
        echo "🎯 监控完成！域名已可正常使用。"
        echo "访问地址: http://$DOMAIN/partysta"
        break
    fi
    
    echo "⏳ 等待 ${CHECK_INTERVAL} 秒后重新检查..."
    echo ""
    sleep $CHECK_INTERVAL
done