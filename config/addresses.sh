#!/bin/bash

# 统一地址配置文件
# 所有脚本都可以引用这个文件来获取正确的地址

# 主应用服务器
export MAIN_HOST="deapps.huihys.ip-ddns.com"
export MAIN_URL="https://${MAIN_HOST}"
export APP_URL="https://${MAIN_HOST}/partysta"
export HEALTH_URL="https://${MAIN_HOST}/partysta/api/health"

# WebSSH 服务
export WEBSSH_HOST="dewebssh.huihys.ip-ddns.com"
export WEBSSH_URL="https://${WEBSSH_HOST}"
export WEBSSH_USER="club"
export WEBSSH_PASS="123456"

# 文件管理服务 (DUFS)
export DUFS_HOST="dedufs.huihys.ip-ddns.com"
export DUFS_URL="https://${DUFS_HOST}"
export DUFS_USER="club"
export DUFS_PASS="123456"

# SSH 配置
export SSH_HOST="$MAIN_HOST"
export SSH_USER="root"
export SSH_PORT="22"

# 部署配置
export DEPLOY_PATH="/root/apps/party-system"
export GIT_REPO="https://github.com/sheldore/partysta.git"
export GIT_BRANCH="main"

# 显示所有地址信息
show_addresses() {
    echo "🌐 服务地址信息："
    echo "   主应用: $APP_URL"
    echo "   健康检查: $HEALTH_URL"
    echo "   WebSSH: $WEBSSH_URL ($WEBSSH_USER/$WEBSSH_PASS)"
    echo "   文件管理: $DUFS_URL ($DUFS_USER/$DUFS_PASS)"
    echo "   SSH: ssh $SSH_USER@$SSH_HOST -p $SSH_PORT"
    echo "   部署路径: $DEPLOY_PATH"
    echo "   Git 仓库: $GIT_REPO"
}