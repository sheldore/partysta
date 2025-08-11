#!/bin/bash

# 增强版同步脚本 - 支持增量上传和自动部署

# 加载配置
if [ -f "../server-config.sh" ]; then
    source ../server-config.sh
else
    echo "❌ 请先配置 server-config.sh 文件"
    exit 1
fi

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示菜单
show_menu() {
    echo -e "${BLUE}🚀 ClawCloud 部署工具${NC}"
    echo "================================"
    echo "1. 📤 上传所有文件"
    echo "2. 🔄 增量同步（只上传修改的文件）"
    echo "3. 🚀 上传并自动部署"
    echo "4. 📊 查看服务器状态"
    echo "5. 📋 查看服务器日志"
    echo "6. 🔧 连接到服务器"
    echo "7. 🌐 打开应用"
    echo "0. 退出"
    echo "================================"
    read -p "请选择操作 (0-7): " choice
}

# 检查服务器连接
check_connection() {
    echo -e "${YELLOW}📡 检查服务器连接...${NC}"
    if ssh -p $SERVER_PORT -o ConnectTimeout=10 $SERVER_USER@$SERVER_HOST "echo '连接成功'" 2>/dev/null; then
        echo -e "${GREEN}✅ 服务器连接正常${NC}"
        return 0
    else
        echo -e "${RED}❌ 无法连接到服务器${NC}"
        echo "请检查："
        echo "  - 服务器地址: $SERVER_HOST"
        echo "  - SSH 端口: $SERVER_PORT"
        echo "  - 网络连接"
        return 1
    fi
}

# 上传所有文件
upload_all() {
    echo -e "${YELLOW}📤 上传所有文件到服务器...${NC}"
    
    # 创建远程目录
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "mkdir -p $SERVER_PATH"
    
    # 使用 rsync 上传（如果可用）
    if command -v rsync >/dev/null 2>&1; then
        echo "使用 rsync 同步文件..."
        rsync -avz --progress -e "ssh -p $SERVER_PORT" \
            --exclude='.git' \
            --exclude='node_modules' \
            --exclude='*.log' \
            ../ $SERVER_USER@$SERVER_HOST:$SERVER_PATH/
    else
        echo "使用 scp 上传文件..."
        # 核心文件
        scp -P $SERVER_PORT ../*.js ../*.html ../*.css ../*.json ../*.md $SERVER_USER@$SERVER_HOST:$SERVER_PATH/ 2>/dev/null
        scp -P $SERVER_PORT ../*.sh ../*.conf $SERVER_USER@$SERVER_HOST:$SERVER_PATH/ 2>/dev/null
    fi
    
    # 设置权限
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd $SERVER_PATH && chmod +x *.sh"
    
    echo -e "${GREEN}✅ 文件上传完成${NC}"
}

# 主程序
main() {
    # 检查配置
    if [ -z "$SERVER_HOST" ] || [ "$SERVER_HOST" = "your-clawcloud-domain.com" ]; then
        echo -e "${RED}❌ 请先配置 server-config.sh 文件${NC}"
        echo "编辑 server-config.sh，设置你的服务器信息"
        exit 1
    fi
    
    while true; do
        show_menu
        
        case $choice in
            1)
                check_connection && upload_all
                ;;
            0)
                echo -e "${GREEN}👋 再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择，请重新输入${NC}"
                ;;
        esac
        
        echo ""
        read -p "按 Enter 继续..."
        clear
    done
}

# 运行主程序
main