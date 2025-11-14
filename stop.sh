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

# 检查是否有运行中的服务
if pgrep -f "java -jar ${JAR_FILE}" > /dev/null; then
    PID=$(pgrep -f "java -jar ${JAR_FILE}")
    echo -e "${YELLOW}发现运行中的服务 (PID: ${PID})${NC}"
    
    echo -e "${BLUE}正在停止服务...${NC}"
    
    # 先尝试正常停止
    pkill -f "java -jar ${JAR_FILE}" 2>/dev/null || true
    
    # 等待最多10秒
    for i in {1..10}; do
        if ! pgrep -f "java -jar ${JAR_FILE}" > /dev/null; then
            echo -e "${GREEN}✅ 服务已成功停止${NC}"
            exit 0
        fi
        sleep 1
    done
    
    # 如果还在运行，强制停止
    echo -e "${YELLOW}强制停止服务...${NC}"
    pkill -9 -f "java -jar ${JAR_FILE}" 2>/dev/null || true
    
    # 最终检查
    if ! pgrep -f "java -jar ${JAR_FILE}" > /dev/null; then
        echo -e "${GREEN}✅ 服务已强制停止${NC}"
    else
        echo -e "${RED}❌ 无法停止服务，请手动处理${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}ℹ️  没有发现运行中的服务${NC}"
fi

echo -e "${BLUE}=== 停止完成 ===${NC}"