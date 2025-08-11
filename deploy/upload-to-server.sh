#!/bin/bash

# 一键上传到 ClawCloud 服务器脚本

# 服务器配置 - 请修改为你的实际信息
SERVER_HOST="deapps.huihys.ip-ddns.com"
SERVER_USER="root"
SERVER_PORT="22"  # SSH 端口，ClawCloud 通常是 22
SERVER_PATH="/root/apps/party-system"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 开始上传党员统计系统到 ClawCloud 服务器...${NC}"

# 检查服务器连接
echo -e "${YELLOW}📡 测试服务器连接...${NC}"
if ! ssh -p $SERVER_PORT -o ConnectTimeout=10 $SERVER_USER@$SERVER_HOST "echo '连接成功'" 2>/dev/null; then
    echo -e "${RED}❌ 无法连接到服务器，请检查：${NC}"
    echo "   1. 服务器地址: $SERVER_HOST"
    echo "   2. SSH 端口: $SERVER_PORT"
    echo "   3. 用户名: $SERVER_USER"
    echo "   4. SSH 密钥或密码是否正确"
    exit 1
fi

# 创建远程目录
echo -e "${YELLOW}📁 创建远程目录...${NC}"
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "mkdir -p $SERVER_PATH"

# 上传文件
echo -e "${YELLOW}📤 上传文件...${NC}"

# 核心应用文件
echo "上传核心应用文件..."
scp -P $SERVER_PORT ../backend-server.js $SERVER_USER@$SERVER_HOST:$SERVER_PATH/
scp -P $SERVER_PORT ../index.html $SERVER_USER@$SERVER_HOST:$SERVER_PATH/
scp -P $SERVER_PORT ../script-multiuser.js $SERVER_USER@$SERVER_HOST:$SERVER_PATH/
scp -P $SERVER_PORT ../styles.css $SERVER_USER@$SERVER_HOST:$SERVER_PATH/
scp -P $SERVER_PORT ../package.json $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

# 部署脚本
echo "上传部署脚本..."
scp -P $SERVER_PORT ../*.sh $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

# 配置文件
echo "上传配置文件..."
scp -P $SERVER_PORT ../configs/*.conf $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

# 文档文件
echo "上传文档..."
scp -P $SERVER_PORT ../*.md $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

# 设置权限
echo -e "${YELLOW}🔐 设置文件权限...${NC}"
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && chmod +x *.sh"

echo -e "${GREEN}✅ 上传完成！${NC}"
echo ""
echo -e "${YELLOW}📋 下一步操作：${NC}"
echo "1. 连接到服务器："
echo "   ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
echo ""
echo "2. 进入应用目录："
echo "   cd $SERVER_PATH"
echo ""
echo "3. 执行部署："
echo "   ./manual-deploy.sh"
echo ""
echo "4. 或者使用服务管理："
echo "   ./quick-fix.sh && ./service.sh start"
echo ""
echo -e "${GREEN}🎉 现在可以通过 http://your-domain/partysta 访问应用！${NC}"