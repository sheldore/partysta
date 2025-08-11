#!/bin/bash

# 党员统计系统服务管理脚本

APP_NAME="party-system"
APP_DIR="/root/apps/party-system"
LOG_FILE="/root/logs/party-system.log"
ERROR_LOG="/root/logs/party-system-error.log"
PID_FILE="/tmp/party-system.pid"

case "$1" in
    start)
        echo "🚀 启动 $APP_NAME..."
        cd $APP_DIR
        
        # 检查是否已经运行
        if [ -f "$PID_FILE" ] && kill -0 $(cat $PID_FILE) 2>/dev/null; then
            echo "⚠️ $APP_NAME 已经在运行中"
            exit 1
        fi
        
        # 设置环境变量
        export NODE_ENV=production
        export PORT=3000
        export PARTY_ADMIN_PASSWORD=admin123456
        export BASE_PATH=/partysta
        
        # 启动应用
        nohup node backend-server.js > $LOG_FILE 2> $ERROR_LOG &
        echo $! > $PID_FILE
        
        sleep 2
        if kill -0 $(cat $PID_FILE) 2>/dev/null; then
            echo "✅ $APP_NAME 启动成功，PID: $(cat $PID_FILE)"
        else
            echo "❌ $APP_NAME 启动失败"
            rm -f $PID_FILE
            exit 1
        fi
        ;;
        
    stop)
        echo "🛑 停止 $APP_NAME..."
        if [ -f "$PID_FILE" ]; then
            PID=$(cat $PID_FILE)
            if kill -0 $PID 2>/dev/null; then
                kill $PID
                sleep 2
                if kill -0 $PID 2>/dev/null; then
                    kill -9 $PID
                fi
                echo "✅ $APP_NAME 已停止"
            else
                echo "⚠️ $APP_NAME 进程不存在"
            fi
            rm -f $PID_FILE
        else
            # 尝试通过进程名停止
            pkill -f backend-server.js
            echo "✅ 已尝试停止 $APP_NAME"
        fi
        ;;
        
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
        
    status)
        echo "📊 $APP_NAME 状态："
        if [ -f "$PID_FILE" ] && kill -0 $(cat $PID_FILE) 2>/dev/null; then
            echo "✅ 运行中，PID: $(cat $PID_FILE)"
            echo "📊 内存使用: $(ps -o pid,ppid,rss,vsz,comm -p $(cat $PID_FILE) 2>/dev/null | tail -1)"
        else
            echo "❌ 未运行"
            # 清理可能存在的无效 PID 文件
            rm -f $PID_FILE
        fi
        
        # 检查端口
        if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then
            echo "✅ 端口 3000 正在监听"
        else
            echo "❌ 端口 3000 未监听"
        fi
        ;;
        
    logs)
        echo "📋 查看日志 (按 Ctrl+C 退出):"
        tail -f $LOG_FILE
        ;;
        
    errors)
        echo "📋 查看错误日志:"
        if [ -f "$ERROR_LOG" ]; then
            tail -20 $ERROR_LOG
        else
            echo "无错误日志文件"
        fi
        ;;
        
    *)
        echo "用法: $0 {start|stop|restart|status|logs|errors}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  status  - 查看状态"
        echo "  logs    - 查看日志"
        echo "  errors  - 查看错误日志"
        exit 1
        ;;
esac