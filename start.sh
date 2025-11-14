#!/bin/bash

# 剪贴板管理器启动脚本
# 创建者：部署系统
# 功能：安全启动应用并处理各种情况

set -e  # 遇到错误立即退出

# 设置变量
APP_NAME="剪贴板管理器"
JAR_FILE="app.jar"
LOG_FILE="app.log"
DB_FILE="clipboard.db"
PORT="2345"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ${APP_NAME} 启动脚本 ===${NC}"

# 函数：检查端口是否被占用
check_port() {
    if command -v netstat > /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":${PORT} "; then
            echo -e "${YELLOW}⚠️  端口 ${PORT} 已被占用${NC}"
            return 1
        fi
    elif command -v ss > /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":${PORT} "; then
            echo -e "${YELLOW}⚠️  端口 ${PORT} 已被占用${NC}"
            return 1
        fi
    else
        # 尝试使用lsof作为备选方案
        if command -v lsof > /dev/null && lsof -i :${PORT} > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  端口 ${PORT} 已被占用${NC}"
            return 1
        fi
    fi
    echo -e "${GREEN}✅ 端口 ${PORT} 可用${NC}"
    return 0
}

# 函数：获取占用端口的进程信息
get_port_process() {
    local port=$1
    if command -v lsof > /dev/null; then
        lsof -i :${port} 2>/dev/null | grep -v "COMMAND" | head -1
    elif command -v netstat > /dev/null; then
        netstat -tulnp 2>/dev/null | grep ":${port} " | head -1
    elif command -v ss > /dev/null; then
        ss -tulnp 2>/dev/null | grep ":${port} " | head -1
    fi
}

# 函数：处理端口冲突
handle_port_conflict() {
    echo -e "${YELLOW}=== 处理端口冲突 ===${NC}"
    
    # 获取占用端口的进程信息
    PROCESS_INFO=$(get_port_process ${PORT})
    if [ -n "$PROCESS_INFO" ]; then
        echo -e "${YELLOW}占用端口的进程信息：${NC}"
        echo "$PROCESS_INFO"
        
        # 检查是否是我们的Java应用
        if echo "$PROCESS_INFO" | grep -q "java.*app.jar"; then
            echo -e "${YELLOW}发现旧的应用实例，将停止它${NC}"
            stop_old_service
            sleep 3
            
            # 再次检查端口
            if check_port; then
                return 0
            fi
        else
            echo -e "${RED}❌ 端口 ${PORT} 被其他应用占用${NC}"
            echo -e "${RED}请手动处理端口冲突或修改应用端口配置${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 无法获取占用端口的进程信息${NC}"
        return 1
    fi
}

# 函数：停止旧服务
stop_old_service() {
    echo -e "${BLUE}=== 停止旧服务 ===${NC}"
    if pgrep -f "java -jar ${JAR_FILE}" > /dev/null; then
        echo -e "${YELLOW}正在停止旧服务...${NC}"
        pkill -f "java -jar ${JAR_FILE}" 2>/dev/null || true
        sleep 3
        
        # 确保进程已停止
        if pgrep -f "java -jar ${JAR_FILE}" > /dev/null; then
            echo -e "${RED}❌ 强制停止旧服务${NC}"
            pkill -9 -f "java -jar ${JAR_FILE}" 2>/dev/null || true
            sleep 2
        fi
        
        echo -e "${GREEN}✅ 旧服务已停止${NC}"
    else
        echo -e "${GREEN}ℹ️  无旧服务需要停止${NC}"
    fi
}

