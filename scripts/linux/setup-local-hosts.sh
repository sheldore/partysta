#!/bin/bash

# 本地 hosts 文件配置脚本
# 用于在 DNS 解析完成前临时访问域名

DOMAIN="deapps.huihys.ip-ddns.com"
TARGET="rrubgtslrkjg.eu-central-1.clawcloudrun.com"

echo "🔧 配置本地 hosts 文件..."

# 获取目标服务器的 IP 地址
echo "📡 解析目标服务器 IP..."
TARGET_IP=$(nslookup $TARGET | grep -A 1 "Name:" | tail -n1 | awk '{print $2}')

if [ -z "$TARGET_IP" ]; then
    echo "❌ 无法解析目标服务器 IP"
    exit 1
fi

echo "✅ 目标服务器 IP: $TARGET_IP"

# 检查操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    # Linux/macOS
    HOSTS_FILE="/etc/hosts"
    echo "🐧 检测到 Linux/macOS 系统"
    
    # 检查是否已存在记录
    if grep -q "$DOMAIN" $HOSTS_FILE; then
        echo "⚠️ hosts 文件中已存在该域名记录"
        echo "当前记录:"
        grep "$DOMAIN" $HOSTS_FILE
    else
        echo "📝 添加记录到 hosts 文件..."
        echo "$TARGET_IP $DOMAIN" | sudo tee -a $HOSTS_FILE
        echo "✅ 已添加: $TARGET_IP $DOMAIN"
    fi
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    HOSTS_FILE="C:\\Windows\\System32\\drivers\\etc\\hosts"
    echo "🪟 检测到 Windows 系统"
    echo "请以管理员身份运行以下命令:"
    echo "echo $TARGET_IP $DOMAIN >> $HOSTS_FILE"
fi

echo ""
echo "🧪 测试本地解析:"
ping -c 2 $DOMAIN

echo ""
echo "💡 提示:"
echo "1. 现在可以通过 http://$DOMAIN 访问应用"
echo "2. DNS 解析生效后，可以删除 hosts 文件中的记录"
echo "3. 删除命令: sudo sed -i '/$DOMAIN/d' $HOSTS_FILE"