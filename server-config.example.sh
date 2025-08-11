#!/bin/bash

# 服务器配置文件示例
# 复制此文件为 server-config.sh 并修改为你的实际配置

# 服务器基本信息
export SERVER_HOST="deapps.huihys.ip-ddns.com"  # 你的服务器域名或 IP
export SERVER_USER="root"                       # SSH 用户名
export SERVER_PORT="22"                         # SSH 端口
export SERVER_PATH="/root/apps/party-system"    # 服务器上的部署路径

# Git 仓库信息
export GIT_REPO="https://github.com/sheldore/partysta.git"
export GIT_BRANCH="main"

# 应用配置
export APP_PORT="3000"                          # 应用端口
export BASE_PATH="/partysta"                    # 应用子路径
export PARTY_ADMIN_PASSWORD="admin123456"      # 管理员密码（请修改）

# WebSSH 和文件管理
export WEBSSH_PORT="8888"
export DUFS_PORT="5000"

# 访问地址
export APP_URL="https://${SERVER_HOST}${BASE_PATH}"
export WEBSSH_URL="https://${SERVER_HOST}:${WEBSSH_PORT}"
export DUFS_URL="https://${SERVER_HOST}:${DUFS_PORT}"

# 显示配置信息
echo "🔧 服务器配置信息："
echo "   服务器地址: $SERVER_HOST"
echo "   SSH 端口: $SERVER_PORT"
echo "   用户名: $SERVER_USER"
echo "   部署路径: $SERVER_PATH"
echo "   Git 仓库: $GIT_REPO"
echo "   应用地址: $APP_URL"
echo "   WebSSH: $WEBSSH_URL"
echo "   文件管理: $DUFS_URL"
echo ""
echo "💡 使用说明："
echo "1. 复制此文件: cp server-config.example.sh server-config.sh"
echo "2. 修改配置: nano server-config.sh"
echo "3. 执行部署: ./deploy/git-deploy.sh"