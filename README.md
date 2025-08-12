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

### 方法一：完整部署流程（推荐）

```bash
# 一键完成：推送到 GitHub + 部署到服务器
chmod +x full-deploy.sh
./full-deploy.sh
```

### 方法二：分步部署

```bash
# 步骤1: 推送到 GitHub
chmod +x push-to-github.sh
./push-to-github.sh

# 步骤2: 部署到服务器
chmod +x deploy-to-server.sh
./deploy-to-server.sh
```

### 方法三：WebSSH 部署

如果 SSH 连接失败，使用 WebSSH：
- 访问: https://dewebssh.huihys.ip-ddns.com
- 用户名: `club`, 密码: `123456`
- 参考: [WebSSH 部署指南](WEBSSH-DEPLOY.md)

## 🌐 访问地址

部署完成后，可通过以下地址访问：

- **主应用**: `https://deapps.huihys.ip-ddns.com/partysta`
- **健康检查**: `https://deapps.huihys.ip-ddns.com/partysta/api/health`
- **WebSSH 终端**: `https://dewebssh.huihys.ip-ddns.com` (club/123456)
- **文件管理**: `https://dedufs.huihys.ip-ddns.com` (club/123456)

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
│   └── core/                # 核心代码
│       ├── backend-server.js    # Node.js 后端服务器
│       ├── index.html           # 前端页面
│       ├── script-multiuser.js  # 多用户前端脚本
│       ├── styles.css          # 样式文件
│       └── package.json        # 依赖配置
├── 🔧 部署脚本
│   ├── deploy.sh            # 一键部署脚本 ⭐
│   ├── manual-deploy.sh     # 手动部署脚本
│   ├── service.sh           # 服务管理脚本
│   └── start-app.sh         # 应用启动脚本
├── ⚙️ 配置文件
│   ├── supervisor-party.conf   # 进程管理配置
│   ├── nginx-party.conf        # Nginx 配置
│   └── server-config.example.sh # 服务器配置示例
└── 📖 文档
    ├── README.md            # 项目说明
    └── LICENSE             # 许可证
```

## 🔧 常用命令

```bash
# 完整部署流程
./full-deploy.sh         # 推送到 GitHub + 部署到服务器

# 分步部署
./push-to-github.sh      # 推送代码到 GitHub
./deploy-to-server.sh    # 部署到服务器

# 服务器端命令
./deploy.sh              # 服务器一键部署
./service.sh start       # 启动服务
./service.sh stop        # 停止服务
./service.sh restart     # 重启服务
./service.sh status      # 查看状态
./service.sh logs        # 查看日志
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