# 函数：检查环境
check_environment() {
    echo -e "${BLUE}=== 环境检查 ===${NC}"
    
    # 检查Java
    if command -v java > /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        echo -e "${GREEN}✅ Java已安装: ${JAVA_VERSION}${NC}"
    else
        echo -e "${RED}❌ Java未安装${NC}"
        exit 1
    fi
    
    # 检查jar文件
    if [ -f "${JAR_FILE}" ]; then
        JAR_SIZE=$(ls -lh ${JAR_FILE} | awk '{print $5}')
        echo -e "${GREEN}✅ JAR文件存在: ${JAR_SIZE}${NC}"
    else
        echo -e "${RED}❌ JAR文件不存在: ${JAR_FILE}${NC}"
        exit 1
    fi
    
    # 检查数据库
    if [ -f "${DB_FILE}" ]; then
        DB_SIZE=$(ls -lh ${DB_FILE} | awk '{print $5}')
        echo -e "${GREEN}✅ 数据库文件存在: ${DB_SIZE}${NC}"
    else
        echo -e "${YELLOW}⚠️  数据库文件不存在，将自动创建${NC}"
    fi
    
    # 检查端口 - 如果端口被占用，尝试处理冲突
    if ! check_port; then
        if ! handle_port_conflict; then
            exit 1
        fi
    fi
}

# 函数：启动服务
start_service() {
    echo -e "${BLUE}=== 启动新服务 ===${NC}"
    
    # 备份旧日志
    if [ -f "${LOG_FILE}" ]; then
        mv "${LOG_FILE}" "${LOG_FILE}.$(date +%Y%m%d_%H%M%S).bak" 2>/dev/null || true
        echo -e "${GREEN}✅ 已备份旧日志${NC}"
    fi
    
    # 启动应用
    echo -e "${BLUE}正在启动应用...${NC}"
    nohup java -jar ${JAR_FILE} > ${LOG_FILE} 2>&1 &
    APP_PID=$!
    
    echo -e "${BLUE}等待应用启动...${NC}"
    sleep 5
    
    # 检查进程是否存在
    if ps -p $APP_PID > /dev/null; then
        echo -e "${GREEN}✅ 应用启动成功 (PID: ${APP_PID})${NC}"
        
        # 等待HTTP服务就绪
        echo -e "${BLUE}检查HTTP服务...${NC}"
        for i in {1..10}; do
            if curl -s http://localhost:${PORT}/ > /dev/null; then
                echo -e "${GREEN}✅ HTTP服务正常运行${NC}"
                return 0
            fi
            sleep 2
        done
        
        echo -e "${YELLOW}⚠️  HTTP服务启动超时，但进程正在运行${NC}"
        return 0
    else
        echo -e "${RED}❌ 应用启动失败${NC}"
        echo -e "${RED}=== 错误日志 ===${NC}"
        tail -20 ${LOG_FILE} 2>/dev/null || echo "无法读取日志文件"
        return 1
    fi
}

# 函数：显示状态
show_status() {
    echo -e "${BLUE}=== 服务状态 ===${NC}"
    
    if pgrep -f "java -jar ${JAR_FILE}" > /dev/null; then
        PID=$(pgrep -f "java -jar ${JAR_FILE}")
        echo -e "${GREEN}✅ 服务运行中 (PID: ${PID})${NC}"
        echo -e "${GREEN}🌐 访问地址: http://localhost:${PORT}${NC}"
        
        # 显示日志中的关键信息
        if [ -f "${LOG_FILE}" ]; then
            echo -e "${BLUE}=== 启动日志 ===${NC}"
            tail -5 ${LOG_FILE}
        fi
    else
        echo -e "${RED}❌ 服务未运行${NC}"
    fi
}

# 主函数
main() {
    # 检查是否在正确目录
    if [ ! -f "${JAR_FILE}" ]; then
        echo -e "${RED}❌ 请在包含 ${JAR_FILE} 的目录中运行此脚本${NC}"
        exit 1
    fi
    
    # 执行步骤
    check_environment
    stop_old_service
    start_service && show_status || exit 1
    
    echo -e "${BLUE}=== 部署完成 ===${NC}"
    echo -e "${GREEN}🎉 ${APP_NAME} 启动成功！${NC}"
    echo -e "${GREEN}🌐 请访问: http://localhost:${PORT}${NC}"
}

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi