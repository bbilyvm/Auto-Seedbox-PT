#!/bin/bash

################################################################################
# Auto-Seedbox-PT (ASP) v1.0 
# qBittorrent  + libtorrent  + Vertex + FileBrowser 一键安装脚本
# 系统要求: Debian 10+ / Ubuntu 20.04+ (x86_64 / aarch64)
# 参数说明:
#   -u : 用户名
#   -p : 密码
#   -c : qBittorrent 缓存大小 (MiB)
#   -q : qBittorrent 版本 (4.3.9)
#   -v : 安装 Vertex
#   -f : 安装 FileBrowser
#   -t : 启用系统内核优化（强烈推荐）
#   -o : 自定义端口 (会提示输入)
#   -d : Vertex data 目录 ZIP 下载链接 (可选)
#   -k : Vertex data ZIP 解压密码 (可选)
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ================= 0. 全局变量 =================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

QB_WEB_PORT=8080; QB_BT_PORT=20000; VX_PORT=3000; FB_PORT=8081
QB_USER=""; QB_PASS=""; QB_CACHE=1024; QB_VER_REQ="4.3.9" 
DO_VX=false; DO_FB=false; DO_TUNE=false; CUSTOM_PORT=false 
VX_RESTORE_URL=""; VX_ZIP_PASS=""; INSTALLED_MAJOR_VER="4"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

URL_V4_AMD64="https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.3.9_v1.2.15/x86_64-qbittorrent-nox"
URL_V4_ARM64="https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.3.9_v1.2.15/aarch64-qbittorrent-nox"

# ================= 1. 基础工具函数 =================

log_info() { echo -e "${GREEN}[INFO] $1${NC}" >&2; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}" >&2; }
log_err() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }

check_root() { if [[ $EUID -ne 0 ]]; then log_err "必须使用 root 权限运行此脚本"; fi; }

check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then log_err "仅支持 Debian/Ubuntu"; fi
    else
        log_err "无法检测系统类型"; fi
}

is_port_free() {
    local port=$1
    if command -v ss >/dev/null; then ! ss -tuln | grep -q ":$port "; else ! netstat -tuln 2>/dev/null | grep -q ":$port "; fi
}

get_input_port() {
    local prompt=$1; local default=$2; local port
    while true; do
        read -p "$prompt [默认 $default]: " port; port=${port:-$default}
        if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then log_warn "输入不合法"; continue; fi
        if ! is_port_free "$port"; then log_warn "端口 $port 已被占用"; continue; fi
        echo "$port"; break
    done
}

# ================= 2. 安装核心逻辑 =================

