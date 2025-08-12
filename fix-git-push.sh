#!/bin/bash

# 修复 Git 推送问题

echo "🔧 修复 Git 推送问题..."

# 检查当前分支
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "📋 当前分支: $current_branch"

# 检查是否有提交
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "📝 没有任何提交，创建初始提交..."
    
    # 添加所有文件
    git add .
    
    # 创建初始提交
    git commit -m "Initial commit: Party member management system

🎯 党员统计管理系统
- 多用户协作支持
- Excel 文件上传处理
- 数据汇总统计
- 管理员权限控制
- 子路径部署 (/partysta)
- SSL 证书支持

🚀 部署信息:
- 目标服务器: deapps.huihys.ip-ddns.com
- 部署路径: /root/apps/party-system
- 访问地址: https://deapps.huihys.ip-ddns.com/partysta"

    echo "✅ 初始提交完成"
else
    echo "✅ 已有提交记录"
fi

# 确保在 main 分支
if [ "$current_branch" != "main" ]; then
    echo "🔄 创建并切换到 main 分支..."
    git checkout -b main 2>/dev/null || git checkout main
    echo "✅ 已切换到 main 分支"
fi

# 检查远程仓库
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "🔗 添加远程仓库..."
    git remote add origin https://github.com/sheldore/partysta.git
fi

echo "📤 推送到 GitHub..."
if git push -u origin main; then
    echo "✅ 推送成功！"
    echo ""
    echo "🎉 GitHub 仓库设置完成！"
    echo "📍 仓库地址: https://github.com/sheldore/partysta"
    echo ""
    echo "🚀 下一步: 在服务器上部署"
    echo "   ssh root@deapps.huihys.ip-ddns.com"
    echo "   curl -sSL https://raw.githubusercontent.com/sheldore/partysta/main/first-deploy-server.sh | bash"
else
    echo "❌ 推送失败"
    echo ""
    echo "🔧 可能的解决方案:"
    echo "1. 确保 GitHub 仓库已创建: https://github.com/new"
    echo "2. 仓库名称: partysta"
    echo "3. 不要初始化任何文件"
    echo "4. 检查网络连接"
    echo ""
    echo "📋 手动推送命令:"
    echo "   git push -u origin main"
fi