# 🎯 党员统计管理系统

一个支持多用户协作的党员数据管理系统，基于 Node.js + Express 构建，支持 Excel 文件上传、数据汇总统计和管理员权限控制。

## ✨ 功能特性

- ✅ **多用户协作支持** - 多人同时上传和管理数据
- ✅ **Excel 文件处理** - 支持 .xlsx/.xls 格式文件上传
- ✅ **数据汇总统计** - 自动生成各类统计报表
- ✅ **管理员权限控制** - 分级权限管理
- ✅ **数据导出功能** - 支持导出 Excel 格式报表
- ✅ **实时数据同步** - 多用户数据实时更新
- ✅ **子路径部署** - 支持 `/partysta` 子路径访问

## 🚀 快速部署

### 方法一：Git 部署（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/sheldore/partysta.git
cd partysta

# 2. 配置服务器信息
cp server-config.example.sh server-config.sh
nano server-config.sh  # 修改为你的服务器信息

# 3. 执行 Git 部署
chmod +x deploy/git-deploy.sh
./deploy/git-deploy.sh
```

### 方法二：直接部署

```bash
# 1. 上传文件到服务器
./deploy/sync-to-server.sh

# 2. 在服务器上执行
ssh root@your-server
cd /root/apps/party-system
./manual-deploy.sh
```

## 🌐 访问地址

部署完成后，可通过以下地址访问：

- **主应用**: `https://deapps.huihys.ip-ddns.com/partysta`
- **健康检查**: `https://deapps.huihys.ip-ddns.com/partysta/api/health`

## 🔐 默认配置

- **管理员密码**: `admin123456` (请及时修改)
- **部署路径**: `/root/apps/party-system`
- **应用端口**: `3000` (内部)
- **访问端口**: `80/443` (通过 Nginx 代理)

## 📋 系统要求

- **Node.js**: >= 12.0.0
- **操作系统**: Linux (Ubuntu 20.04+ 推荐)
- **内存**: 最低 1GB，推荐 2GB
- **存储**: 最低 10GB 可用空间

## 🛠️ 开发环境

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 或直接启动
node backend-server.js
```

## 📁 项目结构

```
partysta/
├── 📄 核心应用文件
│   ├── backend-server.js      # Node.js 后端服务器
│   ├── index.html            # 前端页面
│   ├── script-multiuser.js   # 多用户前端脚本
│   ├── styles.css           # 样式文件
│   └── package.json         # 依赖配置
├── 🔧 部署脚本
│   ├── deploy-setup.sh      # 主要部署脚本
│   ├── manual-deploy.sh     # 手动部署脚本
│   ├── service.sh           # 服务管理脚本
│   └── start-app.sh         # 应用启动脚本
├── 📁 工具脚本
│   ├── scripts/linux/       # Linux/macOS 脚本
│   ├── scripts/windows/     # Windows 脚本
│   └── scripts/powershell/  # PowerShell 脚本
├── 📁 部署工具
│   └── deploy/              # 各种部署方案
└── 📁 配置示例
    └── configs/             # Nginx 等配置示例
```

## 🔧 常用命令

```bash
# 服务管理
./service.sh start    # 启动服务
./service.sh stop     # 停止服务
./service.sh restart  # 重启服务
./service.sh status   # 查看状态
./service.sh logs     # 查看日志

# DNS 和 SSL
./scripts/linux/check-dns.sh        # 检查 DNS 解析
./scripts/linux/quick-ssl-setup.sh  # 配置 SSL 证书

# 部署更新
./deploy/git-deploy.sh              # Git 部署
./deploy/sync-to-server.sh          # 同步部署
```

## 🔒 安全配置

### 修改默认密码

```bash
# 方法1: 环境变量
export PARTY_ADMIN_PASSWORD="your-secure-password"

# 方法2: 修改配置文件
nano backend-server.js  # 修改 CONFIG.adminPassword
```

### SSL 证书配置

```bash
# 快速 SSL 配置（自签名证书）
./scripts/linux/quick-ssl-setup.sh

# 或使用 Let's Encrypt（如果 Certbot 正常）
./scripts/linux/setup-ssl.sh
```

## 📊 功能说明

### 数据管理
- 支持多种党员数据类型上传
- 自动数据验证和清洗
- 实时统计和汇总

### 用户权限
- 普通用户：上传和查看自己单位的数据
- 管理员：查看所有数据、导出报表、清除数据

### 数据安全
- 文件上传大小限制
- 数据格式验证
- 操作日志记录

## 🐛 故障排除

### 常见问题

1. **应用无法启动**
   ```bash
   # 检查依赖
   npm install
   
   # 查看日志
   ./service.sh logs
   ```

2. **HTTPS 无法访问**
   ```bash
   # 配置 SSL 证书
   ./scripts/linux/quick-ssl-setup.sh
   ```

3. **DNS 解析问题**
   ```bash
   # 检查解析状态
   ./scripts/linux/check-dns.sh
   ```

## 📞 技术支持

- **项目地址**: https://github.com/sheldore/partysta
- **问题反馈**: 请在 GitHub 上提交 Issue
- **文档**: 查看 `docs/` 目录下的详细文档

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

**🎉 感谢使用党员统计管理系统！**