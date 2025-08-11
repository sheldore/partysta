#!/bin/bash

# 党员统计应用启动脚本
# 在 ClawCloud 容器中使用

cd /root/apps/party-system

echo "🚀 启动党员统计管理系统..."
echo "📅 启动时间: $(date)"
echo "📁 工作目录: $(pwd)"

# 检查必要文件
if [ ! -f "backend-server.js" ]; then
    echo "❌ backend-server.js 不存在"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "❌ package.json 不存在"
    exit 1
fi

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    exit 1
fi

# 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install --production
fi

# 创建必要目录
mkdir -p data/{summary,details,logs} uploads public

# 设置环境变量
export NODE_ENV=production
export PORT=${PORT:-3000}
export PARTY_ADMIN_PASSWORD=${PARTY_ADMIN_PASSWORD:-admin123456}

echo "🔧 环境配置:"
echo "   NODE_ENV: $NODE_ENV"
echo "   PORT: $PORT"
echo "   管理员密码: $PARTY_ADMIN_PASSWORD"

# 启动应用
echo "🚀 启动 Node.js 应用..."
exec node backend-server.js