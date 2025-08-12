// 多用户党员管理系统后端服务
// 使用 Node.js + Express + 文件存储

const express = require('express');
const multer = require('multer');
const XLSX = require('xlsx');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// 支持子路径部署
const BASE_PATH = process.env.BASE_PATH || '/partysta';

// 配置
const CONFIG = {
    adminPassword: process.env.PARTY_ADMIN_PASSWORD || 'admin123456', // 管理员密码
    dataDir: './data',         // 数据存储目录
    maxFileSize: 50 * 1024 * 1024, // 最大文件大小 50MB
    allowedExtensions: ['.xlsx', '.xls']
};

// 中间件
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// 静态文件服务 - 支持子路径
app.use(BASE_PATH, express.static('public'));
app.use(BASE_PATH + '/static', express.static('public'));

// 安全中间件
const helmet = require('helmet');
const compression = require('compression');
app.use(helmet({
    contentSecurityPolicy: false // 允许内联脚本，适应现有前端代码
}));
app.use(compression());

// 文件上传配置
const upload = multer({
    dest: 'uploads/',
    limits: { fileSize: CONFIG.maxFileSize },
    fileFilter: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        if (CONFIG.allowedExtensions.includes(ext)) {
            cb(null, true);
        } else {
            cb(new Error('只支持 Excel 文件格式'));
        }
    }
});

// 确保数据目录存在
async function ensureDataDirectories() {
    const dirs = [
        CONFIG.dataDir,
        path.join(CONFIG.dataDir, 'summary'),
        path.join(CONFIG.dataDir, 'details'),
        path.join(CONFIG.dataDir, 'logs')
    ];
    
    for (const dir of dirs) {
        try {
            await fs.access(dir);
        } catch {
            await fs.mkdir(dir, { recursive: true });
        }
    }
}

// 文件锁机制
class FileLock {
    constructor() {
        this.locks = new Map();
    }
    
    async acquire(filePath) {
        const lockKey = path.resolve(filePath);
        
        while (this.locks.has(lockKey)) {
            await new Promise(resolve => setTimeout(resolve, 10));
        }
        
        this.locks.set(lockKey, true);
    }
    
    release(filePath) {
        const lockKey = path.resolve(filePath);
        this.locks.delete(lockKey);
    }
}

const fileLock = new FileLock();

// 安全读写文件
async function safeReadFile(filePath, defaultValue = null) {
    try {
        await fileLock.acquire(filePath);
        const data = await fs.readFile(filePath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        if (error.code === 'ENOENT') {
            return defaultValue;
        }
        throw error;
    } finally {
        fileLock.release(filePath);
    }
}

async function safeWriteFile(filePath, data) {
    try {
        await fileLock.acquire(filePath);
        await fs.writeFile(filePath, JSON.stringify(data, null, 2), 'utf8');
    } finally {
        fileLock.release(filePath);
    }
}

// 操作日志
async function logOperation(operation, user, data) {
    const logFile = path.join(CONFIG.dataDir, 'logs', 'operations.json');
    const logs = await safeReadFile(logFile, []);
    
    logs.push({
        timestamp: new Date().toISOString(),
        operation,
        user: user || 'anonymous',
        data,
        id: crypto.randomBytes(16).toString('hex')
    });
    
    // 只保留最近1000条日志
    if (logs.length > 1000) {
        logs.splice(0, logs.length - 1000);
    }
    
    await safeWriteFile(logFile, logs);
}

// 创建API路由器
const apiRouter = express.Router();

// 0. 健康检查端点
apiRouter.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        services: {
            database: 'file-based',
            storage: 'local'
        }
    });
});

// 1. 管理员验证
apiRouter.post('/auth/admin', (req, res) => {
    const { password } = req.body;
    
    if (password === CONFIG.adminPassword) {
        const token = crypto.randomBytes(32).toString('hex');
        // 简单的token验证，生产环境建议使用JWT
        res.json({ 
            success: true, 
            token,
            message: '管理员验证成功' 
        });
    } else {
        res.status(401).json({ 
            success: false, 
            message: '密码错误' 
        });
    }
});

