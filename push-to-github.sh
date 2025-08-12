#!/bin/bash

# 推送代码到 GitHub 仓库

REPO_URL="https://github.com/sheldore/partysta.git"
BRANCH="main"

echo "📤 推送代码到 GitHub..."
echo "📋 仓库信息："
echo "   GitHub 仓库: $REPO_URL"
echo "   分支: $BRANCH"
echo "================================"

# 检查是否在 Git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 Git 仓库"
    echo "💡 初始化 Git 仓库..."
    git init
    git remote add origin $REPO_URL
    echo "✅ Git 仓库初始化完成"
fi

# 检查远程仓库
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "🔗 添加远程仓库..."
    git remote add origin $REPO_URL
elif [ "$(git remote get-url origin)" != "$REPO_URL" ]; then
    echo "🔄 更新远程仓库地址..."
    git remote set-url origin $REPO_URL
fi

# 检查 Git 用户配置
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
    echo "👤 配置 Git 用户信息..."
    read -p "请输入你的 Git 用户名 (默认: sheldore): " git_username
    git_username=${git_username:-sheldore}
    
    read -p "请输入你的 Git 邮箱 (默认: sheldore@users.noreply.github.com): " git_email
    git_email=${git_email:-sheldore@users.noreply.github.com}
    
    git config user.name "$git_username"
    git config user.email "$git_email"
    echo "✅ Git 用户信息配置完成"
fi

# 检查当前分支
current_branch=$(git branch --show-current 2>/dev/null || echo "")
if [ "$current_branch" != "$BRANCH" ]; then
    echo "🔄 切换到 $BRANCH 分支..."
    if git show-ref --verify --quiet refs/heads/$BRANCH; then
        git checkout $BRANCH
    else
        git checkout -b $BRANCH
    fi
fi

# 添加所有文件
echo "📁 添加文件到暂存区..."
git add .

# 检查是否有需要提交的更改
if git diff --cached --quiet; then
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "📝 创建初始提交..."
        git commit -m "Initial commit: 党员统计管理系统

🎯 功能特性:
- 多用户协作支持
- Excel 文件上传处理
- 数据汇总统计
- 管理员权限控制
- 子路径部署 (/partysta)

🚀 部署信息:
- 目标服务器: deapps.huihys.ip-ddns.com
- 部署路径: /root/apps/party-system
- 访问地址: https://deapps.huihys.ip-ddns.com/partysta"
        echo "✅ 初始提交完成"
    else
        echo "✅ 没有需要提交的更改"
    fi
else
    echo "📝 提交更改..."
    read -p "请输入提交信息 (回车使用默认): " commit_message
    if [ -z "$commit_message" ]; then
        commit_message="Update: 党员统计系统更新 - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    git commit -m "$commit_message"
    echo "✅ 提交完成"
fi

# 推送到 GitHub
echo "📤 推送到 GitHub..."
if git push -u origin $BRANCH; then
    echo "✅ 推送成功！"
    echo ""
    echo "🎉 代码已成功推送到 GitHub！"
    echo "📍 仓库地址: $REPO_URL"
    echo ""
    echo "🚀 下一步: 部署到服务器"
    echo "   ./deploy-to-server.sh"
else
    echo "❌ 推送失败"
    echo ""
    echo "🔧 可能的解决方案:"
    echo "1. 确保 GitHub 仓库已创建: https://github.com/new"
    echo "2. 仓库名称: partysta"
    echo "3. 检查网络连接和认证"
    echo "4. 如果是私有仓库，确保有推送权限"
    exit 1
fi