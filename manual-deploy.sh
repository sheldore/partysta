#!/bin/bash

# 完全手动部署脚本
# 避免使用可能有问题的 supervisor 命令

echo "🚀 开始手动部署党员统计系统..."

# 1. 创建目录结构
echo "📁 创建目录结构..."
mkdir -p /root/apps/party-system/{public,data/{summary,details,logs},uploads}
mkdir -p /root/logs

# 2. 复制前端文件
echo "📄 设置前端文件..."
cp index.html public/ 2>/dev/null && echo "✅ index.html 已复制"
cp script-multiuser.js public/script.js 2>/dev/null && echo "✅ script.js 已复制"
cp styles.css public/ 2>/dev/null && echo "✅ styles.css 已复制"

# 3. 运行快速修复（安装依赖）
echo "📦 安装依赖..."
if [ -f "quick-fix.sh" ]; then
    chmod +x quick-fix.sh
    ./quick-fix.sh
else
    echo "⚠️ quick-fix.sh 不存在，跳过依赖安装"
fi

# 4. 配置 Nginx
echo "🌐 配置 Nginx..."
if [ -f "nginx-party.conf" ]; then
    # 备份原配置
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup 2>/dev/null
    
    # 应用新配置
    cp nginx-party.conf /etc/nginx/sites-available/default
    
    # 测试配置
    if nginx -t; then
        echo "✅ Nginx 配置测试通过"
        # 重启 nginx
        pkill -f nginx 2>/dev/null || true
        sleep 1
        nginx
        echo "✅ Nginx 已重启"
    else
        echo "❌ Nginx 配置错误"
        # 恢复备份
        cp /etc/nginx/sites-available/default.backup /etc/nginx/sites-available/default 2>/dev/null
    fi
fi

# 5. 直接启动应用（不使用 supervisor）
echo "🚀 启动应用..."

# 停止可能运行的旧进程
pkill -f backend-server.js 2>/dev/null || true
sleep 1

# 设置环境变量
export NODE_ENV=production
export PORT=3000
export PARTY_ADMIN_PASSWORD=admin123456
export BASE_PATH=/partysta

# 后台启动应用
nohup node backend-server.js > /root/logs/party-system.log 2> /root/logs/party-system-error.log &

# 等待启动
sleep 3

# 检查是否启动成功
if pgrep -f backend-server.js > /dev/null; then
    echo "✅ 应用启动成功！"
    echo "📋 进程ID: $(pgrep -f backend-server.js)"
else
    echo "❌ 应用启动失败"
    echo "📋 错误日志："
    tail -10 /root/logs/party-system-error.log 2>/dev/null || echo "无错误日志"
    exit 1
fi

# 6. 测试 HTTP 连接
echo "🧪 测试 HTTP 连接..."
sleep 2
if curl -s --connect-timeout 5 "http://localhost:3000/api/health" > /dev/null; then
    echo "✅ HTTP 连接测试通过"
else
    echo "⚠️ HTTP 连接测试失败，但应用可能仍在启动中"
fi

echo ""
echo "🎉 手动部署完成！"
echo ""
echo "📍 访问地址："
echo "   - 主应用: http://your-domain/"
echo "   - 健康检查: http://your-domain/api/health"
echo ""
echo "🔧 管理命令："
echo "   - 查看日志: tail -f /root/logs/party-system.log"
echo "   - 查看错误: tail -f /root/logs/party-system-error.log"
echo "   - 重启应用: pkill -f backend-server.js && nohup node backend-server.js > /root/logs/party-system.log 2>&1 &"
echo "   - 查看进程: ps aux | grep backend-server"
echo ""
echo "🔐 管理员密码: admin123456"
echo ""