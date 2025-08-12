#!/bin/bash

# 党员统计系统一键部署脚本
# 适用于 ClawCloud 环境

echo "🚀 党员统计系统一键部署开始..."
echo "📅 部署时间: $(date)"
echo "================================"

# 检查环境
echo "📋 检查运行环境..."
node --version || { echo "❌ Node.js 未安装"; exit 1; }
npm --version || { echo "❌ npm 未安装"; exit 1; }

# 创建目录结构
echo "📁 创建目录结构..."
mkdir -p public data/{summary,details,logs} uploads

# 复制核心文件
echo "📄 复制应用文件..."
cp core/index.html public/
cp core/script-multiuser.js public/script.js
cp core/styles.css public/
cp core/backend-server.js ./
cp core/package.json ./

# 安装依赖
echo "📦 安装依赖..."
export NODE_OPTIONS="--max-old-space-size=512"
npm install --production --no-optional --no-audit --no-fund

# 配置 Supervisor
echo "⚙️ 配置进程管理..."
if [ -f "supervisor-party.conf" ]; then
    cp supervisor-party.conf /etc/supervisor/conf.d/party-system.conf
    supervisorctl reread && supervisorctl update
fi

# 配置 Nginx
echo "🌐 配置 Nginx..."
if [ -f "nginx-party.conf" ]; then
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    cp nginx-party.conf /etc/nginx/sites-available/default
    nginx -t && supervisorctl restart nginx
fi

# 启动应用
echo "🚀 启动应用..."
supervisorctl start party-system

# 等待启动
sleep 5

# 检查状态
echo "📊 检查服务状态..."
supervisorctl status party-system

echo ""
echo "🎉 部署完成！"
echo "📍 访问地址: https://deapps.huihys.ip-ddns.com/partysta"
echo "🔐 管理员密码: admin123456"
echo ""
echo "🔧 管理命令:"
echo "   查看日志: tail -f /root/logs/party-system.log"
echo "   重启应用: supervisorctl restart party-system"
echo "   查看状态: supervisorctl status"