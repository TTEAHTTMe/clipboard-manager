#!/bin/bash

# Ubuntu服务器完整安装部署脚本
# 功能: 部署app.jar到Ubuntu服务器，包含systemd服务配置

set -e

# 配置变量
APP_NAME="app.jar"
APP_PORT="2345"
DEPLOY_DIR="/www/clip"
SERVICE_NAME="app.jar"
LOG_FILE="/var/log/app-deployment.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用sudo或root用户运行此脚本"
        exit 1
    fi
}

# 检查app.jar文件是否存在
check_app_jar() {
    if [[ ! -f "$APP_NAME" ]]; then
        error "未找到 $APP_NAME 文件，请确保文件在当前目录"
        exit 1
    fi
    log "找到 $APP_NAME 文件"
}

# 创建systemd服务文件
create_systemd_service() {
    log "创建systemd服务文件..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << 'EOF'
[Unit]
Description=Clipboard Manager Application
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/www/clip
ExecStart=/usr/bin/java -jar /www/clip/app.jar
ExecStop=/bin/kill -TERM $MAINPID
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app.jar

# 环境变量
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=SPRING_PROFILES_ACTIVE=prod

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768

[Install]
WantedBy=multi-user.target
EOF

    log "systemd服务文件创建完成"
}

# 创建管理脚本
create_management_scripts() {
    log "创建管理脚本..."
    
    # 启动脚本
    cat > "$DEPLOY_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "正在启动应用..."
sudo systemctl start app.jar
sleep 3
sudo systemctl status app.jar --no-pager -l
EOF
    chmod +x "$DEPLOY_DIR/start.sh"
    
    # 停止脚本
    cat > "$DEPLOY_DIR/stop.sh" << 'EOF'
#!/bin/bash
echo "正在停止应用..."
sudo systemctl stop app.jar
sleep 2
echo "应用已停止"
EOF
    chmod +x "$DEPLOY_DIR/stop.sh"
    
    # 重启脚本
    cat > "$DEPLOY_DIR/restart.sh" << 'EOF'
#!/bin/bash
echo "正在重启应用..."
sudo systemctl restart app.jar
sleep 3
sudo systemctl status app.jar --no-pager -l
EOF
    chmod +x "$DEPLOY_DIR/restart.sh"
    
    # 状态脚本
    cat > "$DEPLOY_DIR/status.sh" << 'EOF'
#!/bin/bash
echo "=== 应用状态 ==="
sudo systemctl status app.jar --no-pager -l
echo ""
echo "=== 端口监听 ==="
netstat -tulpn | grep :2345 || echo "端口2345未监听"
echo ""
echo "=== 进程信息 ==="
ps aux | grep app.jar | grep -v grep || echo "未找到app.jar进程"
EOF
    chmod +x "$DEPLOY_DIR/status.sh"
    
    # 日志脚本
    cat > "$DEPLOY_DIR/logs.sh" << 'EOF'
#!/bin/bash
echo "=== 最近100行日志 ==="
sudo journalctl -u app.jar -n 100 --no-pager
echo ""
echo "=== 实时日志（按Ctrl+C退出）==="
echo "sudo journalctl -u app.jar -f"
EOF
    chmod +x "$DEPLOY_DIR/logs.sh"
    
    log "管理脚本创建完成"
}

# 部署应用文件
deploy_application() {
    log "部署应用文件..."
    
    # 复制app.jar到部署目录
    cp "$APP_NAME" "$DEPLOY_DIR/"
    
    # 设置权限
    chmod 755 "$DEPLOY_DIR/$APP_NAME"
    
    log "应用文件部署完成"
}

# 启动服务
start_service() {
    log "启动服务..."
    
    # 重新加载systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable "$SERVICE_NAME"
    
    # 启动服务
    systemctl start "$SERVICE_NAME"
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log "服务启动成功！"
    else
        error "服务启动失败，请检查日志"
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    log "验证部署..."
    
    # 检查端口
    if netstat -tulpn | grep -q ":$APP_PORT "; then
        log "端口 $APP_PORT 监听正常"
    else
        warn "端口 $APP_PORT 未监听"
    fi
    
    # 检查进程
    if pgrep -f "$APP_NAME" > /dev/null; then
        log "应用进程运行正常"
    else
        error "未找到应用进程"
        exit 1
    fi
    
    # 测试HTTP访问
    sleep 3
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$APP_PORT" | grep -q "200\|302"; then
        log "HTTP访问测试通过"
    else
        warn "HTTP访问测试失败，请手动检查"
    fi
}

# 显示部署信息
show_deployment_info() {
    log "========================================"
    log "部署完成！"
    log "========================================"
    info "应用名称: $APP_NAME"
    info "部署目录: $DEPLOY_DIR"
    info "服务名称: $SERVICE_NAME"
    info "监听端口: $APP_PORT"
    info ""
    info "管理命令:"
    info "  启动:   sudo $DEPLOY_DIR/start.sh"
    info "  停止:   sudo $DEPLOY_DIR/stop.sh"
    info "  重启:   sudo $DEPLOY_DIR/restart.sh"
    info "  状态:   sudo $DEPLOY_DIR/status.sh"
    info "  日志:   sudo $DEPLOY_DIR/logs.sh"
    info ""
    info "系统命令:"
    info "  服务状态: sudo systemctl status $SERVICE_NAME"
    info "  实时日志: sudo journalctl -u $SERVICE_NAME -f"
    info ""
    info "访问地址:"
    info "  本地: http://localhost:$APP_PORT"
    info "  外部: http://$(hostname -I | awk '{print $1}'):$APP_PORT"
    log "========================================"
}

# 主函数
main() {
    log "========================================"
    log "开始部署 $APP_NAME 到Ubuntu服务器"
    log "========================================"
    
    # 检查权限
    check_root
    
    # 检查文件
    check_app_jar
    
    # 创建目录
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 创建systemd服务
    create_systemd_service
    
    # 创建管理脚本
    create_management_scripts
    
    # 部署应用
    deploy_application
    
    # 启动服务
    start_service
    
    # 验证部署
    verify_deployment
    
    # 显示信息
    show_deployment_info
}

# 错误处理
trap 'error "脚本执行失败，请检查日志: $LOG_FILE"' ERR

# 运行主函数
main "$@"