// 2. 获取单位列表
apiRouter.get('/units', async (req, res) => {
    try {
        const unitsFile = path.join(CONFIG.dataDir, 'units.json');
        const units = await safeReadFile(unitsFile, []);
        res.json({ success: true, data: units });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 3. 添加/更新单位
apiRouter.post('/units', async (req, res) => {
    try {
        const { units } = req.body;
        const unitsFile = path.join(CONFIG.dataDir, 'units.json');
        
        await safeWriteFile(unitsFile, units);
        await logOperation('update_units', req.ip, { count: units.length });
        
        res.json({ success: true, message: '单位列表更新成功' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 4. 上传明细数据
apiRouter.post('/data/upload', upload.single('file'), async (req, res) => {
    try {
        const { unit, type } = req.body;
        const file = req.file;
        
        if (!file) {
            return res.status(400).json({ success: false, message: '请选择文件' });
        }
        
        // 读取Excel文件
        const workbook = XLSX.readFile(file.path);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
        
        // 保存明细数据
        const detailDir = path.join(CONFIG.dataDir, 'details', unit);
        await fs.mkdir(detailDir, { recursive: true });
        
        const detailFile = path.join(detailDir, `type${type}.json`);
        const detailData = {
            unit,
            type,
            data,
            filename: file.originalname,
            uploadTime: new Date().toISOString(),
            recordCount: data.length - 1 // 减去表头
        };
        
        await safeWriteFile(detailFile, detailData);
        
        // 更新汇总数据
        await updateSummaryData(unit);
        
        // 记录操作日志
        await logOperation('upload_data', req.ip, {
            unit,
            type,
            filename: file.originalname,
            recordCount: detailData.recordCount
        });
        
        // 清理临时文件
        await fs.unlink(file.path);
        
        res.json({ 
            success: true, 
            message: '数据上传成功',
            recordCount: detailData.recordCount
        });
        
    } catch (error) {
        // 清理临时文件
        if (req.file) {
            try {
                await fs.unlink(req.file.path);
            } catch {}
        }
        
        res.status(500).json({ success: false, message: error.message });
    }
});

// 5. 获取汇总统计数据
apiRouter.get('/data/summary', async (req, res) => {
    try {
        const summaryDir = path.join(CONFIG.dataDir, 'summary');
        const files = await fs.readdir(summaryDir).catch(() => []);
        
        const allUnitsStats = {};
        
        for (const file of files) {
            if (file.endsWith('.json')) {
                const unit = path.basename(file, '.json');
                const summaryFile = path.join(summaryDir, file);
                const unitData = await safeReadFile(summaryFile, {});
                allUnitsStats[unit] = unitData;
            }
        }
        
        res.json({ success: true, data: allUnitsStats });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 6. 获取单位详细数据
apiRouter.get('/data/unit/:unit', async (req, res) => {
    try {
        const { unit } = req.params;
        const detailDir = path.join(CONFIG.dataDir, 'details', unit);
        
        const unitStats = {};
        const files = await fs.readdir(detailDir).catch(() => []);
        
        for (const file of files) {
            if (file.endsWith('.json')) {
                const type = file.replace('type', '').replace('.json', '');
                const detailFile = path.join(detailDir, file);
                const typeData = await safeReadFile(detailFile, null);
                
                if (typeData) {
                    unitStats[type] = typeData.data || [];
                }
            }
        }
        
        res.json({ success: true, data: unitStats });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 7. 导出汇总数据
apiRouter.get('/data/export', async (req, res) => {
    try {
        // 这里需要管理员权限验证
        const token = req.headers.authorization;
        if (!token) {
            return res.status(401).json({ success: false, message: '需要管理员权限' });
        }
        
        const summaryDir = path.join(CONFIG.dataDir, 'summary');
        const files = await fs.readdir(summaryDir).catch(() => []);
        
        const exportData = [];
        const headers = ['单位', '党员人数', '党委数', '党总支数', '党支部数', '入党申请人数', '发展党员数', '转入党员数', '转出党员数', '死亡党员数'];
        exportData.push(headers);
        
        let totals = [0, 0, 0, 0, 0, 0, 0, 0, 0];
        
        for (const file of files) {
            if (file.endsWith('.json')) {
                const unit = path.basename(file, '.json');
                const summaryFile = path.join(summaryDir, file);
                const unitData = await safeReadFile(summaryFile, {});
                
                // 分析党组织类型
                const orgStats = analyzeOrganizationTypes(unitData['2'] || []);
                
                const row = [
                    unit,
                    unitData['1'] || 0,
                    orgStats.党委 || 0,
                    orgStats.党总支 || 0,
                    orgStats.党支部 || 0,
                    unitData['4'] || 0,
                    unitData['5'] || 0,
                    unitData['6'] || 0,
                    unitData['7'] || 0,
                    unitData['10'] || 0
                ];
                
                exportData.push(row);
                
                // 累计总数
                for (let i = 1; i < row.length; i++) {
                    totals[i - 1] += row[i] || 0;
                }
            }
        }
        
        // 添加总计行
        exportData.push(['总计', ...totals]);
        
        // 创建Excel文件
        const wb = XLSX.utils.book_new();
        const ws = XLSX.utils.aoa_to_sheet(exportData);
        XLSX.utils.book_append_sheet(wb, ws, '汇总统计');
        
        const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
        
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', `attachment; filename="汇总统计_${new Date().toISOString().split('T')[0]}.xlsx"`);
        res.send(buffer);
        
        await logOperation('export_data', req.ip, { recordCount: exportData.length - 2 });
        
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 8. 导入汇总数据
apiRouter.post('/data/import', upload.single('file'), async (req, res) => {
    try {
        // 需要管理员权限验证
        const token = req.headers.authorization;
        if (!token) {
            return res.status(401).json({ success: false, message: '需要管理员权限' });
        }
        
        const file = req.file;
        if (!file) {
            return res.status(400).json({ success: false, message: '请选择文件' });
        }
        
        // 读取Excel文件
        const workbook = XLSX.readFile(file.path);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
        
        // 验证数据格式
        if (!validateImportData(data)) {
            throw new Error('导入文件格式不正确');
        }
        
        // 清除现有数据
        const summaryDir = path.join(CONFIG.dataDir, 'summary');
        const detailsDir = path.join(CONFIG.dataDir, 'details');
        
        await fs.rm(summaryDir, { recursive: true, force: true });
        await fs.rm(detailsDir, { recursive: true, force: true });
        await fs.mkdir(summaryDir, { recursive: true });
        await fs.mkdir(detailsDir, { recursive: true });
        
        // 处理导入的数据
        await processImportedData(data);
        
        // 清理临时文件
        await fs.unlink(file.path);
        
        await logOperation('import_data', req.ip, { 
            filename: file.originalname,
            recordCount: data.length - 1
        });
        
        res.json({ 
            success: true, 
            message: '数据导入成功',
            recordCount: data.length - 1
        });
        
    } catch (error) {
        if (req.file) {
            try {
                await fs.unlink(req.file.path);
            } catch {}
        }
        
        res.status(500).json({ success: false, message: error.message });
    }
});

// 9. 清除单位数据
apiRouter.delete('/data/unit/:unit', async (req, res) => {
    try {
        // 需要管理员权限验证
        const token = req.headers.authorization;
        if (!token) {
            return res.status(401).json({ success: false, message: '需要管理员权限' });
        }
        
        const { unit } = req.params;
        
        // 删除汇总数据
        const summaryFile = path.join(CONFIG.dataDir, 'summary', `${unit}.json`);
        await fs.unlink(summaryFile).catch(() => {});
        
        // 删除明细数据
        const detailDir = path.join(CONFIG.dataDir, 'details', unit);
        await fs.rm(detailDir, { recursive: true, force: true }).catch(() => {});
        
        await logOperation('clear_unit_data', req.ip, { unit });
        
        res.json({ success: true, message: `单位 ${unit} 的数据已清除` });
        
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// 辅助函数

// 更新汇总数据
async function updateSummaryData(unit) {
    const detailDir = path.join(CONFIG.dataDir, 'details', unit);
    const summaryFile = path.join(CONFIG.dataDir, 'summary', `${unit}.json`);
    
    const unitStats = {};
    
    try {
        const files = await fs.readdir(detailDir);
        
        for (const file of files) {
            if (file.endsWith('.json')) {
                const type = file.replace('type', '').replace('.json', '');
                const detailFile = path.join(detailDir, file);
                const typeData = await safeReadFile(detailFile, null);
                
                if (typeData && typeData.data) {
                    if (type === '2') {
                        // 党组织数据保留原始记录用于类型分析
                        unitStats[type] = typeData.data.slice(1); // 去掉表头
                    } else {
                        unitStats[type] = typeData.data.length - 1; // 去掉表头的记录数
                    }
                }
            }
        }
        
        await safeWriteFile(summaryFile, unitStats);
    } catch (error) {
        console.error('更新汇总数据失败:', error);
    }
}

// 分析党组织类型
function analyzeOrganizationTypes(orgData) {
    const types = { 党委: 0, 党总支: 0, 党支部: 0 };
    
    if (Array.isArray(orgData)) {
        orgData.forEach(record => {
            // 假设组织类别在第4列（索引3）
            const orgCategory = record[3] || '';
            
            if (typeof orgCategory === 'string') {
                if (/党委/.test(orgCategory)) {
                    types.党委++;
                } else if (/总/.test(orgCategory)) {
                    types.党总支++;
                } else {
                    types.党支部++;
                }
            }
        });
    }
    
    return types;
}

// 验证导入数据格式
function validateImportData(data) {
    if (!Array.isArray(data) || data.length < 2) {
        return false;
    }
    
    const headers = data[0];
    const expectedHeaders = ['单位', '党员人数', '党委数', '党总支数', '党支部数', '入党申请人数', '发展党员数', '转入党员数', '转出党员数', '死亡党员数'];
    
    return expectedHeaders.every((header, index) => 
        headers[index] && headers[index].toString().trim() === header
    );
}

// 处理导入的数据
async function processImportedData(data) {
    const dataRows = data.slice(1); // 跳过表头
    
    for (const row of dataRows) {
        const unitName = row[0];
        
        // 跳过总计行
        if (unitName === '总计') continue;
        
        const partyMemberCount = parseInt(row[1]) || 0;
        const committeeCount = parseInt(row[2]) || 0;
        const branchCount = parseInt(row[3]) || 0;
        const subBranchCount = parseInt(row[4]) || 0;
        const applicantCount = parseInt(row[5]) || 0;
        
        // 创建单位目录
        const detailDir = path.join(CONFIG.dataDir, 'details', unitName);
        await fs.mkdir(detailDir, { recursive: true });
        
        // 生成模拟的明细数据
        const detailData = {
            '1': generateMockData('党员', partyMemberCount),
            '2': generateMockOrgData(committeeCount, branchCount, subBranchCount),
            '4': generateMockData('申请人', applicantCount)
        };
        
        // 保存明细数据
        for (const [type, mockData] of Object.entries(detailData)) {
            if (mockData.length > 0) {
                const detailFile = path.join(detailDir, `type${type}.json`);
                await safeWriteFile(detailFile, {
                    unit: unitName,
                    type,
                    data: mockData,
                    filename: '导入的汇总数据',
                    uploadTime: new Date().toISOString(),
                    recordCount: mockData.length - 1
                });
            }
        }
        
        // 更新汇总数据
        await updateSummaryData(unitName);
    }
}

// 生成模拟数据
function generateMockData(prefix, count) {
    if (count === 0) return [];
    
    const data = [['姓名', '备注']]; // 表头
    for (let i = 1; i <= count; i++) {
        data.push([`${prefix}${i}`, '导入数据']);
    }
    return data;
}

// 生成模拟党组织数据
function generateMockOrgData(committeeCount, branchCount, subBranchCount) {
    const data = [['组织名称', '组织类型', '备注', '组织类别']]; // 表头
    
    for (let i = 1; i <= committeeCount; i++) {
        data.push([`党委${i}`, '党委', '导入数据', '党委']);
    }
    for (let i = 1; i <= branchCount; i++) {
        data.push([`党总支${i}`, '党总支', '导入数据', '党总支']);
    }
    for (let i = 1; i <= subBranchCount; i++) {
        data.push([`党支部${i}`, '党支部', '导入数据', '党支部']);
    }
    
    return data;
}

// 挂载API路由器
app.use(BASE_PATH + '/api', apiRouter);

// 主页路由 - 重定向到子路径
app.get('/', (req, res) => {
    res.redirect(BASE_PATH);
});

// 子路径主页
app.get(BASE_PATH, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 启动服务器
async function startServer() {
    await ensureDataDirectories();
    
    app.listen(PORT, () => {
        console.log(`🚀 党员管理系统服务器启动成功`);
        console.log(`📍 服务地址: http://localhost:${PORT}${BASE_PATH}`);
        console.log(`📁 数据目录: ${path.resolve(CONFIG.dataDir)}`);
        console.log(`🔐 管理员密码: ${CONFIG.adminPassword}`);
    });
}

// 错误处理
process.on('uncaughtException', (error) => {
    console.error('未捕获的异常:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('未处理的Promise拒绝:', reason);
});

// 启动服务器
startServer().catch(console.error);

module.exports = app;