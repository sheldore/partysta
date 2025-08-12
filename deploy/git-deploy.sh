#!/bin/bash

# Git 部署脚本 - 通过 Git 仓库同步代码

# 加载配置
if [ -f "../server-config.sh" ]; then
    source ../server-config.sh
elif [ -f "server-config.sh" ]; then
    source server-config.sh
else
    echo "❌ 请先配置 server-config.sh 文件"
    echo "💡 运行: cp server-config.example.sh server-config.sh"
    echo "💡 然后编辑: nano server-config.sh"
    exit 1
fi

# Git 仓库配置（从配置文件读取）
GIT_REPO="${GIT_REPO:-https://github.com/sheldore/partysta.git}"
BRANCH="${GIT_BRANCH:-main}"

echo "🚀 使用 Git 部署到 ClawCloud 服务器..."
echo "📋 配置信息："
echo "   Git 仓库: $GIT_REPO"
echo "   分支: $BRANCH"
echo "   服务器: $SERVER_HOST"
echo "   部署路径: $SERVER_PATH"
echo ""

# 本地提交代码（如果有更改）
echo "📝 检查本地更改..."
if [ -d "../.git" ]; then
    cd ..
elif [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 检查是否有未提交的更改
if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    read -p "请输入提交信息 (回车使用默认): " commit_message
    if [ -z "$commit_message" ]; then
        commit_message="Update party system - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    git commit -m "$commit_message"
    git push origin $BRANCH
    echo "✅ 代码已推送到 GitHub"
else
    echo "✅ 没有需要提交的更改"
fi

# 在服务器上拉取更新
echo "📥 在服务器上拉取更新..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST << EOF
cd $SERVER_PATH

# 如果是第一次部署，克隆仓库
if [ ! -d ".git" ]; then
    echo "📦 首次部署，克隆仓库..."
    cd /root/apps
    rm -rf party-system 2>/dev/null || true
    git clone $GIT_REPO party-system
    cd party-system
else
    echo "🔄 拉取最新代码..."
    git pull origin $BRANCH
fi

# 设置权限
chmod +x *.sh

# 执行一键部署
echo "🚀 执行一键部署..."
./deploy.sh

echo "✅ Git 部署完成！"
EOF

echo ""
echo "🎉 部署完成！"
echo "📍 访问地址: $APP_URL"
echo "🔧 管理命令: ssh $SERVER_USER@$SERVER_HOST 'cd $SERVER_PATH && ./service.sh status'"