install_qbit() {
    local home_base=$([[ "$QB_USER" == "root" ]] && echo "/root" || echo "/home/$QB_USER")
    local url=""

    # 版本识别
    if [[ "$QB_VER_REQ" == "4" || "$QB_VER_REQ" == "4.3.9" ]]; then
        log_info "锁定经典版本: 4.3.9 (Static)"
        [[ "$(uname -m)" == "x86_64" ]] && url="$URL_V4_AMD64" || url="$URL_V4_ARM64"
    else
        log_info "正在搜索版本 $QB_VER_REQ ..."
        local api="https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases"
        local tag=$(curl -sL "$api" | jq -r --arg v "$QB_VER_REQ" '.[].tag_name | select(contains($v))' | head -n 1)
        [[ -z "$tag" || "$tag" == "null" ]] && tag="release-4.3.9_v1.2.15"
        url="https://github.com/userdocs/qbittorrent-nox-static/releases/download/${tag}/$([[ "$(uname -m)" == "aarch64" ]] && echo "aarch64" || echo "x86_64")-qbittorrent-nox"
        [[ "$tag" =~ release-5 ]] && INSTALLED_MAJOR_VER="5"
    fi

    wget -q --show-progress -O /usr/bin/qbittorrent-nox "$url"
    chmod +x /usr/bin/qbittorrent-nox

    # 用户处理
    if ! id "$QB_USER" &>/dev/null; then
        log_info "创建新用户 $QB_USER ..."
        useradd -m -s /bin/bash "$QB_USER" || (getent group "$QB_USER" >/dev/null && useradd -m -s /bin/bash -g "$QB_USER" "$QB_USER")
    fi

    mkdir -p "$home_base/.config/qBittorrent" "$home_base/Downloads"
    
    # 磁盘检测
    local is_ssd=0
    local dev_source=$(df --output=source "$home_base" | tail -1)
    if [[ "$dev_source" == "/dev/"* ]]; then
        local disk_pname=$(lsblk -nd -o PKNAME "$dev_source" 2>/dev/null || echo "${dev_source##*/}" | sed 's/[0-9]*$//')
        [[ -f "/sys/block/$disk_pname/queue/rotational" && "$(cat /sys/block/$disk_pname/queue/rotational)" == "0" ]] && is_ssd=1
    fi

    local pass_hash=$(python3 -c "import sys, base64, hashlib, os; dk = hashlib.pbkdf2_hmac('sha512', sys.argv[1].encode(), os.urandom(16), 100000); print(f'@ByteArray({base64.b64encode(os.urandom(16)).decode()}:{base64.b64encode(dk).decode()})')" "$QB_PASS")

    if [[ "$INSTALLED_MAJOR_VER" == "5" ]]; then
        log_info "应用 v5 (MMap) 优化策略..."
        cat > "$home_base/.config/qBittorrent/qBittorrent.conf" << EOF
[BitTorrent]
Session\DefaultSavePath=$home_base/Downloads/
Session\AsyncIOThreadsCount=0
Session\SendBufferWatermark=3072
Session\QueueingSystemEnabled=false
Session\IgnoreLimitsOnLocalNetwork=true
Session\SuggestMode=true
[Preferences]
Connection\PortRangeMin=$QB_BT_PORT
Downloads\DiskWriteCacheSize=-1
WebUI\Password_PBKDF2="$pass_hash"
WebUI\Port=$QB_WEB_PORT
WebUI\Username=$QB_USER
EOF
    else
        log_info "应用 v4 (UserCache) 优化策略 (SSD: $is_ssd)..."
        local aio=4; local buf=10240
        [[ "$is_ssd" -eq 1 ]] && { aio=12; buf=20480; }
        cat > "$home_base/.config/qBittorrent/qBittorrent.conf" << EOF
[BitTorrent]
Session\DefaultSavePath=$home_base/Downloads/
Session\AsyncIOThreadsCount=$aio
Session\SendBufferWatermark=$buf
Session\QueueingSystemEnabled=false
Session\IgnoreLimitsOnLocalNetwork=true
[Preferences]
Connection\PortRangeMin=$QB_BT_PORT
Downloads\DiskWriteCacheSize=$QB_CACHE
WebUI\Password_PBKDF2="$pass_hash"
WebUI\Port=$QB_WEB_PORT
WebUI\Username=$QB_USER
EOF
    fi
    chown -R "$QB_USER:$QB_USER" "$home_base"

    cat > /etc/systemd/system/qbittorrent-nox@.service << EOF
[Unit]
Description=qBittorrent Service for %i
After=network.target
[Service]
Type=simple
User=%i
Group=%i
ExecStart=/usr/bin/qbittorrent-nox --webui-port=$QB_WEB_PORT
Restart=on-failure
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "qbittorrent-nox@$QB_USER" >/dev/null 2>&1
    systemctl restart "qbittorrent-nox@$QB_USER"
}

# ================= 3. Docker & 优化 =================

install_apps() {
    if ! command -v docker >/dev/null; then 
        log_info "正在安装 Docker..."
        curl -fsSL https://get.docker.com | bash >/dev/null 2>&1
        systemctl enable docker; systemctl start docker
    fi
    local uid=$(id -u "$QB_USER"); local gid=$(id -g "$QB_USER")
    local home_base=$([[ "$QB_USER" == "root" ]] && echo "/root" || echo "/home/$QB_USER")

    if [[ "$DO_VX" == "true" ]]; then
        log_info "部署 Vertex..."
        mkdir -p "$home_base/vertex"
        if [[ -n "$VX_RESTORE_URL" ]]; then
            wget -q -O "$TEMP_DIR/v.zip" "$VX_RESTORE_URL"
            local u_cmd="unzip -o"
            [[ -n "$VX_ZIP_PASS" ]] && u_cmd="unzip -o -P $VX_ZIP_PASS"
            $u_cmd "$TEMP_DIR/v.zip" -d "$home_base/vertex/" >/dev/null
            find "$home_base/vertex/data/client" -name "*.json" -print0 2>/dev/null | xargs -0 sed -i "s/\"port\": [0-9]*/\"port\": $QB_WEB_PORT/g" 2>/dev/null || true
        fi
        chown -R "$uid:$gid" "$home_base/vertex"
        docker rm -f vertex &>/dev/null || true
        docker run -d --name vertex --restart unless-stopped -p $VX_PORT:3000 -v "$home_base/vertex":/vertex -e TZ=Asia/Shanghai -e PUID=$uid -e PGID=$gid lswl/vertex:stable >/dev/null
    fi

    if [[ "$DO_FB" == "true" ]]; then
        log_info "部署 FileBrowser..."
        touch "$home_base/fb.db" && chown "$uid:$gid" "$home_base/fb.db"
        docker rm -f filebrowser &>/dev/null || true
        docker run -d --name filebrowser --restart unless-stopped -v "$home_base":/srv -v "$home_base/fb.db":/database/filebrowser.db -p $FB_PORT:80 -u $uid:$gid filebrowser/filebrowser:latest >/dev/null
    fi
}

