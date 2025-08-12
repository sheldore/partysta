#!/bin/bash

# 完整部署流程：推送到 GitHub + 部署到服务器

echo "🚀 党员统计系统完整部署流程"
echo "================================"
echo "步骤1: 推送代码到 GitHub"
echo "步骤2: 部署到 ClawCloud 服务器"
echo "================================"

# 第一步：推送到 GitHub
echo ""
echo "📤 第一步：推送到 GitHub..."
if [ -f "push-to-github.sh" ]; then
    chmod +x push-to-github.sh
    ./push-to-github.sh
    
    if [ $? -ne 0 ]; then
        echo "❌ GitHub 推送失败，停止部署"
        exit 1
    fi
else
    echo "❌ 找不到 push-to-github.sh 脚本"
    exit 1
fi

# 询问是否继续部署
echo ""
read -p "🤔 是否继续部署到服务器？(y/N): " continue_deploy
if [[ ! "$continue_deploy" =~ ^[Yy]$ ]]; then
    echo "⏸️ 部署已暂停，代码已推送到 GitHub"
    echo "💡 稍后可以运行: ./deploy-to-server.sh"
    exit 0
fi

# 第二步：部署到服务器
echo ""
echo "🚀 第二步：部署到服务器..."
if [ -f "deploy-to-server.sh" ]; then
    chmod +x deploy-to-server.sh
    ./deploy-to-server.sh
else
    echo "❌ 找不到 deploy-to-server.sh 脚本"
    exit 1
fi

echo ""
echo "🎉 完整部署流程完成！"