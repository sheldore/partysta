#!/bin/bash

# 一键设置 GitHub 部署脚本
# 自动初始化 Git 仓库并推送到 GitHub

REPO_URL="https://github.com/sheldore/partysta.git"
BRANCH="main"

echo "🚀 开始设置 GitHub 部署..."
echo "📋 仓库信息："
echo "   GitHub 仓库: $REPO_URL"
echo "   分支: $BRANCH"
echo "   用户名: sheldore"
echo "================================"

# 检查是否已经是 Git 仓库
if [ -d ".git" ]; then
    echo "✅ 已经是 Git 仓库"
else
    echo "📦 初始化 Git 仓库..."
    git init
    echo "✅ Git 仓库初始化完成"
fi

# 检查远程仓库
if git remote get-url origin >/dev/null 2>&1; then
    echo "✅ 远程仓库已配置"
    echo "   当前远程仓库: $(git remote get-url origin)"
else
    echo "🔗 添加远程仓库..."
    git remote add origin $REPO_URL
    echo "✅ 远程仓库添加完成"
fi

# 配置服务器信息
if [ ! -f "server-config.sh" ]; then
    echo "⚙️ 创建服务器配置文件..."
    cp server-config.example.sh server-config.sh
    echo "✅ 配置文件已创建: server-config.sh"
    echo "💡 配置文件已预设为你的服务器信息，如需修改请编辑 server-config.sh"
else
    echo "✅ 服务器配置文件已存在"
fi

# 检查 Git 用户配置
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
    echo "👤 配置 Git 用户信息..."
    read -p "请输入你的 Git 用户名 (默认: sheldore): " git_username
    git_username=${git_username:-sheldore}
    
    read -p "请输入你的 Git 邮箱: " git_email
    if [ -z "$git_email" ]; then
        git_email="sheldore@users.noreply.github.com"
    fi
    
    git config user.name "$git_username"
    git config user.email "$git_email"
    echo "✅ Git 用户信息配置完成"
fi

# 添加所有文件
echo "📁 添加文件到 Git..."
git add .

# 检查是否有需要提交的更改
if git diff --cached --quiet; then
    # 检查是否有任何提交
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo "📝 创建初始提交..."
        commit_message="Initial commit: Party member management system for ClawCloud

Features:
- Multi-user collaboration support
- Excel file upload and processing
- Data summary and statistics
- Admin permission control
- Sub-path deployment (/partysta)
- SSL support with self-signed certificates

Deployment:
- Target server: deapps.huihys.ip-ddns.com
- Deploy path: /root/apps/party-system
- Access URL: https://deapps.huihys.ip-ddns.com/partysta"

        git commit -m "$commit_message"
        echo "✅ 初始提交完成"
    else
        echo "✅ 没有需要提交的更改"
    fi
else
    echo "📝 提交更改..."
    commit_message="Update: Party member management system - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_message"
    echo "✅ 提交完成"
fi

# 确保在 main 分支上
current_branch=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$current_branch" != "main" ]; then
    echo "🔄 切换到 main 分支..."
    if git show-ref --verify --quiet refs/heads/main; then
        git checkout main
    else
        git checkout -b main
    fi
    echo "✅ 已切换到 main 分支"
fi

# 推送到 GitHub
echo "📤 推送到 GitHub..."
if git push -u origin $BRANCH; then
    echo "✅ 推送成功！"
else
    echo "❌ 推送失败，可能需要先在 GitHub 创建仓库"
    echo ""
    echo "🔧 解决步骤："
    echo "1. 访问 https://github.com/new"
    echo "2. 创建名为 'partysta' 的仓库"
    echo "3. 不要初始化 README、.gitignore 或 LICENSE"
    echo "4. 创建后重新运行此脚本"
    echo ""
    echo "或者手动推送："
    echo "   git push -u origin main"
    exit 1
fi

# 设置脚本权限
echo "🔐 设置脚本权限..."
chmod +x deploy/git-deploy.sh
chmod +x deploy/*.sh
chmod +x scripts/linux/*.sh

echo ""
echo "🎉 GitHub 部署设置完成！"
echo ""
echo "📍 仓库地址: $REPO_URL"
echo "🌐 访问地址: https://deapps.huihys.ip-ddns.com/partysta"
echo ""
echo "🚀 下一步操作："
echo "1. 在服务器上首次部署："
echo "   ssh root@deapps.huihys.ip-ddns.com"
echo "   git clone $REPO_URL /root/apps/party-system"
echo "   cd /root/apps/party-system"
echo "   ./deploy/server-git-deploy.sh"
echo ""
echo "2. 后续更新部署："
echo "   ./deploy/git-deploy.sh"
echo ""
echo "💡 提示: 所有配置已预设完成，可以直接使用！"