# 🌐 WebSSH 部署指南

如果 SSH 连接失败，可以使用 WebSSH 进行手动部署。

## 🚀 部署步骤

### 1. 访问 WebSSH
- **地址**: https://dewebssh.huihys.ip-ddns.com
- **用户名**: `club`
- **密码**: `123456`

### 2. 在 WebSSH 终端中执行

```bash
# 切换到 root 用户
sudo su -

# 克隆 GitHub 仓库
git clone https://github.com/sheldore/partysta.git /root/apps/party-system

# 进入项目目录
cd /root/apps/party-system

# 设置权限
chmod +x *.sh

# 执行一键部署
./deploy.sh
```

### 3. 验证部署

```bash
# 查看服务状态
./service.sh status

# 查看日志
./service.sh logs

# 测试访问
curl http://localhost:3000/partysta/api/health
```

## 🔧 如果 git clone 失败

```bash
# 下载项目压缩包
wget https://github.com/sheldore/partysta/archive/refs/heads/main.zip -O partysta.zip

# 解压
unzip partysta.zip

# 移动到目标目录
mv partysta-main /root/apps/party-system

# 进入目录并部署
cd /root/apps/party-system
chmod +x *.sh
./deploy.sh
```

## 🌐 访问地址

部署完成后访问：
- **主应用**: https://deapps.huihys.ip-ddns.com/partysta
- **健康检查**: https://deapps.huihys.ip-ddns.com/partysta/api/health