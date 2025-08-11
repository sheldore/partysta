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

# 检查是否在 Git 仓库中
if [ ! -d "../.git" ] && [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 Git 仓库"
    echo "💡 请先初始化 Git 仓库："
    echo "   git init"
    echo "   git remote add origin $GIT_REPO"
    exit 1
fi

# 本地提交代码
echo "📝 提交本地更改..."
if [ -d "../.git" ]; then
    cd ..
fi

# 检查是否有未提交的更改
if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    read -p "请输入提交信息: " commit_message
    if [ -z "$commit_message" ]; then
        commit_message="Update party system - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    git commit -m "$commit_message"
    echo "✅ 本地提交完成"
else
    echo "✅ 没有需要提交的更改"
fi

# 推送到远程仓库
echo "📤 推送到 GitHub..."
git push origin $BRANCH

# 在服务器上拉取更新
echo "📥 在服务器上拉取更新..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST << EOF
cd $SERVER_PATH

# 如果是第一次部署，克隆仓库
if [ ! -d ".git" ]; then
    echo "📦 首次部署，克隆仓库..."
    cd /root/apps
    git clone $GIT_REPO party-system
    cd party-system
else
    echo "🔄 拉取最新代码..."
    git pull origin $BRANCH
fi

# 设置权限
chmod +x *.sh

# 自动部署
echo "🚀 执行自动部署..."
./manual-deploy.sh

echo "✅ Git 部署完成！"
EOF

echo "🎉 部署完成！访问地址: $APP_URL"