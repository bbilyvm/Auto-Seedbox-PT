# Auto-Seedbox-PT (ASP)

🚀 **专为 PT 玩家打造的终极服务器自动化部署与极限调优工具**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![System](https://img.shields.io/badge/System-Debian%20%7C%20Ubuntu-green.svg)]()
[![Architecture](https://img.shields.io/badge/Arch-x86__64%20%7C%20arm64-orange.svg)]()

**Auto-Seedbox-PT** 是一个高度智能化的 Shell 脚本，旨在彻底简化 PT 专用服务器（Seedbox）的部署流程。它不仅能一键安装 qBittorrent、Vertex 和 FileBrowser，更内置了极其硬核的**系统级内核调优引擎**。

无论你是使用昂贵的万兆独立服务器抢首发，还是使用便宜的家用 NAS/VPS 长期养老，ASP 都能根据你的硬件环境（内存容量、磁盘介质）和所选模式，自动注入最完美的底层参数，榨干服务器的每一滴性能。

---

## ✨ 核心特性

### ⚔️ 双模调优引擎 (Dual-Mode Tuning)
首创场景化调优模式，拒绝一刀切的无脑打药：
- **极限刷流模式 (`-m 1`)**：专为大内存、NVMe 独立服务器打造。强制锁定 CPU 最高睿频、暴增 TCP 发送/接收缓冲区至 1GB、注入 qBittorrent 隐藏网络水位线参数 (SendBufferWatermark)，适合 G口/万兆 极速抢首发。
- **均衡保种模式 (`-m 2`)**：专为轻量 VPS 和家用设备打造。采用温和的 Sysctl 优化，释放 CPU 性能限制，兼顾 I/O 吞吐与极低的系统负载，适合挂载数千种子的长期养老。
- *💡 附带硬件防呆机制：若选择极限模式但物理内存 <4GB，脚本将强制自动降级为均衡模式，防止系统 OOM 死机。*

### 🧠 底层依赖智能绑定 (libtorrent Version Lock)
摒弃繁琐的手动选择，脚本会自动抓取最新静态编译包并匹配最完美的底层库：
- **v4 模式 (4.3.9)**：强制绑定 **libtorrent v1.2.x**。应用层精准控制内存缓存，完美规避 4.x 时代的内存泄漏，PT 圈公认的稳定之王。
- **v5 模式 (最新版)**：强制绑定 **libtorrent v2.0.x**。彻底禁用应用层缓存，拥抱 MMap（内存映射）与 io_uring。通过自动调整内核脏页比例 (dirty_ratio) 让系统空闲内存接管 I/O，NVMe 满载亦不卡顿。

### 🔄 网络感知与极致容错
- **拥塞控制自适应**：脚本会自动嗅探系统内核，若已安装 `BBRx` 或 `BBRv3` 等魔改抢跑算法将自动挂载；否则安全退回原生 `BBR + FQ`，绝不强行换内核导致机器失联。
- **数据一键恢复**：支持 `-d` 指定 ZIP 备份 URL 恢复 Vertex 数据，并**自动修正**备份配置中的 qBittorrent 局域网网关 IP 和鉴权信息，实现无缝搬家。
- **真正的踏雪无痕卸载**：`--purge` 模式不仅清理容器和文件，更能将打药的 Sysctl 参数、网卡队列、甚至 CPU 调度策略 (Governor) 1:1 无损回滚至安装前的系统初始状态。

---

## 🖥️ 环境要求

- **操作系统**: **Debian 10+ / Ubuntu 20.04+** (强烈建议在纯净系统下运行)
- **硬件架构**: x86_64 (AMD64) / aarch64 (ARM64)
- **权限要求**: 必须使用 `root` 用户运行

---

## ⚡ 快速开始

> **提示**：以下命令中的 `用户名`、`密码` 请自行修改。密码长度必须 ≥ 8 位。

### 1. 极致抢跑安装（独立服务器 / 刷流首选）
安装最新版 qBittorrent v5 + 附加组件，并启用**极限刷流模式**（锁定 CPU，暴增网络并发）：
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) -u 用户名 -p 密码 -q 5 -m 1 -v -f -t
```

### 2. 均衡保种安装（轻量 VPS / NAS 首选）
安装稳定的 qBittorrent 4.3.9 + 附加组件，启用**均衡保种模式**（稳定低负载）：
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) -u 用户名 -p 密码 -q 4.3.9 -m 2 -v -f -t
```

### 3. 基础极简安装（仅 qBittorrent）
不安装面板和文件浏览器，仅部署 qBittorrent 和基础系统优化：
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) -u 用户名 -p 密码 -q 5 -m 2 -t
```

### 4. 自定义端口（交互模式）
使用 `-o` 参数，安装过程中会暂停并要求你输入自定义的各个组件端口，支持防冲突检测：
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) -u 用户名 -p 密码 -m 2 -v -f -t -o
```

### 5. 一键搬家（恢复 Vertex 数据）
从旧服务器迁移，自动下载备份包并解压覆盖：
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) -u 用户名 -p 密码 -m 2 -v -f -t -d "[https://your-server.com/backup/vertex.zip](https://your-server.com/backup/vertex.zip)" -k "zip_password"
```

---

## 📝 参数详解

| 参数 | 必填 | 描述 | 示例 |
|------|------|------|------|
| `-u` | ✅ | 用户名（用于运行服务和登录 WebUI/面板） | `-u admin` |
| `-p` | ✅ | 统一密码（必须 ≥ 8 位） | `-p mysecurepass` |
| `-m` | ❌ | **调优模式**：`1` (极限刷流) 或 `2` (均衡保种)。默认 `1` | `-m 1` |
| `-q` | ❌ | qBit 大版本：支持 `4` (锁定 4.3.9) 或 `5` (拉取最新 v5) | `-q 5` |
| `-c` | ❌ | 缓存大小 (MB)。*注：仅对 4.x 有效，5.x 使用 mmap 将被忽略* | `-c 2048` |
| `-v` | ❌ | 部署 Vertex 面板 (Docker) | `-v` |
| `-f` | ❌ | 部署 FileBrowser 文件管理器 (Docker) | `-f` |
| `-t` | ❌ | 启用系统级内核与网络调优 (强烈推荐) | `-t` |
| `-o` | ❌ | 自定义端口 (进入交互式询问) | `-o` |
| `-d` | ❌ | Vertex 备份 ZIP 远程下载链接 | `-d http://...` |
| `-k` | ❌ | Vertex 备份 ZIP 解压密码 (若无则不填) | `-k 123456` |

