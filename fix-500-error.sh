#!/bin/bash

echo "🔧 开始修复500错误..."

# 1. 检查应用是否在运行
echo "📊 检查应用状态..."
cd /www/clip

# 2. 检查日志文件
if [ -f app.log ]; then
    echo "📋 最近10行日志:"
    tail -10 app.log
else
    echo "⚠️ 日志文件不存在"
fi

# 3. 检查端口占用
echo "🔍 检查端口2345状态..."
netstat -tlnp | grep :2345 || echo "端口2345未监听"

# 4. 检查数据库文件
if [ -f clipboard.db ]; then
    echo "✅ 数据库文件存在"
    ls -la clipboard.db
else
    echo "❌ 数据库文件不存在"
fi

# 5. 检查jar文件
if [ -f app.jar ]; then
    echo "✅ JAR文件存在"
    ls -la app.jar
else
    echo "❌ JAR文件不存在"
fi

# 6. 停止现有服务
echo "🛑 停止现有服务..."
pkill -f "java -jar app.jar" 2>/dev/null || echo "无旧进程需要停止"

# 7. 清理并重启
echo "🔄 重启应用..."
nohup java -jar app.jar > app.log 2>&1 &
PID=$!
echo "新进程PID: $PID"

# 8. 等待启动并验证
sleep 5
if ps -p $PID > /dev/null; then
    echo "✅ 应用启动成功"
    
    # 9. 测试HTTP响应
    sleep 3
    curl -s -o /dev/null -w "%{http_code}" http://localhost:2345/ || echo "连接失败"
else
    echo "❌ 应用启动失败"
    echo "📋 查看详细日志:"
    tail -20 app.log
fi

echo "🔧 修复完成！"