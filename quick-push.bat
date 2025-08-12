@echo off
chcp 65001 >nul
echo 🚀 快速推送地址更新到 GitHub...
echo ================================

cd /d "%~dp0"

echo 📋 当前目录: %CD%
echo 📋 检查文件...
dir /b *.sh

echo.
echo 🔐 设置脚本权限...
if exist "push-to-github.sh" (
    echo ✅ 找到推送脚本
) else (
    echo ❌ 找不到 push-to-github.sh
    pause
    exit /b 1
)

echo.
echo 📤 执行推送...
bash -c "git add . && git commit -m 'Update WebSSH and DUFS addresses

🌐 地址更新:
- WebSSH: https://dewebssh.huihys.ip-ddns.com
- DUFS: https://dedufs.huihys.ip-ddns.com

📁 更新文件:
- README.md
- server-config.example.sh  
- WEBSSH-DEPLOY.md
- deploy-to-server.sh
- config/addresses.sh (新增)
- check-addresses.sh (新增)

✨ 新增功能:
- 统一地址配置管理
- 地址连通性检查脚本' && git push origin main"

echo.
echo 🎉 推送完成！
pause