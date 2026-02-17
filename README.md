# Auto-Seedbox-PT (ASP)

🚀 **专为 PT 玩家打造的终极服务器自动化部署工具**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![System](https://img.shields.io/badge/System-Debian%20%7C%20Ubuntu-green.svg)]()
[![Architecture](https://img.shields.io/badge/Arch-x86__64%20%7C%20arm64-orange.svg)]()

**Auto-Seedbox-PT** 是一个高度智能化的 Shell 脚本，旨在简化 PT 专用服务器（Seedbox）的部署流程。它不仅能一键安装 qBittorrent、Vertex 和 FileBrowser，更能根据你选择的软件版本（v4 或 v5）和硬件环境（SSD 或 HDD），**自动应用最底层的内核级优化参数**，最大限度释放服务器性能。

---

## ✨ 核心特性

### 🛡️ 安全透明
- **零黑盒**：移除所有不明来源的二进制文件和闭源组件。
- **原生加密**：使用 Python3 标准库生成 PBKDF2 密码哈希，杜绝后门风险。
- **最小权限**：Docker 容器以非 Root 用户身份运行，保障宿主机安全。

### 🧠 双核智能引擎
脚本会自动识别 qBittorrent 的内核版本，并应用完全不同的优化策略：
- **v4 模式 (libtorrent 1.x)**：优化应用层缓存，根据磁盘类型调整异步 I/O 线程。
- **v5 模式 (libtorrent 2.x)**：启用 MMap 策略，调整内核脏页比例和 Swap，利用系统空闲内存加速 I/O。

### 🔄 版本随心选
- **稳定养老**：默认安装 **4.3.9**（PT 圈公认最稳版本）。
- **尝鲜技术**：支持 `-q latest` 一键安装最新版。
- **指定版本**：支持安装任意历史版本（如 `4.6.4`、`5.0.3`），脚本自动从 GitHub API 搜索下载。

### 🎛️ 灵活配置
- **交互式端口**：使用 `-o` 参数开启交互模式，自定义 WebUI、BT 监听及应用端口。
- **数据一键恢复**：安装 Vertex 时支持 `-d` 指定备份 URL，自动下载并恢复数据，甚至修正端口配置。

---

## 🖥️ 环境要求

- **操作系统**: Debian 10+ / Ubuntu 20.04+
- **硬件架构**: x86_64 (AMD64) / aarch64 (ARM64)
- **用户权限**: Root 用户

---

## ⚡ 快速开始

### 1. 一键安装（推荐）
使用以下命令直接运行脚本（无需下载）：
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) -u ptseedbox2026 -p PtSeedB0x-2026 -c 1024 -v -f -t
```

### 2. 基础安装
安装 qBittorrent 4.3.9（稳定版）。
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) -u admin -p password123 -c 1024 -t
```

### 3. 全能安装（带 Vertex 和 FileBrowser）
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) -u admin -p password123 -c 1024 -v -f -t
```

### 4. 自定义端口（交互模式）
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) -u admin -p password123 -c 1024 -v -f -t -o
```

### 5. 安装最新版（v5.x）
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) -u admin -p password123 -c 1024 -q latest -t
```

### 6. 迁移与恢复（恢复 Vertex 数据）
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) -u admin -p password123 -c 1024 -v -f -t -d "https://your-server.com/backup/vertex.zip" -k "zip_password"
```

> **提示**：以上命令中的用户名、密码、缓存大小请根据实际情况修改。

---

## 📝 参数详解

| 参数 | 必填 | 描述 | 示例 |
|------|------|------|------|
| `-u` | ✅ | 用户名（WebUI 及系统用户） | `-u admin` |
| `-p` | ✅ | 密码（必须 ≥ 12 位） | `-p mysecurepass` |
| `-c` | ✅ | 缓存大小 (MB)<br>注：v5 模式下仅作安装校验，实际由内核管理 | `-c 2048` |
| `-q` | ❌ | 指定版本，支持 `4.3.9`（默认）、`latest` 或具体版本号如 `5.0.4` | `-q latest` |
| `-v` | ❌ | 安装 Vertex 面板 | `-v` |
| `-f` | ❌ | 安装 FileBrowser | `-f` |
| `-t` | ❌ | 启用系统内核优化（强烈推荐） | `-t` |
| `-o` | ❌ | 自定义端口（交互式询问） | `-o` |
| `-d` | ❌ | Vertex 备份 ZIP 下载链接 | `-d http://...` |
| `-k` | ❌ | Vertex 备份 ZIP 解压密码 | `-k 123456` |

---

## 🗑️ 卸载与清理

**普通卸载（保留数据）**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) --uninstall
```

**彻底清除（删库）**  
⚠️ 警告：这将连同用户主目录及所有下载文件一并删除！
```bash
bash <(wget -qO- https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh) --purge
```

---

## ⚠️ 常见问题

**Q:** 为什么安装 v5 版本后内存占用显示很高？  
**A:** 这是正常的。v5 使用内存映射 I/O（MMap），Linux 会利用空闲内存作为 Page Cache 加速文件读写。这部分内存在系统显示为 "Cached"，当其他程序需要内存时会自动释放。

**Q:** 我应该选 v4 还是 v5？  
**A:**  
- **v4 (4.3.9)**：极其稳定，适合长期保种，对内存控制严格，适合小内存机器或追求极致稳定的用户。  
- **v5 (Latest)**：性能更强，适合大带宽刷流，但对磁盘 I/O 机制依赖较重。

**Q:** 脚本报错 `syntax error` 或乱码？  
**A:** 请确保脚本使用 UTF-8 编码，且没有 Windows 换行符（CRLF）。建议直接使用 `wget` 下载 raw 文件运行。

---

## 📜 License

本项目基于 [MIT License](LICENSE) 开源，基于 [vivibudong/PT-Seedbox](https://github.com/vivibudong/PT-Seedbox) 深度重构。您可以自由修改、分发，但请保留原作者署名。
