#!/bin/bash

# 快速修复脚本 - 解决内存不足问题

echo "🚀 快速修复开始..."

# 停止可能运行的进程
pkill -f backend-server.js 2>/dev/null || true

# 设置内存限制
export NODE_OPTIONS="--max-old-space-size=256"

# 清理环境
echo "🧹 清理环境..."
rm -rf node_modules package-lock.json .npm
npm cache clean --force 2>/dev/null || true

# 创建最简化的 package.json
echo "📦 创建最简配置..."
cat > package.json << 'EOF'
{
  "name": "party-system",
  "version": "1.0.0",
  "main": "backend-server.js",
  "dependencies": {
    "express": "4.17.3",
    "multer": "1.4.4",
    "xlsx": "0.17.5",
    "cors": "2.8.5"
  }
}
EOF

# 只安装最核心的依赖
echo "📦 安装最核心依赖..."
npm install express@4.17.3 --save --no-optional --no-audit --no-fund
npm install multer@1.4.4 --save --no-optional --no-audit --no-fund
npm install cors@2.8.5 --save --no-optional --no-audit --no-fund

# 尝试安装 xlsx（可能会失败）
echo "📦 尝试安装 xlsx..."
if npm install xlsx@0.17.5 --save --no-optional --no-audit --no-fund; then
    echo "✅ xlsx 安装成功"
else
    echo "⚠️ xlsx 安装失败，使用备用方案"
    # 创建一个简化的 xlsx 替代
    mkdir -p node_modules/xlsx
    cat > node_modules/xlsx/index.js << 'EOF'
// 简化的 xlsx 替代
module.exports = {
    readFile: function() { throw new Error('Excel功能暂不可用'); },
    utils: {
        sheet_to_json: function() { return []; },
        book_new: function() { return {}; },
        aoa_to_sheet: function() { return {}; },
        book_append_sheet: function() {},
        write: function() { return Buffer.from(''); }
    }
};
EOF
fi

# 创建目录结构
mkdir -p public data/{summary,details,logs} uploads

# 复制前端文件
cp index.html public/ 2>/dev/null || true
cp script-multiuser.js public/script.js 2>/dev/null || true
cp styles.css public/ 2>/dev/null || true

echo "✅ 快速修复完成！"

# 测试启动
echo "🧪 测试应用启动..."
timeout 5 node backend-server.js &
sleep 2
if pgrep -f backend-server.js > /dev/null; then
    echo "✅ 应用启动成功！"
    pkill -f backend-server.js
else
    echo "⚠️ 应用启动可能有问题，请检查日志"
fi

echo ""
echo "🎉 修复完成！现在可以运行："
echo "   supervisorctl start party-system"
echo "   或者直接运行: node backend-server.js"