#!/bin/bash

# 部署到 ClawCloud 服务器

# 服务器配置
SERVER_HOST="deapps.huihys.ip-ddns.com"
SERVER_USER="root"
SERVER_PORT="22"
SERVER_PATH="/root/apps/party-system"
GIT_REPO="https://github.com/sheldore/partysta.git"
BRANCH="main"

echo "🚀 部署到 ClawCloud 服务器..."
echo "📋 部署信息："
echo "   服务器: $SERVER_HOST"
echo "   用户: $SERVER_USER"
echo "   路径: $SERVER_PATH"
echo "   仓库: $GIT_REPO"
echo "================================"

# 检查服务器连接
echo "📡 测试服务器连接..."
if ! ssh -p $SERVER_PORT -o ConnectTimeout=10 -o BatchMode=yes $SERVER_USER@$SERVER_HOST "echo '连接成功'" 2>/dev/null; then
    echo "❌ SSH 连接失败"
    echo ""
    echo "🌐 替代方案: 使用 WebSSH"
    echo "1. 访问: https://$SERVER_HOST:8888"
    echo "2. 用户名: club, 密码: 123456"
    echo "3. 执行以下命令:"
    echo ""
    echo "   sudo su -"
    echo "   git clone $GIT_REPO $SERVER_PATH"
    echo "   cd $SERVER_PATH"
    echo "   chmod +x *.sh"
    echo "   ./deploy.sh"
    echo ""
    exit 1
fi

echo "✅ 服务器连接正常"

# 在服务器上部署
echo "📥 在服务器上执行部署..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST << EOF
set -e

echo "🚀 开始服务器端部署..."

# 检查并创建部署目录
if [ -d "$SERVER_PATH" ]; then
    echo "📁 部署目录已存在，备份数据..."
    if [ -d "$SERVER_PATH/data" ]; then
        cp -r "$SERVER_PATH/data" "/root/backup-data-\$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        echo "✅ 数据已备份"
    fi
    
    echo "🔄 更新代码..."
    cd "$SERVER_PATH"
    git pull origin $BRANCH
else
    echo "📦 首次部署，克隆仓库..."
    mkdir -p \$(dirname "$SERVER_PATH")
    git clone "$GIT_REPO" "$SERVER_PATH"
    cd "$SERVER_PATH"
fi

echo "🔐 设置文件权限..."
chmod +x *.sh

echo "🚀 执行一键部署..."
./deploy.sh

echo "📊 检查服务状态..."
./service.sh status

echo "✅ 服务器端部署完成！"
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 部署成功完成！"
    echo ""
    echo "📍 访问地址:"
    echo "   主应用: https://$SERVER_HOST/partysta"
    echo "   健康检查: https://$SERVER_HOST/partysta/api/health"
    echo ""
    echo "🔧 管理命令:"
    echo "   查看状态: ssh $SERVER_USER@$SERVER_HOST 'cd $SERVER_PATH && ./service.sh status'"
    echo "   查看日志: ssh $SERVER_USER@$SERVER_HOST 'cd $SERVER_PATH && ./service.sh logs'"
    echo "   重启服务: ssh $SERVER_USER@$SERVER_HOST 'cd $SERVER_PATH && ./service.sh restart'"
    echo ""
    echo "🔐 默认密码:"
    echo "   管理员: admin123456"
    echo "   系统用户: club/123456"
else
    echo "❌ 部署失败"
    echo "💡 请检查服务器日志或使用 WebSSH 手动部署"
fi