# 📁 脚本使用指南

## 🗂️ 文件夹结构

```
partysta/
├── scripts/                    # 工具脚本
│   ├── linux/                 # Linux/macOS 脚本
│   │   ├── check-dns.sh       # DNS 解析检查
│   │   ├── monitor-domain.sh  # 域名状态监控
│   │   └── setup-local-hosts.sh # 本地 hosts 配置
│   ├── windows/               # Windows 批处理脚本
│   │   ├── check-dns.bat      # DNS 解析检查
│   │   ├── monitor-domain.bat # 域名状态监控
│   │   └── setup-hosts.bat    # 本地 hosts 配置
│   └── powershell/            # PowerShell 脚本
│       └── check-dns.ps1      # DNS 解析检查
├── deploy/                    # 部署脚本
│   ├── upload-to-server.sh    # 文件上传
│   ├── sync-to-server.sh      # 同步部署
│   └── git-deploy.sh          # Git 部署
├── configs/                   # 配置文件
│   └── nginx-examples/        # Nginx 配置示例
└── docs/                      # 文档
    └── README-SCRIPTS.md      # 本文档
```

## 🚀 使用方法

### Linux/macOS 用户

```bash
# 进入脚本目录
cd scripts/linux

# 给脚本执行权限
chmod +x *.sh

# 检查 DNS 解析
./check-dns.sh

# 监控域名状态
./monitor-domain.sh

# 配置本地 hosts
./setup-local-hosts.sh
```

### Windows 用户

#### 方法1：双击运行批处理文件
```
scripts/windows/check-dns.bat          # 双击运行
scripts/windows/monitor-domain.bat     # 双击运行
scripts/windows/setup-hosts.bat        # 右键"以管理员身份运行"
```

#### 方法2：使用 PowerShell
```powershell
# 打开 PowerShell，进入项目目录
cd scripts/powershell
.\check-dns.ps1
```

#### 方法3：使用 Git Bash
```bash
cd scripts/linux
chmod +x *.sh
./check-dns.sh
```

## 📤 部署脚本使用

### 1. 配置服务器信息
首先编辑根目录的 `server-config.sh` 文件：
```bash
export SERVER_HOST="deapps.huihys.ip-ddns.com"
export SERVER_USER="root"
export SERVER_PORT="22"
```

### 2. 选择部署方式

#### 简单上传
```bash
cd deploy
chmod +x upload-to-server.sh
./upload-to-server.sh
```

#### 同步部署（推荐）
```bash
cd deploy
chmod +x sync-to-server.sh
./sync-to-server.sh
```

#### Git 部署
```bash
cd deploy
chmod +x git-deploy.sh
./git-deploy.sh
```

## 🔧 故障排除

### DNS 解析问题
1. 运行 `check-dns.sh` 或 `check-dns.bat` 检查状态
2. 如果解析失败，运行 `setup-local-hosts.sh` 临时解决
3. 使用 `monitor-domain.sh` 持续监控解析状态

### 部署问题
1. 确保 `server-config.sh` 配置正确
2. 检查 SSH 连接是否正常
3. 确保服务器上有足够的权限

### Windows 脚本问题
1. 如果批处理文件无法运行，尝试使用 Git Bash
2. PowerShell 脚本可能需要执行策略设置：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 💡 提示

- 所有脚本都已配置好默认的域名和服务器信息
- 可以根据需要修改脚本中的配置
- 建议先在测试环境中验证脚本功能
- 定期备份重要数据和配置