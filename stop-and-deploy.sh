#!/bin/bash

# Ubuntu服务器停止旧项目并部署新项目的脚本
# 作者: 自动化部署脚本
# 功能: 停止已有服务、备份旧版本、部署新版本

set -e

# 配置变量
APP_NAME="app.jar"
APP_PORT="2345"
DEPLOY_DIR="/www/clip"
SERVICE_NAME="app.jar"
BACKUP_DIR="/www/clip/backups"
LOG_FILE="/var/log/app-deployment.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用sudo或root用户运行此脚本"
        exit 1
    fi
}

# 检查端口占用情况
check_port() {
    log "检查端口 $APP_PORT 占用情况..."
    if netstat -tulpn | grep -q ":$APP_PORT "; then
        local pid=$(netstat -tulpn | grep ":$APP_PORT " | awk '{print $7}' | cut -d'/' -f1)
        warn "端口 $APP_PORT 被进程 $pid 占用"
        return 0
    else
        log "端口 $APP_PORT 未被占用"
        return 1
    fi
}

# 停止相关服务
stop_services() {
    log "开始停止相关服务..."
    
    # 停止systemd服务
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log "停止systemd服务: $SERVICE_NAME"
        systemctl stop "$SERVICE_NAME"
        systemctl disable "$SERVICE_NAME" 2>/dev/null || true
        log "systemd服务已停止"
    fi
    
    # 停止其他可能的Java进程
    local java_pids=$(pgrep -f "java.*$APP_PORT" || true)
    if [[ -n "$java_pids" ]]; then
        warn "发现其他Java进程监听端口 $APP_PORT: $java_pids"
        log "正在停止这些进程..."
        kill -TERM $java_pids 2>/dev/null || true
        sleep 3
        # 如果还有进程，强制杀死
        local remaining_pids=$(pgrep -f "java.*$APP_PORT" || true)
        if [[ -n "$remaining_pids" ]]; then
            warn "仍有进程存活，强制杀死: $remaining_pids"
            kill -KILL $remaining_pids 2>/dev/null || true
        fi
    fi
    
    # 停止clipboard相关服务（兼容旧版本）
    for service in clipboard clipboard-manager clip; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log "停止服务: $service"
            systemctl stop "$service"
            systemctl disable "$service" 2>/dev/null || true
        fi
    done
    
    log "所有相关服务已停止"
}

# 创建备份
create_backup() {
    log "创建备份..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 备份旧版本（如果存在）
    if [[ -f "$DEPLOY_DIR/$APP_NAME" ]]; then
        local backup_name="app_backup_$(date '+%Y%m%d_%H%M%S').jar"
        log "备份旧版本到: $BACKUP_DIR/$backup_name"
        cp "$DEPLOY_DIR/$APP_NAME" "$BACKUP_DIR/$backup_name"
        
        # 保留最近5个备份
        ls -t "$BACKUP_DIR"/app_backup_*.jar 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
        
        log "备份完成"
    else
        log "未找到旧版本，跳过备份"
    fi
}

# 清理旧文件
cleanup_old_files() {
    log "清理旧文件..."
    
    # 清理旧的systemd服务文件
    local old_services=(
        "/etc/systemd/system/clipboard.service"
        "/etc/systemd/system/clipboard-manager.service"
        "/etc/systemd/system/clip.service"
        "/etc/systemd/system/app.jar.service"
    )
    
    for service in "${old_services[@]}"; do
        if [[ -f "$service" ]]; then
            log "删除旧服务文件: $service"
            rm -f "$service"
        fi
    done
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 清理旧的部署目录
    if [[ -d "/www/clipboard" ]]; then
        warn "发现旧目录 /www/clipboard，正在清理..."
        rm -rf "/www/clipboard"
    fi
    
    log "旧文件清理完成"
}

# 创建部署目录结构
setup_directories() {
    log "创建部署目录结构..."
    
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "目录结构创建完成"
}

# 主函数
main() {
    log "========================================"
    log "开始停止旧项目并部署新项目"
    log "========================================"
    
    # 检查权限
    check_root
    
    # 检查端口
    check_port
    
    # 停止服务
    stop_services
    
    # 创建备份
    create_backup
    
    # 清理旧文件
    cleanup_old_files
    
    # 创建目录结构
    setup_directories
    
    log "========================================"
    log "旧项目停止和清理完成！"
    log "可以安全部署新项目了"
    log "========================================"
}

# 错误处理
trap 'error "脚本执行失败，请检查日志: $LOG_FILE"' ERR

# 运行主函数
main "$@"