sys_tune() {
    log_info "应用内核优化 (BBR + 网络栈)..."
    [ ! -f /etc/sysctl.conf.bak ] && cp /etc/sysctl.conf /etc/sysctl.conf.bak
    cat > /etc/sysctl.d/99-ptbox.conf << EOF
fs.file-max = 2097152
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
    sysctl --system >/dev/null 2>&1
}

# ================= 4. 主程序入口 =================

if [[ "${1:-}" == "--uninstall" || "${1:-}" == "--purge" ]]; then 
    log_err "请参考文档手动删除或运行旧版卸载逻辑"; fi

while getopts "u:p:c:q:vfd:k:toh" opt; do
    case $opt in
        u) QB_USER=$OPTARG ;; p) QB_PASS=$OPTARG ;; c) QB_CACHE=$OPTARG ;;
        q) QB_VER_REQ=$OPTARG ;; v) DO_VX=true ;; f) DO_FB=true ;;
        d) VX_RESTORE_URL=$OPTARG ;; k) VX_ZIP_PASS=$OPTARG ;; t) DO_TUNE=true ;;
        o) CUSTOM_PORT=true ;; *) exit 1 ;;
    esac
done

check_root; check_os
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update && apt-get -qq install -y curl wget jq unzip python3 net-tools >/dev/null

[[ -z "$QB_USER" ]] && read -p "请输入运行用户名 (root 或 现有用户): " QB_USER
[[ -z "$QB_PASS" ]] && { echo -n "请设置密码 (≥12位): "; read -s QB_PASS; echo ""; }
while [[ ${#QB_PASS} -lt 12 ]]; do echo -n "密码过短! 请输入至少 12 位: "; read -s QB_PASS; echo ""; done

if [[ "$CUSTOM_PORT" == "true" ]]; then
    log_info "--- 进入交互式端口设置 ---"
    QB_WEB_PORT=$(get_input_port "qBit WebUI" 8080)
    QB_BT_PORT=$(get_input_port "qBit BT监听" 20000)
    [[ "$DO_VX" == "true" ]] && VX_PORT=$(get_input_port "Vertex" 3000)
    [[ "$DO_FB" == "true" ]] && FB_PORT=$(get_input_port "FileBrowser" 8081)
else
    if ! is_port_free "$QB_WEB_PORT" || ! is_port_free "$QB_BT_PORT"; then
        log_err "默认端口被占用，请使用 -o 参数运行以自定义端口。"; fi
fi

install_qbit
[[ "$DO_VX" == "true" || "$DO_FB" == "true" ]] && install_apps
[[ "$DO_TUNE" == "true" ]] && sys_tune

# ================= 5. 完成汇总输出 =================

PUB_IP=$(curl -s --max-time 3 https://api.ipify.org || echo "ServerIP")

echo ""
echo "========================================================"
echo -e "${GREEN}   Auto-Seedbox-PT 安装成功! (v${INSTALLED_MAJOR_VER} 内核)${NC}"
echo "========================================================"
echo -e "运行用户: ${YELLOW}$QB_USER${NC}"
echo -e "Web 密码: ${YELLOW}(您设置的密码)${NC}"
echo "--------------------------------------------------------"
echo -e "🧩 qBittorrent: http://$PUB_IP:$QB_WEB_PORT"
[[ "$DO_VX" == "true" ]] && echo -e "🌐 Vertex:      http://$PUB_IP:$VX_PORT"
[[ "$DO_FB" == "true" ]] && echo -e "📁 FileBrowser: http://$IP:$FB_PORT"
echo "========================================================"

if [[ "$DO_TUNE" == "true" ]]; then 
    echo -e "${YELLOW}提示: 已应用内核优化，建议执行 reboot 重启服务器以生效${NC}"
fi
