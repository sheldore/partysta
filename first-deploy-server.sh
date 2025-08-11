#!/bin/bash

# 服务器首次部署脚本
# 在 ClawCloud 服务器上运行

echo "🚀 ClawCloud 服务器首次部署开始..."
echo "📅 部署时间: $(date)"
echo "🖥️ 服务器信息: $(uname -a)"
echo "================================"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 用户身份运行此脚本"
    exit 1
fi

# 更新系统
echo "📦 更新系统包..."
apt-get update

# 安装必要工具
echo "🔧 安装必要工具..."
apt-get install -y git curl wget

# 检查 Node.js
echo "📋 检查 Node.js..."
if command -v node >/dev/null 2>&1; then
    echo "✅ Node.js 已安装: $(node --version)"
else
    echo "❌ Node.js 未安装"
    exit 1
fi

# 克隆仓库
REPO_URL="https://github.com/sheldore/partysta.git"
DEPLOY_PATH="/root/apps/party-system"

if [ -d "$DEPLOY_PATH" ]; then
    echo "⚠️ 部署目录已存在，备份现有数据..."
    if [ -d "$DEPLOY_PATH/data" ]; then
        cp -r "$DEPLOY_PATH/data" "/root/backup-data-$(date +%Y%m%d_%H%M%S)"
        echo "✅ 数据已备份"
    fi
    rm -rf "$DEPLOY_PATH"
fi

echo "📦 克隆 GitHub 仓库..."
git clone "$REPO_URL" "$DEPLOY_PATH"

if [ $? -ne 0 ]; then
    echo "❌ 克隆仓库失败"
    exit 1
fi

echo "✅ 仓库克隆成功"

# 进入项目目录
cd "$DEPLOY_PATH"

# 设置权限
echo "🔐 设置文件权限..."
chmod +x *.sh
chmod +x deploy/*.sh
chmod +x scripts/linux/*.sh

# 执行部署
echo "🚀 执行应用部署..."
if [ -f "deploy/server-git-deploy.sh" ]; then
    ./deploy/server-git-deploy.sh
else
    echo "⚠️ 使用备用部署方案..."
    ./manual-deploy.sh
fi

echo ""
echo "🎉 首次部署完成！"
echo ""
echo "📍 访问地址:"
echo "   主应用: https://deapps.huihys.ip-ddns.com/partysta"
echo "   健康检查: https://deapps.huihys.ip-ddns.com/partysta/api/health"
echo ""
echo "🔧 管理命令:"
echo "   查看状态: ./service.sh status"
echo "   查看日志: ./service.sh logs"
echo "   重启服务: ./service.sh restart"
echo ""
echo "🔐 默认密码:"
echo "   管理员: admin123456"
echo "   系统用户: club/123456"
echo ""
echo "💡 后续更新: 在本地运行 ./deploy/git-deploy.sh"