---

## 🗑️ 卸载与清理

本脚本自带极其完善的卸载逻辑，支持系统状态无损回滚。

**普通卸载（仅删服务，保留用户数据和内核优化）**
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) --uninstall
```

**彻底清除（删库跑路级别）** ⚠️ **警告**：这将清除所有配置文件、容器映像，并**动态回滚** CPU 频率、TCP 缓冲区、拥塞窗口等内核参数至系统默认值！（保留 Downloads 下载目录防误删）
```bash
bash <(wget -qO- [https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh](https://raw.githubusercontent.com/yimouleng/Auto-Seedbox-PT/main/auto_seedbox_pt.sh)) --purge
```

---

## ⚠️ 常见问题

**Q: 极限模式 (`-m 1`) 和均衡模式 (`-m 2`) 到底怎么选？**
**A:** - 如果你花重金租用了大内存 (>16GB)、拥有 1Gbps/10Gbps 独享带宽、配置了 NVMe 硬盘的**独立服务器**，只为了在新种发布时疯狂抢上传，请毫不犹豫选择 **`-m 1`**。
- 如果你使用的是几百块钱的 NAS、轻量云服务器（如甲骨文 ARM）、普通的 VPS，目的是挂载几百上千个种子长期保种获取魔力值，请务必选择 **`-m 2`**，否则极限参数会导致你的机器发热降频甚至死机。

**Q: 为什么我运行命令指定了 `-m 1`，脚本却提示我被降级了？**
**A:** 脚本内置了**内存防呆机制**。极限模式会将 TCP 发送/接收缓冲区推高至 1GB，如果你的服务器物理内存小于 4GB，开启极限模式极易导致系统 OOM（内存溢出）崩溃。因此脚本会自动介入并为你降级到安全稳定的均衡模式。

**Q: 为什么安装 v5 版本后，系统界面显示内存快被占满了？**
**A:** 这是正常的现代 Linux 内存机制。v5 搭配 libtorrent 2.0 强制使用内存映射 I/O（MMap），Linux 会贪婪地利用所有空闲内存作为 Page Cache 来加速 BT 数据的读写。这部分内存在系统中标记为 "Cached/Buff"，当其他程序（如数据库或面板）需要内存时，系统会自动瞬间释放，**无需任何人工干预**。

**Q: Vertex 导入备份后鉴权错误？**
**A:** 备份中的旧密码会被脚本自动覆盖为当前安装时指定的 `-u` 和 `-p`。若仍出现错误，请手动检查 `/root/vertex/data/setting.json` 中的信息。

**Q: Vertex 设置 qBittorrent 下载器时，为什么填写 `127.0.0.1` 连不上？**
**A:** Vertex 运行在 Docker 隔离环境中，容器内无法直接使用 `127.0.0.1` 访问宿主机的 qBit。应使用 Docker 网桥的网关地址（通常是 `172.17.0.1`）。不必担心，**脚本在安装完成后的高亮提示中，会直接输出为你计算好的精准内网连接 IP**。

---

## 📜 License

本项目基于 [MIT License](LICENSE) 开源，内核调优思路参考了 [jerry048/Dedicated-Seedbox](https://github.com/jerry048/Dedicated-Seedbox) 和 [vivibudong/PT-Seedbox](https://github.com/vivibudong/PT-Seedbox) 的优秀设计并进行了深度重构与场景化安全改造。您可以自由修改、分发，但请保留原作者署名。
