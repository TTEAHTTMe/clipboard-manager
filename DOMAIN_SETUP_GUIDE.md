# 🌐 域名配置指南

## 📋 配置步骤

### 1. 域名解析设置
登录你的域名服务商控制台，添加以下DNS记录：

```
类型: A记录
主机记录: @ 或 www 或 clip
记录值: 3.34.136.13  (你的服务器IP)
TTL: 600
```

### 2. GitHub Secrets 更新

在GitHub仓库的Settings > Secrets中更新：

```
SERVER_HOST=your-domain.com
```

### 3. 配置文件更新

更新以下文件中的域名：

#### test-deployment.bat
```batch
echo 📍 应用访问地址：http://your-domain.com:2345
```

#### .github/workflows/deploy.yml
```yaml
echo "- 访问地址：http://your-domain.com:2345"
```

### 4. 可选：配置子域名

如果你想使用子域名，如 `clip.your-domain.com`：

```
类型: A记录
主机记录: clip
记录值: 3.34.136.13
TTL: 600
```

然后在Secrets中设置：
```
SERVER_HOST=clip.your-domain.com
```

### 5. 验证域名解析

等待DNS生效后（通常5-30分钟），测试访问：

```bash
# 测试域名解析
ping your-domain.com

# 测试应用访问
curl http://your-domain.com:2345
```

### 6. 更新部署脚本（可选）

如果你想让部署脚本也使用域名，可以修改 `stop-and-deploy.sh`：

```bash
# 在文件开头添加
DOMAIN="your-domain.com"
PORT="2345"

# 在健康检查中使用域名
curl -f http://${DOMAIN}:${PORT}/health || echo "健康检查失败"
```

## 🔒 安全建议

1. **使用HTTPS**：考虑配置SSL证书
2. **防火墙配置**：只开放必要的端口
3. **定期更新**：保持域名解析和服务器安全

## 🚀 完成

配置完成后，你的应用将通过域名访问：
```
http://your-domain.com:2345
```

记得在GitHub Secrets中更新 `SERVER_HOST` 为你的实际域名！