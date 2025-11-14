// 复制到剪贴板功能
function copyToClipboard(button) {
    const content = button.getAttribute('data-content');
    
    // 创建临时文本区域
    const textarea = document.createElement('textarea');
    textarea.value = content;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    
    // 选择并复制文本
    textarea.select();
    document.execCommand('copy');
    
    // 移除临时元素
    document.body.removeChild(textarea);
    
    // 显示复制成功提示
    const originalText = button.textContent;
    button.textContent = '已复制!';
    button.style.background = 'linear-gradient(135deg, #28a745 0%, #20c997 100%)';
    
    setTimeout(() => {
        button.textContent = originalText;
        button.style.background = 'linear-gradient(135deg, #56ab2f 0%, #a8e6cf 100%)';
    }, 2000);
}

// 展开/收起内容功能
function toggleContent(itemId) {
    const preview = document.getElementById('preview-' + itemId);
    const full = document.getElementById('full-' + itemId);
    
    if (preview.style.display === 'none') {
        preview.style.display = 'flex';
        full.style.display = 'none';
    } else {
        preview.style.display = 'none';
        full.style.display = 'block';
    }
}

// 删除项目功能
let itemToDelete = null;

function deleteItem(itemId) {
    itemToDelete = itemId;
    document.getElementById('deleteModal').style.display = 'block';
}

// 标注功能相关函数
function toggleAnnotation(id) {
    const editor = document.getElementById(`annotation-editor-${id}`);
    const currentAnnotation = document.querySelector(`button[onclick="toggleAnnotation(${id})"]`).getAttribute('data-annotation') || '';
    
    if (editor.style.display === 'none') {
        // 显示编辑器
        document.getElementById(`annotation-input-${id}`).value = currentAnnotation;
        editor.style.display = 'block';
    } else {
        // 隐藏编辑器
        editor.style.display = 'none';
    }
}

