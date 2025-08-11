#!/bin/bash

# 党员统计系统部署脚本
# 适用于 ClawCloud 基础镜像环境

set -e

echo "🚀 开始部署党员统计管理系统..."
echo "📅 部署时间: $(date)"
echo "🖥️ 系统信息: $(uname -a)"

# 检查环境
echo "📋 检查运行环境..."
node --version || { echo "❌ Node.js 未安装"; exit 1; }
npm --version || { echo "❌ npm 未安装"; exit 1; }
python3 --version || { echo "❌ Python3 未安装"; exit 1; }

# 创建应用目录
echo "📁 创建应用目录..."
mkdir -p /root/apps/party-system
mkdir -p /root/apps/party-system/public
mkdir -p /root/apps/party-system/data/{summary,details,logs}
mkdir -p /root/apps/party-system/uploads
mkdir -p /root/logs

# 复制应用文件
echo "📄 设置应用文件..."
cd /root/apps/party-system

# 设置前端文件
echo "🌐 设置前端文件..."
mkdir -p public
if [ -f "index.html" ]; then
    cp index.html public/
    echo "✅ index.html 已复制到 public/"
fi

if [ -f "script-multiuser.js" ]; then
    cp script-multiuser.js public/script.js
    echo "✅ script-multiuser.js 已复制为 public/script.js"
elif [ -f "script.js" ]; then
    cp script.js public/
    echo "✅ script.js 已复制到 public/"
fi

if [ -f "styles.css" ]; then
    cp styles.css public/
    echo "✅ styles.css 已复制到 public/"
fi

# 如果文件不存在，创建基本文件结构
if [ ! -f "package.json" ]; then
    echo "📦 创建 package.json..."
    cat > package.json << 'EOF'
{
  "name": "party-member-management-system",
  "version": "1.0.0",
  "description": "多用户党员管理系统",
  "main": "backend-server.js",
  "scripts": {
    "start": "node backend-server.js",
    "dev": "nodemon backend-server.js",
    "install-deps": "npm install",
    "build": "echo 'No build step required'",
    "test": "echo 'No tests specified'"
  },
  "dependencies": {
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.1",
    "xlsx": "^0.18.5",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "compression": "^1.7.4"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  },
  "engines": {
    "node": ">=16.0.0"
  },
  "keywords": [
    "党员管理",
    "多用户",
    "数据统计",
    "Excel处理"
  ],
  "author": "ClawCloud",
  "license": "MIT"
}
EOF
fi

# 安装依赖
echo "📦 安装 Node.js 依赖..."

# 设置内存限制和优化选项
export NODE_OPTIONS="--max-old-space-size=512"
export npm_config_audit=false
export npm_config_fund=false

# 清理可能存在的缓存和锁文件
rm -rf node_modules package-lock.json
npm cache clean --force 2>/dev/null || true

echo "🔧 使用内存优化安装..."
# 尝试多种安装方式
if npm install --production --no-optional --no-audit --no-fund --legacy-peer-deps; then
    echo "✅ 依赖安装成功"
elif npm install --production --no-optional --force; then
    echo "✅ 依赖安装成功 (使用 --force)"
else
    echo "⚠️ 标准安装失败，使用手动安装脚本..."
    if [ -f "install-deps.sh" ]; then
        chmod +x install-deps.sh
        ./install-deps.sh
    else
        echo "❌ 手动安装脚本不存在，尝试最小化安装..."
        npm install express@4.17.3 multer@1.4.4 xlsx@0.17.5 cors@2.8.5 --save --no-optional --no-audit
    fi
fi

# 配置 Supervisor
echo "⚙️ 配置 Supervisor..."
if [ -f "/root/apps/party-system/supervisor-party.conf" ]; then
    cp /root/apps/party-system/supervisor-party.conf /etc/supervisor/conf.d/party-system.conf
    echo "✅ Supervisor 配置已更新"
fi

# 配置 Nginx
echo "🌐 配置 Nginx..."
if [ -f "/root/apps/party-system/nginx-party.conf" ]; then
    # 备份原配置
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    
    # 应用新配置
    cp /root/apps/party-system/nginx-party.conf /etc/nginx/sites-available/default
    
    # 测试配置
    nginx -t && echo "✅ Nginx 配置测试通过" || {
        echo "❌ Nginx 配置错误，恢复备份"
        cp /etc/nginx/sites-available/default.backup /etc/nginx/sites-available/default
        exit 1
    }
fi

# 设置权限
echo "🔐 设置文件权限..."
chown -R root:root /root/apps/party-system
chmod -R 755 /root/apps/party-system
chmod +x /root/apps/party-system/*.sh 2>/dev/null || true
chmod 644 /root/apps/party-system/data -R 2>/dev/null || true

# 创建健康检查端点
echo "🏥 添加健康检查..."
if [ ! -f "/root/apps/party-system/health-check.js" ]; then
    cat > /root/apps/party-system/health-check.js << 'EOF'
// 简单的健康检查脚本
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/health',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    console.log('✅ 应用健康检查通过');
    process.exit(0);
  } else {
    console.log(`❌ 应用健康检查失败: ${res.statusCode}`);
    process.exit(1);
  }
});

req.on('error', (err) => {
  console.log(`❌ 健康检查错误: ${err.message}`);
  process.exit(1);
});

req.on('timeout', () => {
  console.log('❌ 健康检查超时');
  req.destroy();
  process.exit(1);
});

req.end();
EOF
fi

# 重新加载服务
echo "🔄 重新加载服务..."
supervisorctl reread
supervisorctl update

# 重启相关服务
echo "🔄 重启服务..."
supervisorctl restart nginx
supervisorctl start party-system

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 健康检查
echo "🏥 执行健康检查..."
node /root/apps/party-system/health-check.js || {
    echo "⚠️ 健康检查失败，查看日志："
    echo "📋 应用日志："
    tail -20 /root/logs/party-system.log 2>/dev/null || echo "日志文件不存在"
    echo "📋 错误日志："
    tail -20 /root/logs/party-system-error.log 2>/dev/null || echo "错误日志文件不存在"
}

# 显示服务状态
echo "📊 服务状态："
supervisorctl status

echo ""
echo "🎉 党员统计管理系统部署完成！"
echo ""
echo "📍 访问地址："
echo "   - 主应用: http://your-domain/"
echo "   - 文件管理: http://your-domain:5000 (用户名: club, 密码: 123456)"
echo "   - WebSSH: http://your-domain:8888 (用户名: club, 密码: 123456)"
echo ""
echo "🔧 管理命令："
echo "   - 查看应用日志: tail -f /root/logs/party-system.log"
echo "   - 重启应用: supervisorctl restart party-system"
echo "   - 查看服务状态: supervisorctl status"
echo ""
echo "📁 数据存储位置: /root/apps/party-system/data/"
echo "🔐 管理员密码: admin123456 (请及时修改)"
echo ""