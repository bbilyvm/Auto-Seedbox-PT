/**
 * Auto-Seedbox-PT (ASP) MediaInfo 前端扩展
 * 由 Nginx 底层动态注入
 */
(function() {
    console.log("🚀 [ASP] MediaInfo 沉浸式 UI 已加载，专为 PT 发种优化！");
    
    const copyText = (text) => { /* 保持原样 */ return navigator.clipboard.writeText(text); };
    function getCurrentPath() { /* 保持原样 */ return '/'; }
    let lastRightClickedFile = "";
    // ... [保留原有的右键/左键监听逻辑] ...

    const openMediaInfo = (fileName) => {
        let fullPath = (getCurrentPath() + '/' + fileName).replace(/\/\//g, '/');
        if (typeof Swal === 'undefined') {
            alert('UI组件正在加载，请稍后再试...'); return;
        }
        Swal.fire({
            title: '解析中...',
            text: '正在提取底层媒体轨道信息',
            allowOutsideClick: false,
            background: '#1a1b1e',
            color: '#e4e5e8',
            didOpen: () => Swal.showLoading()
        });
        
        // 模拟请求后端 API
        fetch(`/api/mi?file=${encodeURIComponent(fullPath)}`)
        .then(r => r.json())
        .then(data => {
            if(data.error) throw new Error(data.error);
            
            let rawText = "";
            // 🚀 核心美化 CSS
            let html = `<style>
                .mi-container { 
                    text-align: left; 
                    background: #141517; 
                    color: #c9d1d9; 
                    padding: 20px; 
                    border-radius: 12px; 
                    max-height: 60vh; 
                    overflow-y: auto; 
                    font-family: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace; 
                    font-size: 13.5px;
                    line-height: 1.6;
                    box-shadow: inset 0 0 10px rgba(0,0,0,0.5);
                }
                /* 自定义暗黑滚动条 */
                .mi-container::-webkit-scrollbar { width: 8px; }
                .mi-container::-webkit-scrollbar-track { background: #1a1b1e; border-radius: 4px; }
                .mi-container::-webkit-scrollbar-thumb { background: #3f4148; border-radius: 4px; }
                .mi-container::-webkit-scrollbar-thumb:hover { background: #5c5f66; }

                .mi-track { margin-bottom: 24px; }
                .mi-track:last-child { margin-bottom: 0; }
                
                .mi-track-header { 
                    font-size: 14px; 
                    font-weight: 700; 
                    letter-spacing: 1px;
                    text-transform: uppercase;
                    padding: 6px 12px; 
                    margin-bottom: 12px; 
                    border-radius: 6px;
                    background: #1e1f24;
                    display: inline-block;
                }
                
                /* 轨道专属强调色 */
                .mi-Video .mi-track-header { color: #61afef; border-left: 3px solid #61afef; }
                .mi-Audio .mi-track-header { color: #98c379; border-left: 3px solid #98c379; }
                .mi-Text .mi-track-header { color: #d19a66; border-left: 3px solid #d19a66; }
                .mi-General .mi-track-header { color: #e5c07b; border-left: 3px solid #e5c07b; }
                .mi-Menu .mi-track-header { color: #c678dd; border-left: 3px solid #c678dd; }

                /* 数据行布局：抛弃虚线，改用 Grid 和 Hover */
                .mi-item { 
                    display: grid; 
                    grid-template-columns: 200px 1fr; 
                    padding: 4px 12px; 
                    border-radius: 4px;
                    transition: background 0.2s ease;
                }
                .mi-item:hover { background: rgba(255, 255, 255, 0.04); }
                
                .mi-key { color: #7f848e; font-weight: 500; }
                .mi-val { color: #e4e5e8; word-break: break-all; }
            </style><div class="mi-container">`;

            if (data.media && data.media.track) {
                data.media.track.forEach(t => {
                    let type = t['@type'] || 'Unknown';
                    rawText += `${type}\n`;
                    html += `<div class="mi-track mi-${type}"><div class="mi-track-header">${type}</div>`;

                    for (let k in t) { 
                        if (k === '@type') continue;
                        let val = t[k];
                        if (typeof val === 'object') val = JSON.stringify(val);
                        
                        let paddedKey = String(k).padEnd(32, ' ');
                        rawText += `${paddedKey}: ${val}\n`;

                        html += `<div class="mi-item"><div class="mi-key">${k}</div><div class="mi-val">${val}</div></div>`;
                    }
                    rawText += `\n`;
                    html += `</div>`;
                });
            }
            html += `</div>`;
            
            Swal.fire({ 
                title: `<span style="font-size: 18px; color: #fff;">${fileName}</span>`, 
                html: html, 
                width: '900px', // 加宽一点让数据展示更舒展
                background: '#1a1b1e', // 配合整体暗黑
                showCancelButton: true,
                showDenyButton: true,
                buttonsStyling: false, // 禁用默认样式，启用自定义类
                customClass: {
                    confirmButton: 'swal2-styled swal2-confirm asp-btn-blue',
                    denyButton: 'swal2-styled swal2-deny asp-btn-green',
                    cancelButton: 'swal2-styled swal2-cancel asp-btn-gray'
                },
                confirmButtonText: '<i class="material-icons" style="vertical-align: middle; font-size: 16px;">content_copy</i> 纯文本',
                denyButtonText: '<i class="material-icons" style="vertical-align: middle; font-size: 16px;">forum</i> 复制 BBCode',
                cancelButtonText: '关闭'
            }).then((result) => {
                let textToCopy = rawText.trim();
                let successMsg = '纯文本已复制到剪贴板';

                if (result.isConfirmed) {
                    textToCopy = rawText.trim();
                } else if (result.isDenied) {
                    // 优化了 BBCode 格式，直接贴到类似 PterClub 这样的主流 PT 站发布页，格式绝对规整
                    textToCopy = `[quote]\n${rawText.trim()}\n[/quote]`;
                    successMsg = 'BBCode 已复制，快去发种吧！';
                } else {
                    return;
                }

                copyText(textToCopy).then(() => {
                    Swal.fire({
                        toast: true, position: 'top-end', icon: 'success', 
                        title: successMsg, background: '#1a1b1e', color: '#fff', 
                        showConfirmButton: false, timer: 2500
                    });
                });
            });
        }).catch(e => Swal.fire({title: '解析失败', text: e.toString(), icon: 'error', background: '#1a1b1e', color: '#fff'}));
    };

    // ... [保留 observer 注入逻辑] ...
})();