function saveAnnotation(id) {
    const annotation = document.getElementById(`annotation-input-${id}`).value.trim();
    
    fetch(`/update/annotation/${id}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: `annotation=${encodeURIComponent(annotation)}`
    })
    .then(response => {
        if (response.ok) {
            location.reload(); // 刷新页面显示新的标注
        } else {
            alert('保存标注失败');
        }
    })
    .catch(error => {
        console.error('保存标注错误:', error);
        alert('保存标注失败');
    });
}

function cancelAnnotation(id) {
    document.getElementById(`annotation-editor-${id}`).style.display = 'none';
}

function closeDeleteModal() {
    document.getElementById('deleteModal').style.display = 'none';
    itemToDelete = null;
}

function confirmDelete() {
    if (itemToDelete) {
        // 创建表单并提交删除请求
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/delete/' + itemToDelete;
        
        // 添加CSRF令牌（如果需要）
        const csrfToken = document.querySelector('meta[name="_csrf"]');
        if (csrfToken) {
            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = '_csrf';
            csrfInput.value = csrfToken.content;
            form.appendChild(csrfInput);
        }
        
        document.body.appendChild(form);
        form.submit();
    }
}

// 页面加载完成后的初始化
document.addEventListener('DOMContentLoaded', function() {
    // 确认删除按钮事件
    const confirmDeleteBtn = document.getElementById('confirmDelete');
    if (confirmDeleteBtn) {
        confirmDeleteBtn.addEventListener('click', confirmDelete);
    }
    
    // 点击模态框外部关闭
    const modal = document.getElementById('deleteModal');
    if (modal) {
        window.addEventListener('click', function(event) {
            if (event.target === modal) {
                closeDeleteModal();
            }
        });
    }
    
    // 添加表单提交时的简单验证
    const addForm = document.querySelector('.add-form');
    if (addForm) {
        addForm.addEventListener('submit', function(event) {
            const textarea = this.querySelector('textarea[name="content"]');
            if (!textarea.value.trim()) {
                event.preventDefault();
                alert('请输入内容！');
                textarea.focus();
            }
        });
    }
    
    // 为所有复制按钮添加键盘快捷键支持
    document.addEventListener('keydown', function(event) {
        // Ctrl+C 复制当前焦点元素的内容（如果有）
        if (event.ctrlKey && event.key === 'c') {
            const focusedElement = document.activeElement;
            if (focusedElement.classList.contains('btn-copy')) {
                event.preventDefault();
                copyToClipboard(focusedElement);
            }
        }
    });
});

// 添加一些实用功能

// 自动调整文本框高度
function autoResizeTextarea(textarea) {
    textarea.style.height = 'auto';
    textarea.style.height = textarea.scrollHeight + 'px';
}

// 为添加表单的文本框添加自动调整功能
document.addEventListener('DOMContentLoaded', function() {
    const addTextarea = document.querySelector('.add-form textarea');
    if (addTextarea) {
        addTextarea.addEventListener('input', function() {
            autoResizeTextarea(this);
        });
    }
});

// 时间筛选功能
function filterByTime() {
    const timeFilter = document.getElementById('timeFilter').value;
    const customTimeRange = document.getElementById('customTimeRange');
    const startDate = document.getElementById('startDate');
    const endDate = document.getElementById('endDate');
    
    // 显示/隐藏自定义时间范围
    if (timeFilter === 'custom') {
        customTimeRange.style.display = 'inline-block';
    } else {
        customTimeRange.style.display = 'none';
    }
    
    applyFilters();
}

// 搜索功能（可选）
function searchItems(searchTerm) {
    const items = document.querySelectorAll('.item-card');
    const lowerSearchTerm = searchTerm.toLowerCase();
    
    items.forEach(item => {
        const content = item.querySelector('.item-content').textContent.toLowerCase();
        if (content.includes(lowerSearchTerm)) {
            item.style.display = 'block';
        } else {
            item.style.display = 'none';
        }
    });
    
    // 搜索后更新全选框状态
    updateBulkActions();
}

// 防抖函数
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// 综合筛选功能（优化版）
function applyFilters() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const searchType = document.getElementById('searchType').value;
    const timeFilter = document.getElementById('timeFilter').value;
    const items = document.querySelectorAll('.item-card');
    
    // 批量处理DOM更新，减少重排重绘
    const fragment = document.createDocumentFragment();
    const itemsToShow = [];
    const itemsToHide = [];
    
    items.forEach(item => {
        // 搜索筛选
        let matchesSearch = true;
        if (searchTerm !== '') {
            if (searchType === 'content') {
                // 按内容搜索
                const content = item.querySelector('.item-content').textContent.toLowerCase();
                matchesSearch = content.includes(searchTerm);
            } else if (searchType === 'annotation') {
                // 按标注搜索
                const annotationElement = item.querySelector('.item-annotation .annotation-text');
                if (annotationElement) {
                    const annotation = annotationElement.textContent.toLowerCase();
                    matchesSearch = annotation.includes(searchTerm);
                } else {
                    matchesSearch = false; // 没有标注的项目不匹配
                }
            }
        }
        
        // 时间筛选
        const itemMeta = item.querySelector('.item-meta small').textContent;
        const matchesTime = checkTimeFilter(itemMeta, timeFilter);
        
        // 收集需要显示/隐藏的项目
        if (matchesSearch && matchesTime) {
            itemsToShow.push(item);
        } else {
            itemsToHide.push(item);
        }
    });
    
    // 批量更新DOM，减少重排重绘
    requestAnimationFrame(() => {
        itemsToShow.forEach(item => item.style.display = 'block');
        itemsToHide.forEach(item => item.style.display = 'none');
        updateBulkActions();
    });
}

// 防抖优化：300ms延迟
const debouncedApplyFilters = debounce(applyFilters, 300);

// 性能监控和优化建议
function checkPerformance() {
    const items = document.querySelectorAll('.item-card');
    const itemCount = items.length;
    
    if (itemCount > 1000) {
        console.warn(`当前项目数量：${itemCount}，建议启用分页或虚拟滚动以提升性能`);
        
        // 显示性能提示
        const performanceTip = document.getElementById('performanceTip');
        if (performanceTip) {
            performanceTip.style.display = 'block';
            performanceTip.textContent = `当前显示 ${itemCount} 条记录，搜索可能稍慢，建议定期清理历史记录`;
        }
    }
}

// 虚拟滚动优化（适用于超大数据量）
function optimizeForLargeDataset() {
    const items = document.querySelectorAll('.item-card');
    const itemCount = items.length;
    
    if (itemCount > 2000) {
        // 启用分批处理
        const batchSize = 100;
        let currentBatch = 0;
        
        function processBatch() {
            const start = currentBatch * batchSize;
            const end = Math.min(start + batchSize, itemCount);
            
            for (let i = start; i < end; i++) {
                // 处理单个项目
                processItem(items[i]);
            }
            
            currentBatch++;
            if (currentBatch * batchSize < itemCount) {
                // 使用 setTimeout 让出主线程，避免阻塞UI
                setTimeout(processBatch, 0);
            }
        }
        
        function processItem(item) {
            // 这里可以添加虚拟滚动的逻辑
            // 例如：只渲染可见区域的项目
        }
        
        processBatch();
    }
}

// 检查时间筛选条件
function checkTimeFilter(itemDateStr, filterType) {
    if (filterType === 'all') {
        return true;
    }
    
    // 解析项目日期（格式：yyyy-MM-dd HH:mm）
    const itemDate = parseDateFromString(itemDateStr);
    if (!itemDate) {
        return true; // 如果解析失败，默认显示
    }
    
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    switch (filterType) {
        case 'today':
            return itemDate >= today;
            
        case 'yesterday':
            const yesterdayStart = new Date(today);
            yesterdayStart.setDate(yesterdayStart.getDate() - 1);
            const yesterdayEnd = new Date(today);
            return itemDate >= yesterdayStart && itemDate < yesterdayEnd;
            
        case 'week':
            const weekAgo = new Date(today);
            weekAgo.setDate(weekAgo.getDate() - 7);
            return itemDate >= weekAgo;
            
        case 'month':
            const monthAgo = new Date(today);
            monthAgo.setMonth(monthAgo.getMonth() - 1);
            return itemDate >= monthAgo;
            
        case 'custom':
            const startDateStr = document.getElementById('startDate').value;
            const endDateStr = document.getElementById('endDate').value;
            
            if (!startDateStr && !endDateStr) {
                return true;
            }
            
            const startDate = startDateStr ? new Date(startDateStr) : new Date('1900-01-01');
            const endDate = endDateStr ? new Date(endDateStr + ' 23:59:59') : new Date('2100-12-31');
            
            return itemDate >= startDate && itemDate <= endDate;
            
        default:
            return true;
    }
}

// 从字符串解析日期（格式：yyyy-MM-dd HH:mm）
function parseDateFromString(dateStr) {
    try {
        // 匹配 yyyy-MM-dd HH:mm 格式
        const match = dateStr.match(/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/);
        if (match) {
            const [, year, month, day, hour, minute] = match;
            return new Date(year, month - 1, day, hour, minute);
        }
        return null;
    } catch (e) {
        return null;
    }
}

// 设置默认日期
document.addEventListener('DOMContentLoaded', function() {
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('startDate').value = today;
    document.getElementById('endDate').value = today;
    
    // 检查性能
    setTimeout(checkPerformance, 1000);
});

// 清空所有内容功能
function showClearModal() {
    document.getElementById('clearModal').style.display = 'block';
}

function closeClearModal() {
    document.getElementById('clearModal').style.display = 'none';
}

// 批量选择功能
function toggleSelectAll() {
    const selectAll = document.getElementById('selectAll');
    const checkboxes = document.querySelectorAll('.item-checkbox');
    
    // 只选中可见的项目（搜索过滤后的结果）
    checkboxes.forEach(checkbox => {
        const itemCard = checkbox.closest('.item-card');
        if (itemCard && itemCard.style.display !== 'none') {
            checkbox.checked = selectAll.checked;
        }
    });
    
    updateBulkActions();
}

function updateBulkActions() {
    const checkboxes = document.querySelectorAll('.item-checkbox:checked');
    const deleteSelectedBtn = document.getElementById('deleteSelected');
    
    if (checkboxes.length > 0) {
        deleteSelectedBtn.disabled = false;
        deleteSelectedBtn.textContent = `删除选中 (${checkboxes.length})`;
    } else {
        deleteSelectedBtn.disabled = true;
        deleteSelectedBtn.textContent = '删除选中';
    }
    
    // 更新全选框状态（只考虑可见的项目）
    const selectAll = document.getElementById('selectAll');
    const allCheckboxes = document.querySelectorAll('.item-checkbox');
    const checkedCheckboxes = document.querySelectorAll('.item-checkbox:checked');
    
    // 获取可见的项目数量
    const visibleItems = Array.from(allCheckboxes).filter(checkbox => {
        const itemCard = checkbox.closest('.item-card');
        return itemCard && itemCard.style.display !== 'none';
    });
    
    // 获取可见的选中项目数量
    const visibleCheckedItems = Array.from(checkedCheckboxes).filter(checkbox => {
        const itemCard = checkbox.closest('.item-card');
        return itemCard && itemCard.style.display !== 'none';
    });
    
    if (visibleCheckedItems.length === 0) {
        selectAll.checked = false;
        selectAll.indeterminate = false;
    } else if (visibleCheckedItems.length === visibleItems.length && visibleItems.length > 0) {
        selectAll.checked = true;
        selectAll.indeterminate = false;
    } else {
        selectAll.checked = false;
        selectAll.indeterminate = true;
    }
}

function deleteSelectedItems() {
    const selectedCheckboxes = document.querySelectorAll('.item-checkbox:checked');
    const selectedCount = selectedCheckboxes.length;
    
    if (selectedCount === 0) {
        return;
    }
    
    document.getElementById('selectedCount').textContent = selectedCount;
    document.getElementById('bulkDeleteModal').style.display = 'block';
}

function closeBulkDeleteModal() {
    document.getElementById('bulkDeleteModal').style.display = 'none';
}

function confirmBulkDelete() {
    const selectedCheckboxes = document.querySelectorAll('.item-checkbox:checked');
    const selectedIds = Array.from(selectedCheckboxes).map(cb => cb.value);
    
    if (selectedIds.length === 0) {
        return;
    }
    
    // 创建表单并提交批量删除请求
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = '/delete/bulk';
    
    // 添加CSRF令牌（如果需要）
    const csrfToken = document.querySelector('meta[name="_csrf"]');
    if (csrfToken) {
        const csrfInput = document.createElement('input');
        csrfInput.type = 'hidden';
        csrfInput.name = '_csrf';
        csrfInput.value = csrfToken.content;
        form.appendChild(csrfInput);
    }
    
    // 添加选中的ID
    const idsInput = document.createElement('input');
    idsInput.type = 'hidden';
    idsInput.name = 'ids';
    idsInput.value = selectedIds.join(',');
    form.appendChild(idsInput);
    
    document.body.appendChild(form);
    form.submit();
}

// 页面加载完成后添加清空模态框的事件监听
document.addEventListener('DOMContentLoaded', function() {
    // 批量删除模态框事件
    const confirmBulkDeleteBtn = document.getElementById('confirmBulkDelete');
    if (confirmBulkDeleteBtn) {
        confirmBulkDeleteBtn.addEventListener('click', confirmBulkDelete);
    }
    
    // 批量删除模态框外部点击关闭
    const bulkDeleteModal = document.getElementById('bulkDeleteModal');
    if (bulkDeleteModal) {
        window.addEventListener('click', function(event) {
            if (event.target === bulkDeleteModal) {
                closeBulkDeleteModal();
            }
        });
    }
    
    // 清空模态框外部点击关闭
    const clearModal = document.getElementById('clearModal');
    if (clearModal) {
        window.addEventListener('click', function(event) {
            if (event.target === clearModal) {
                closeClearModal();
            }
        });
    }
});