#!/bin/bash

# 地址连通性检查脚本

# 加载地址配置
if [ -f "config/addresses.sh" ]; then
    source config/addresses.sh
else
    echo "❌ 找不到地址配置文件"
    exit 1
fi

echo "🔍 检查所有服务地址连通性..."
echo "================================"

# 检查主应用
echo "📱 检查主应用..."
if curl -s --connect-timeout 10 "$APP_URL" > /dev/null; then
    echo "✅ 主应用可访问: $APP_URL"
else
    echo "❌ 主应用不可访问: $APP_URL"
fi

# 检查健康检查端点
echo "🏥 检查健康检查..."
if curl -s --connect-timeout 10 "$HEALTH_URL" > /dev/null; then
    echo "✅ 健康检查可访问: $HEALTH_URL"
else
    echo "❌ 健康检查不可访问: $HEALTH_URL"
fi

# 检查 WebSSH
echo "🌐 检查 WebSSH..."
if curl -s --connect-timeout 10 "$WEBSSH_URL" > /dev/null; then
    echo "✅ WebSSH 可访问: $WEBSSH_URL"
else
    echo "❌ WebSSH 不可访问: $WEBSSH_URL"
fi

# 检查文件管理
echo "📁 检查文件管理..."
if curl -s --connect-timeout 10 "$DUFS_URL" > /dev/null; then
    echo "✅ 文件管理可访问: $DUFS_URL"
else
    echo "❌ 文件管理不可访问: $DUFS_URL"
fi

# 检查 SSH 连接
echo "🔐 检查 SSH 连接..."
if ssh -p $SSH_PORT -o ConnectTimeout=10 -o BatchMode=yes $SSH_USER@$SSH_HOST "echo 'SSH连接成功'" 2>/dev/null; then
    echo "✅ SSH 连接正常: $SSH_USER@$SSH_HOST:$SSH_PORT"
else
    echo "❌ SSH 连接失败: $SSH_USER@$SSH_HOST:$SSH_PORT"
fi

echo ""
echo "📋 所有服务地址："
show_addresses

echo ""
echo "💡 如果某些服务不可访问，请检查："
echo "1. 域名解析是否正确"
echo "2. 服务是否正在运行"
echo "3. 防火墙设置"
echo "4. SSL 证书配置"