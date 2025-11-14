#!/bin/bash

# 剪贴板管理器停止脚本
# 功能：安全停止应用服务

set -e

# 设置变量
JAR_FILE="app.jar"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 停止剪贴板管理器服务 ===${NC}"

# 函数：获取准确的Java进程PID
get_java_pid() {
    # 使用多种方法查找Java进程
    local pid=""
    
    # 方法1：通过JAR文件名查找
    if command -v ps > /dev/null; then
        pid=$(ps aux | grep "java.*${JAR_FILE}" | grep -v grep | awk '{print $2}' | head -1)
    fi
    
    # 方法2：通过端口查找（如果可用）
    if [ -z "$pid" ] && command -v lsof > /dev/null; then
        pid=$(lsof -i :2345 2>/dev/null | grep java | awk '{print $2}' | head -1)
    fi
    
    # 方法3：使用pgrep作为备选
    if [ -z "$pid" ]; then
        pid=$(pgrep -f "java.*${JAR_FILE}" | head -1)
    fi
    
    echo "$pid"
}

# 函数：检查进程是否存在
check_process() {
    local pid=$1
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 获取Java进程PID
JAVA_PID=$(get_java_pid)

# 检查是否有运行中的服务
if [ -n "$JAVA_PID" ]; then
    echo -e "${YELLOW}发现运行中的服务 (PID: ${JAVA_PID})${NC}"
    echo -e "${BLUE}进程详情：${NC}"
    ps -p "$JAVA_PID" -o pid,ppid,cmd 2>/dev/null || echo "无法获取进程详情"
    
    echo -e "${BLUE}正在停止服务...${NC}"
    
    # 先尝试正常停止（发送SIGTERM）
    echo -e "${YELLOW}发送停止信号...${NC}"
    if kill "$JAVA_PID" 2>/dev/null; then
        echo -e "${YELLOW}已发送停止信号，等待服务停止...${NC}"
    else
        echo -e "${YELLOW}无法发送停止信号，尝试强制停止...${NC}"
    fi
    
    # 等待最多15秒
    for i in {1..15}; do
        if ! check_process "$JAVA_PID"; then
            echo -e "${GREEN}✅ 服务已成功停止${NC}"
            exit 0
        fi
        echo -e "${YELLOW}等待服务停止 (${i}/15)...${NC}"
        sleep 1
    done
    
    # 如果还在运行，强制停止（发送SIGKILL）
    echo -e "${YELLOW}强制停止服务 (PID: ${JAVA_PID})...${NC}"
    if kill -9 "$JAVA_PID" 2>/dev/null; then
        sleep 2
        
        # 最终检查
        if ! check_process "$JAVA_PID"; then
            echo -e "${GREEN}✅ 服务已强制停止${NC}"
            exit 0
        fi
    fi
    
    echo -e "${RED}❌ 无法停止服务，请手动处理${NC}"
    exit 1
else
    echo -e "${GREEN}ℹ️  没有发现运行中的服务${NC}"
fi

echo -e "${BLUE}=== 停止完成 ===${NC}"

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit 0
fi