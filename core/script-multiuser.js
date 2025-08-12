// 多用户版本的前端代码
// 将原有的IndexedDB操作替换为服务器API调用

class PartyDataManager {
    constructor() {
        this.currentUnit = '';
        this.localData = null;
        this.nationalData = null;
        this.detailData = {};
        this.compareResults = null;
        this.isAdmin = false;
        this.adminToken = null;
        this.sessionStateRestored = false;
        this.adminPassword = 'admin123';
        
        // API基础URL - 支持子路径部署
        this.apiBaseUrl = window.location.origin.includes('localhost') 
            ? 'http://localhost:3000/partysta/api' 
            : '/partysta/api';

        // 设置全局引用以便HTML中调用
        window.partyDataManager = this;

        this.init();
    }

    async init() {
        this.bindEvents();
        await this.loadUnitsFromServer();
        this.restoreSessionState();
        this.clearUploadSessionState();
        
        // 检查管理员权限并设置按钮可见性
        setTimeout(() => {
            this.checkAdminPermission();
            this.updateButtonVisibility();
        }, 100);
    }

    // API调用封装
    async apiCall(endpoint, options = {}) {
        const url = `${this.apiBaseUrl}${endpoint}`;
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                ...(this.adminToken && { 'Authorization': this.adminToken })
            }
        };

        const finalOptions = {
            ...defaultOptions,
            ...options,
            headers: {
                ...defaultOptions.headers,
                ...options.headers
            }
        };

        try {
            const response = await fetch(url, finalOptions);
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || `HTTP ${response.status}`);
            }
            
            return data;
        } catch (error) {
            console.error(`API调用失败 ${endpoint}:`, error);
            throw error;
        }
    }

    // 密码验证和权限控制
    async promptAdminPassword() {
        const password = prompt('请输入管理员密码：');
        if (!password) return false;

        try {
            const result = await this.apiCall('/auth/admin', {
                method: 'POST',
                body: JSON.stringify({ password })
            });

            if (result.success) {
                this.isAdmin = true;
                this.adminToken = result.token;
                sessionStorage.setItem('adminAuth', 'true');
                sessionStorage.setItem('adminToken', result.token);
                
                // 刷新统计显示以显示管理员按钮
                await this.updateStatistics();
                alert('管理员权限验证成功！');
                return true;
            }
        } catch (error) {
            alert('密码错误或服务器连接失败！');
        }
        
        return false;
    }

    // 检查管理员权限
    checkAdminPermission() {
        const savedAuth = sessionStorage.getItem('adminAuth');
        const savedToken = sessionStorage.getItem('adminToken');
        
        if (savedAuth === 'true' && savedToken) {
            this.isAdmin = true;
            this.adminToken = savedToken;
            return true;
        }
        return false;
    }

    // 注销管理员权限
    logoutAdmin() {
        this.isAdmin = false;
        this.adminToken = null;
        sessionStorage.removeItem('adminAuth');
        sessionStorage.removeItem('adminToken');
        this.updateStatistics();
        console.log('管理员权限已注销');
    }

    // 从服务器加载单位列表
    async loadUnitsFromServer() {
        try {
            const result = await this.apiCall('/units');
            if (result.success && result.data.length > 0) {
                this.updateUnitSelect(result.data);
                console.log('✅ 单位列表已从服务器加载:', result.data.length, '个单位');
                
                // 单位选项加载完成后，尝试恢复会话状态
                setTimeout(() => {
                    this.restoreSessionStateAfterUnitsLoaded();
                }, 100);
            } else {
                console.warn('⚠️ 服务器中没有单位数据，尝试初始化默认单位');
                await this.initializeDefaultUnits();
            }
        } catch (error) {
            console.error('❌ 加载单位列表失败:', error);
            // 如果服务器连接失败，尝试初始化默认单位
            await this.initializeDefaultUnits();
        }
    }

    // 初始化默认单位数据
    async initializeDefaultUnits() {
        console.log('🔧 初始化默认单位数据...');
        
        const defaultUnits = [
            { name: '原煤队党支部', fullName: '原煤队党支部' },
            { name: '后勤中心党总支', fullName: '后勤中心党总支' },
            { name: '后勤中心（公寓）', fullName: '后勤中心（公寓）' },
            { name: '后勤中心（基本建设）', fullName: '后勤中心（基本建设）' },
            { name: '测试单位A', fullName: '测试单位A' },
            { name: '测试单位B', fullName: '测试单位B' },
            { name: '测试单位C', fullName: '测试单位C' }
        ];

        try {
            await this.apiCall('/units', {
                method: 'POST',
                body: JSON.stringify({ units: defaultUnits })
            });
            
            console.log('✅ 默认单位数据初始化成功');
            
            // 重新加载单位列表
            await this.loadUnitsFromServer();
        } catch (error) {
            console.error('❌ 初始化默认单位失败:', error);
        }
    }

    // 汇总明细数据（上传到服务器）
    async summarizeDetailData(cleanedData, type, filename) {
        if (!this.currentUnit) {
            throw new Error('请先选择单位');
        }

        try {
            // 创建FormData对象
            const formData = new FormData();
            
            // 将数据转换为Excel文件
            const wb = XLSX.utils.book_new();
            const ws = XLSX.utils.aoa_to_sheet(cleanedData);
            XLSX.utils.book_append_sheet(wb, ws, 'Sheet1');
            
            // 生成Excel文件的二进制数据
            const wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
            const blob = new Blob([wbout], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
            
            formData.append('file', blob, filename);
            formData.append('unit', this.currentUnit);
            formData.append('type', type);

            const response = await fetch(`${this.apiBaseUrl}/data/upload`, {
                method: 'POST',
                body: formData
            });

            const result = await response.json();
            
            if (!response.ok) {
                throw new Error(result.message || '上传失败');
            }

            return { recordCount: result.recordCount };
        } catch (error) {
            console.error('上传数据到服务器失败:', error);
            throw error;
        }
    }

    // 获取所有单位的统计数据
    async getAllUnitsStatistics() {
        try {
            const result = await this.apiCall('/data/summary');
            return result.success ? result.data : {};
        } catch (error) {
            console.error('获取汇总统计失败:', error);
            return {};
        }
    }

    // 获取单位统计信息
    async getUnitStatistics() {
        if (!this.currentUnit) return {};
        
        try {
            const result = await this.apiCall(`/data/unit/${this.currentUnit}`);
            return result.success ? result.data : {};
        } catch (error) {
            console.error('获取单位统计失败:', error);
            return {};
        }
    }

    // 导出数据功能
    async exportData() {
        if (!this.isAdmin) {
            if (!await this.promptAdminPassword()) {
                return;
            }
        }
        
        try {
            console.log('开始导出数据...');
            
            const response = await fetch(`${this.apiBaseUrl}/data/export`, {
                method: 'GET',
                headers: {
                    'Authorization': this.adminToken
                }
            });

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.message || '导出失败');
            }

            // 下载文件
            const blob = await response.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `汇总统计_${new Date().toISOString().split('T')[0]}.xlsx`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
            
            console.log('✅ 数据导出完成');
        } catch (error) {
            console.error('导出失败:', error);
            alert('导出失败: ' + error.message);
        }
    }

    // 导入汇总数据
    async importSummaryData(file) {
        if (!this.isAdmin) {
            if (!await this.promptAdminPassword()) {
                return;
            }
        }

        try {
            console.log('开始导入汇总数据...');
            
            this.showProgress('正在上传文件...', 20);
            
            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(`${this.apiBaseUrl}/data/import`, {
                method: 'POST',
                headers: {
                    'Authorization': this.adminToken
                },
                body: formData
            });

            this.showProgress('正在处理数据...', 60);

            const result = await response.json();
            
            if (!response.ok) {
                throw new Error(result.message || '导入失败');
            }
            
            this.showProgress('导入完成', 100);
            this.hideProgress();
            
            // 更新统计显示
            await this.updateStatistics();
            
            alert(`汇总数据导入成功！\n文件：${file.name}\n数据行数：${result.recordCount}`);
            
        } catch (error) {
            this.hideProgress();
            console.error('导入汇总数据失败:', error);
            alert('导入失败: ' + error.message);
        }
    }

    // 清除当前单位数据功能
    async clearCurrentUnitData() {
        if (!this.isAdmin) {
            if (!await this.promptAdminPassword()) {
                return;
            }
        }
        
        if (!this.currentUnit) {
            alert('请先选择单位');
            return;
        }
        
        if (!confirm(`确定要清除单位"${this.currentUnit}"的所有数据吗？\n\n此操作不可恢复！`)) {
            return;
        }
        
        try {
            await this.apiCall(`/data/unit/${this.currentUnit}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': this.adminToken
                }
            });
            
            await this.updateStatistics();
            alert('数据清除成功！');
        } catch (error) {
            console.error('清除数据失败:', error);
            alert('清除数据失败: ' + error.message);
        }
    }

    // 显示导入对话框
    showImportDialog() {
        if (!this.isAdmin) {
            if (!this.promptAdminPassword()) {
                return;
            }
        }

        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = '.xlsx,.xls';
        fileInput.style.display = 'none';
        
        fileInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                this.importSummaryData(file);
            }
        });
        
        document.body.appendChild(fileInput);
        fileInput.click();
        document.body.removeChild(fileInput);
    }

    // 更新统计信息
    async updateStatistics() {
        const summary = document.getElementById('statsSummary');
        
        if (!summary) {
            console.error('找不到统计显示区域 #statsSummary');
            return;
        }

        try {
            console.log('开始更新统计信息...');
            
            // 获取所有单位的统计数据
            const allUnitsStats = await this.getAllUnitsStatistics();
            const currentUnitStats = this.currentUnit ? await this.getUnitStatistics() : {};

            console.log('📊 统计数据调试:', {
                allUnitsStats,
                currentUnitStats,
                currentUnit: this.currentUnit,
                hasData: Object.keys(allUnitsStats).length > 0,
                allUnitsCount: Object.keys(allUnitsStats).length,
                currentUnitDataKeys: currentUnitStats ? Object.keys(currentUnitStats) : []
            });

            let html = '';

            // 显示数据更新时间和状态
            const hasAnyData = Object.keys(allUnitsStats).length > 0;
            html += `
                <div class="stats-header ${hasAnyData ? 'has-data' : 'no-data'}">
                    <h3>📊 数据统计报告</h3>
                    <p class="update-time">最后更新: ${new Date().toLocaleString()}</p>
                    ${hasAnyData ?
                    '<p class="data-status">✅ 已有数据，统计结果如下</p>' :
                    '<p class="data-status">⚠️ 暂无数据，请上传明细数据后查看统计结果</p>'
                }
                    ${!hasAnyData && this.currentUnit ?
                    `<div class="quick-actions" style="margin-top: 15px;">
                            <button onclick="window.partyDataManager.uploadSampleData()" class="btn btn-primary" style="margin-right: 10px;">上传示例数据</button>
                        </div>` : ''
                }
                </div>
            `;

            // 当前单位统计
            if (this.currentUnit) {
                const hasCurrentUnitData = currentUnitStats && Object.keys(currentUnitStats).length > 0;

                html += `
                    <div class="current-unit-stats">
                        <h4>🏢 ${this.currentUnit} - 当前单位统计</h4>
                        <div class="stats-grid">
                            ${hasCurrentUnitData ? this.generateStatsItems(currentUnitStats) : '<p class="no-data">暂无当前单位数据</p>'}
                        </div>
                    </div>
                `;
            } else {
                html += `
                    <div class="no-unit-selected">
                        <p>⚠️ 请先选择单位查看当前单位统计</p>
                    </div>
                `;
            }

            // 管理员密码验证按钮（当未登录时显示）
            if (!this.isAdmin) {
                html += `
                    <div class="admin-login">
                        <button class="btn btn-primary" onclick="window.partyDataManager.promptAdminPassword()">
                            🔐 输入管理员密码
                        </button>
                        <small class="login-hint">输入密码后可使用导出和清除功能</small>
                    </div>
                `;
            }

            // 管理员操作按钮和汇总统计（登录后显示）
            if (this.isAdmin) {
                html += `
                    <div class="admin-actions">
                        <div class="admin-buttons">
                            <button id="exportBtn" class="btn btn-success" ${hasAnyData ? '' : 'disabled'} onclick="window.partyDataManager.exportData()">
                                📊 导出汇总数据
                            </button>
                            <button id="importBtn" class="btn btn-warning" onclick="window.partyDataManager.showImportDialog()">
                                📥 导入汇总数据
                            </button>
                            <button id="clearBtn" class="btn btn-danger" onclick="window.partyDataManager.clearCurrentUnitData()">
                                🗑️ 清除当前单位数据
                            </button>
                        </div>
                        <div class="admin-hint">
                            <small>💡 管理员功能：导出Excel报表、导入修改后的数据或清除数据</small>
                        </div>
                    </div>
                    
                    <div class="all-units-stats">
                        <h4>📈 所有单位汇总统计</h4>
                        <div class="summary-table">
                            ${this.generateSummaryTable(allUnitsStats)}
                        </div>
                    </div>
                `;
            }

            summary.innerHTML = html;

            console.log('✅ 统计信息更新完成');

        } catch (error) {
            console.error('统计信息加载失败:', error);
            summary.innerHTML = `
                <div class="error-message">
                    <h4>❌ 统计信息加载失败</h4>
                    <p style="color: red;">${error.message}</p>
                    <button onclick="window.partyDataManager.updateStatistics()" class="btn btn-primary">重试</button>
                </div>
            `;
        }
    }

    // 生成统计项目HTML
    generateStatsItems(stats) {
        const items = [];
        
        // 党员数据
        if (stats['1']) {
            items.push(`<div class="stat-item"><span class="stat-label">党员人数</span><span class="stat-value">${stats['1']}</span></div>`);
        }
        
        // 党组织数据
        if (stats['2']) {
            const orgStats = this.analyzeOrganizationTypes(stats['2']);
            items.push(`<div class="stat-item"><span class="stat-label">党委数</span><span class="stat-value">${orgStats.党委}</span></div>`);
            items.push(`<div class="stat-item"><span class="stat-label">党总支数</span><span class="stat-value">${orgStats.党总支}</span></div>`);
            items.push(`<div class="stat-item"><span class="stat-label">党支部数</span><span class="stat-value">${orgStats.党支部}</span></div>`);
        }
        
        // 其他数据
        if (stats['4']) items.push(`<div class="stat-item"><span class="stat-label">入党申请人数</span><span class="stat-value">${stats['4']}</span></div>`);
        if (stats['5']) items.push(`<div class="stat-item"><span class="stat-label">发展党员数</span><span class="stat-value">${stats['5']}</span></div>`);
        if (stats['6']) items.push(`<div class="stat-item"><span class="stat-label">转入党员数</span><span class="stat-value">${stats['6']}</span></div>`);
        if (stats['7']) items.push(`<div class="stat-item"><span class="stat-label">转出党员数</span><span class="stat-value">${stats['7']}</span></div>`);
        if (stats['10']) items.push(`<div class="stat-item"><span class="stat-label">死亡党员数</span><span class="stat-value">${stats['10']}</span></div>`);
        
        return items.length > 0 ? items.join('') : '<p class="no-data">暂无数据</p>';
    }

    // 生成汇总表格
    generateSummaryTable(allUnitsStats) {
        if (Object.keys(allUnitsStats).length === 0) {
            return '<p class="no-data">暂无汇总数据</p>';
        }

        let html = `
            <table class="summary-table">
                <thead>
                    <tr>
                        <th>单位</th>
                        <th>党员人数</th>
                        <th>党委数</th>
                        <th>党总支数</th>
                        <th>党支部数</th>
                        <th>入党申请人数</th>
                        <th>发展党员数</th>
                        <th>转入党员数</th>
                        <th>转出党员数</th>
                        <th>死亡党员数</th>
                    </tr>
                </thead>
                <tbody>
        `;

        let totals = [0, 0, 0, 0, 0, 0, 0, 0, 0];

        for (const [unit, stats] of Object.entries(allUnitsStats)) {
            const orgStats = stats['2'] ? this.analyzeOrganizationTypes(stats['2']) : { 党委: 0, 党总支: 0, 党支部: 0 };
            
            const values = [
                stats['1'] || 0,
                orgStats.党委 || 0,
                orgStats.党总支 || 0,
                orgStats.党支部 || 0,
                stats['4'] || 0,
                stats['5'] || 0,
                stats['6'] || 0,
                stats['7'] || 0,
                stats['10'] || 0
            ];

            html += `<tr>
                <td>${unit}</td>
                ${values.map(v => `<td>${v}</td>`).join('')}
            </tr>`;

            // 累计总数
            values.forEach((v, i) => totals[i] += v);
        }

        html += `
                    <tr class="total-row">
                        <td><strong>总计</strong></td>
                        ${totals.map(t => `<td><strong>${t}</strong></td>`).join('')}
                    </tr>
                </tbody>
            </table>
        `;

        return html;
    }

    // 分析党组织类型
    analyzeOrganizationTypes(orgData) {
        const types = { 党委: 0, 党总支: 0, 党支部: 0 };
        
        if (Array.isArray(orgData)) {
            orgData.forEach(record => {
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

    // 绑定事件
    bindEvents() {
        // 单位选择事件
        const unitSelect = document.getElementById('unitSelect');
        if (unitSelect) {
            unitSelect.addEventListener('change', (e) => {
                this.currentUnit = e.target.value;
                sessionStorage.setItem('selectedUnit', this.currentUnit);
                this.updateStatistics();
                this.updateCompareButtonState();
            });
        }

        // 文件上传事件
        this.bindFileUploadEvents();
        this.bindDetailFileEvents();
    }

    // 绑定文件上传事件
    bindFileUploadEvents() {
        const localDataFile = document.getElementById('localDataFile');
        const nationalDataFile = document.getElementById('nationalDataFile');

        if (localDataFile) {
            localDataFile.addEventListener('change', (e) => this.handleFileUpload(e, 'local'));
        }

        if (nationalDataFile) {
            nationalDataFile.addEventListener('change', (e) => this.handleFileUpload(e, 'national'));
        }
    }

    // 绑定明细文件上传事件
    bindDetailFileEvents() {
        const detailItems = document.querySelectorAll('.detail-item');
        detailItems.forEach(item => {
            const fileInput = item.querySelector('.detail-file');
            if (fileInput) {
                fileInput.addEventListener('change', (e) => this.handleDetailFileUpload(e, item));
            }
        });
    }

    // 处理文件上传
    async handleFileUpload(event, type) {
        const file = event.target.files[0];
        if (!file) return;

        try {
            const data = await this.readExcelFile(file);
            
            if (type === 'local') {
                this.localData = data;
                this.updateFileStatus('localDataStatus', `✅ ${file.name} (${data.length - 1} 条记录)`);
            } else if (type === 'national') {
                this.nationalData = data;
                this.updateFileStatus('nationalDataStatus', `✅ ${file.name} (${data.length - 1} 条记录)`);
            }

            this.updateCompareButtonState();
        } catch (error) {
            console.error('文件读取失败:', error);
            this.updateFileStatus(type === 'local' ? 'localDataStatus' : 'nationalDataStatus', `❌ 文件读取失败: ${error.message}`);
        }
    }

    // 处理明细文件上传
    async handleDetailFileUpload(event, item) {
        const file = event.target.files[0];
        if (!file) return;

        const type = item.dataset.type;
        const statusDiv = item.querySelector('.detail-status');

        if (!this.currentUnit) {
            statusDiv.innerHTML = '❌ 请先选择单位';
            return;
        }

        try {
            statusDiv.innerHTML = '⏳ 正在处理...';
            
            const data = await this.readExcelFile(file);
            const cleanedData = this.removeEmptyRows(data);
            
            // 上传到服务器
            const result = await this.summarizeDetailData(cleanedData, type, file.name);
            
            statusDiv.innerHTML = `✅ ${file.name} (${result.recordCount} 条记录)`;
            
            // 更新统计
            await this.updateStatistics();
            
        } catch (error) {
            console.error('明细文件处理失败:', error);
            statusDiv.innerHTML = `❌ 处理失败: ${error.message}`;
        }
    }

    // 读取Excel文件
    async readExcelFile(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                try {
                    const data = new Uint8Array(e.target.result);
                    const workbook = XLSX.read(data, { type: 'array' });
                    const sheetName = workbook.SheetNames[0];
                    const worksheet = workbook.Sheets[sheetName];
                    const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
                    resolve(jsonData);
                } catch (error) {
                    reject(error);
                }
            };
            reader.onerror = () => reject(new Error('文件读取失败'));
            reader.readAsArrayBuffer(file);
        });
    }

    // 移除空行
    removeEmptyRows(data) {
        return data.filter(row => {
            return row && row.some(cell => cell !== null && cell !== undefined && cell !== '');
        });
    }

    // 更新文件状态
    updateFileStatus(statusId, message) {
        const statusElement = document.getElementById(statusId);
        if (statusElement) {
            statusElement.innerHTML = message;
        }
    }

    // 更新比对按钮状态
    updateCompareButtonState() {
        const compareBtn = document.getElementById('compareBtn');
        if (compareBtn) {
            compareBtn.disabled = !this.localData || !this.nationalData || !this.currentUnit;
        }
    }

    // 更新单位选择器
    updateUnitSelect(units) {
        const unitSelect = document.getElementById('unitSelect');
        if (!unitSelect) return;

        // 清空现有选项（保留第一个默认选项）
        while (unitSelect.children.length > 1) {
            unitSelect.removeChild(unitSelect.lastChild);
        }

        // 添加单位选项
        units.forEach(unit => {
            const option = document.createElement('option');
            option.value = unit.name;
            option.textContent = unit.fullName || unit.name;
            unitSelect.appendChild(option);
        });
    }

    // 恢复会话状态
    restoreSessionState() {
        const savedUnit = sessionStorage.getItem('selectedUnit');
        if (savedUnit) {
            const unitSelect = document.getElementById('unitSelect');
            if (unitSelect) {
                unitSelect.value = savedUnit;
                this.currentUnit = savedUnit;
            }
        }
    }

    // 恢复单位加载后的会话状态
    restoreSessionStateAfterUnitsLoaded() {
        if (this.sessionStateRestored) return;
        
        const savedUnit = sessionStorage.getItem('selectedUnit');
        if (savedUnit) {
            const unitSelect = document.getElementById('unitSelect');
            if (unitSelect) {
                // 检查保存的单位是否在选项中
                const option = Array.from(unitSelect.options).find(opt => opt.value === savedUnit);
                if (option) {
                    unitSelect.value = savedUnit;
                    this.currentUnit = savedUnit;
                    this.updateStatistics();
                    console.log('✅ 会话状态已恢复，当前单位:', savedUnit);
                } else {
                    console.warn('⚠️ 保存的单位不在当前选项中:', savedUnit);
                    sessionStorage.removeItem('selectedUnit');
                }
            }
        }
        
        this.sessionStateRestored = true;
    }

    // 清除上传会话状态
    clearUploadSessionState() {
        // 清除可能存在的上传状态
        ['localDataStatus', 'nationalDataStatus'].forEach(id => {
            const element = document.getElementById(id);
            if (element && element.innerHTML.includes('✅')) {
                element.innerHTML = '';
            }
        });
    }

    // 显示进度
    showProgress(text, percent) {
        const modal = document.getElementById('progressModal');
        const progressText = document.getElementById('progressText');
        const progressFill = document.getElementById('progressFill');
        
        if (modal && progressText && progressFill) {
            modal.style.display = 'flex';
            progressText.textContent = text;
            progressFill.style.width = percent + '%';
        }
    }

    // 隐藏进度
    hideProgress() {
        const modal = document.getElementById('progressModal');
        if (modal) {
            modal.style.display = 'none';
        }
    }

    // 更新按钮可见性
    updateButtonVisibility() {
        // 这个函数可以根据需要添加按钮显示/隐藏逻辑
    }

    // 调试状态
    debugStatus() {
        console.log('🔍 系统状态调试信息:');
        console.log('当前单位:', this.currentUnit);
        console.log('管理员状态:', this.isAdmin);
        console.log('API地址:', this.apiBaseUrl);
        console.log('本地数据:', this.localData ? '已加载' : '未加载');
        console.log('全国数据:', this.nationalData ? '已加载' : '未加载');
    }
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 党员数据管理系统 - 多用户版本启动');
    new PartyDataManager();
});