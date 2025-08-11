#!/bin/bash

# 服务器端 Git 部署脚本
# 在 ClawCloud 服务器上运行

GIT_REPO="https://github.com/sheldore/partysta.git"
BRANCH="main"
DEPLOY_PATH="/root/apps/party-system"
BACKUP_PATH="/root/backups/party-system"

echo "🚀 服务器端 Git 部署开始..."
echo "📋 配置信息："
echo "   Git 仓库: $GIT_REPO"
echo "   分支: $BRANCH"
echo "   部署路径: $DEPLOY_PATH"
echo "================================"

# 创建备份目录
mkdir -p $BACKUP_PATH

# 如果是首次部署
if [ ! -d "$DEPLOY_PATH" ]; then
    echo "📦 首次部署，克隆仓库..."
    mkdir -p $(dirname $DEPLOY_PATH)
    git clone $GIT_REPO $DEPLOY_PATH
    cd $DEPLOY_PATH
else
    echo "🔄 更新现有部署..."
    cd $DEPLOY_PATH
    
    # 备份当前数据
    if [ -d "data" ]; then
        echo "💾 备份数据..."
        cp -r data $BACKUP_PATH/data-$(date +%Y%m%d_%H%M%S)
    fi
    
    # 拉取最新代码
    git fetch origin
    git reset --hard origin/$BRANCH
fi

echo "✅ 代码更新完成"

# 设置权限
echo "🔐 设置文件权限..."
chmod +x *.sh
chmod +x scripts/linux/*.sh
chmod +x deploy/*.sh

# 恢复数据（如果有备份）
if [ -d "$BACKUP_PATH" ]; then
    LATEST_BACKUP=$(ls -t $BACKUP_PATH/data-* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ] && [ ! -d "data" ]; then
        echo "🔄 恢复数据备份..."
        cp -r $LATEST_BACKUP data
    fi
fi

# 执行部署
echo "🚀 执行应用部署..."
if [ -f "manual-deploy.sh" ]; then
    ./manual-deploy.sh
else
    echo "❌ 找不到 manual-deploy.sh 脚本"
    exit 1
fi

echo ""
echo "🎉 Git 部署完成！"
echo "📍 访问地址: https://deapps.huihys.ip-ddns.com/partysta"
echo "🔧 管理命令:"
echo "   查看状态: ./service.sh status"
echo "   查看日志: ./service.sh logs"
echo "   重启服务: ./service.sh restart"