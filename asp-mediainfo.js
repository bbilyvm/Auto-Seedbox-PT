/**
 * Auto-Seedbox-PT (ASP) MediaInfo 增强扩展 v2.1
 * 修复了路径识别、单页应用注入及 PT 站 BBCode 适配
 */
(function() {
    console.log("🚀 [ASP] MediaInfo 沉浸式 UI 已加载...");

    const copyText = (text) => {
        if (navigator.clipboard) return navigator.clipboard.writeText(text);
        const input = document.createElement('textarea');
        input.value = text; document.body.appendChild(input);
        input.select(); document.execCommand('copy');
        document.body.removeChild(input);
        return Promise.resolve();
    };

    // 修复：动态获取 FileBrowser 当前路径
    function getCurrentPath() {
        const hashPath = window.location.hash.replace('#/files', '');
        return decodeURIComponent(hashPath) || '/';
    }

    let lastRightClickedFile = "";

    // 核心：打开 MediaInfo 弹窗
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

        fetch(`/api/mi?file=${encodeURIComponent(fullPath)}`)
            .then(r => r.json())
            .then(data => {
                if (data.error) throw new Error(data.error);
                
                let rawText = "";
                let html = `<style>
                    .mi-container { text-align: left; background: #141517; color: #c9d1d9; padding: 15px; border-radius: 8px; max-height: 50vh; overflow-y: auto; font-family: monospace; font-size: 12px; }
                    .mi-track-header { color: #61afef; font-weight: bold; border-bottom: 1px solid #3e4451; margin: 10px 0 5px; padding-bottom: 3px; text-transform: uppercase; }
                    .mi-item { display: flex; padding: 2px 0; border-bottom: 1px solid rgba(255,255,255,0.02); }
                    .mi-key { width: 160px; color: #7f848e; flex-shrink: 0; }
                    .mi-val { color: #e4e5e8; word-break: break-all; }
                    .asp-btn-group { display: flex; gap: 10px; justify-content: center; margin-top: 15px; }
                    .asp-btn { padding: 8px 16px; border-radius: 5px; cursor: pointer; border: none; font-weight: bold; transition: opacity 0.2s; }
                    .btn-blue { background: #3498db; color: white; }
                    .btn-green { background: #2ecc71; color: white; }
                </style><div class="mi-container">`;

                if (data.media && data.media.track) {
                    data.media.track.forEach(t => {
                        let type = t['@type'] || 'Unknown';
                        rawText += `${type}\n`;
                        html += `<div class="mi-track-header">${type}</div>`;
                        for (let k in t) {
                            if (k === '@type') continue;
                            let val = t[k];
                            rawText += `${String(k).padEnd(25, ' ')}: ${val}\n`;
                            html += `<div class="mi-item"><div class="mi-key">${k}</div><div class="mi-val">${val}</div></div>`;
                        }
                        rawText += `\n`;
                    });
                }
                html += `</div>`;

                Swal.fire({
                    title: `<span style="font-size: 16px; color: #fff;">${fileName}</span>`,
                    html: html,
                    width: '800px',
                    background: '#1a1b1e',
                    showConfirmButton: true,
                    showDenyButton: true,
                    confirmButtonText: '复制纯文本',
                    denyButtonText: '复制 BBCode (PT用)',
                    customClass: {
                        confirmButton: 'asp-btn btn-blue',
                        denyButton: 'asp-btn btn-green'
                    }
                }).then((result) => {
                    let text = rawText.trim();
                    if (result.isDenied) text = `[quote]\n${text}\n[/quote]`;
                    if (result.isConfirmed || result.isDenied) {
                        copyText(text).then(() => {
                            Swal.fire({ toast: true, position: 'top-end', icon: 'success', title: '已复制到剪贴板', showConfirmButton: false, timer: 2000 });
                        });
                    }
                });
            })
            .catch(e => Swal.fire({ icon: 'error', title: '解析失败', text: e.message, background: '#1a1b1e', color: '#fff' }));
    };

    // 核心：动态注入按钮逻辑 (针对 FileBrowser 优化)
    const injectButton = () => {
        // 查找 FileBrowser 的右键菜单容器
        const menu = document.querySelector('#context-menu, .action-menu, .shell-menu');
        if (!menu || menu.querySelector('.asp-mi-btn')) return;

        const miBtn = document.createElement('button');
        miBtn.className = 'action asp-mi-btn';
        miBtn.setAttribute('aria-label', 'MediaInfo');
        miBtn.innerHTML = '<i class="material-icons">info</i><span>MediaInfo</span>';
        
        miBtn.onclick = () => {
            if (lastRightClickedFile) openMediaInfo(lastRightClickedFile);
            menu.style.display = 'none'; // 点击后隐藏菜单
        };

        // 插入到菜单的首位或特定位置
        menu.prepend(miBtn);
    };

    // 监听文件列表的右键点击
    document.addEventListener('contextmenu', (e) => {
        const item = e.target.closest('.item, tr');
        if (item) {
            // 获取文件名（针对 FileBrowser 不同视图的兼容处理）
            lastRightClickedFile = item.getAttribute('aria-label') || 
                                   item.querySelector('.name')?.innerText || 
                                   item.querySelector('td:nth-child(2)')?.innerText;
        }
    }, true);

    // 使用 MutationObserver 监听 DOM 变化，实现单页应用下的动态注入
    const observer = new MutationObserver(() => {
        injectButton();
    });

    observer.observe(document.body, { childList: true, subtree: true });

})();
