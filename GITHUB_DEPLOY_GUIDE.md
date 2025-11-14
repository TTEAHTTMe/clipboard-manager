# 🚀 GitHub自动化部署完全指南

## 📋 概述

本指南将帮助你从手动打包上传的繁琐过程中解脱出来，实现真正的**一键部署**。通过GitHub Actions，你只需要`git push`就能自动完成构建和部署。

## 🎯 为什么选择GitHub部署？

| 传统方式 | GitHub自动化部署 |
|---------|-----------------|
| 手动打包、上传、重启 | 一键push，自动完成 |
| 容易出错、版本混乱 | 版本控制清晰 |
| 需要服务器权限 | 安全的密钥管理 |
| 无法追踪部署历史 | 完整的部署记录 |

## 📦 部署方式对比

### 🚫 传统方式（你现在的方式）
```bash
# 每次修改后都要执行：
mvn clean package -DskipTests
copy target\*.jar app.jar
# 登录服务器
# 停止旧服务
# 上传新jar包
# 启动新服务
```

### ✅ GitHub自动化方式
```bash
# 只需要：
git add .
git commit -m "添加新功能"
git push origin main
# 剩下的交给GitHub Actions！
```

## 🛠️ 完整部署步骤

### 第一步：准备GitHub仓库

1. **创建GitHub仓库**
   - 访问 [github.com](https://github.com)
   - 点击右上角的 "+" → "New repository"
   - 仓库名称：`clipboard-manager`
   - 选择 "Public"（或Private）
   - 不要初始化README（我们已有）

2. **关联本地仓库到GitHub**
   ```bash
   # 添加远程仓库（替换为你的仓库地址）
   git remote add origin https://github.com/TTEAHTTMe/clipboard-manager.git
   
   # 推送到GitHub
   git push -u origin main
   ```

### 第二步：配置服务器（Ubuntu示例）

1. **安装必要软件**
   ```bash
   # 安装Java 8
   sudo apt update
   sudo apt install -y openjdk-8-jdk
   
   # 安装Maven
   sudo apt install -y maven
   
   # 安装Git
   sudo apt install -y git
   
   # 安装进程管理工具
   sudo apt install -y supervisor
   ```

2. **创建部署目录**
   ```bash
   sudo mkdir -p /www/clip
   sudo mkdir -p /www/clip/backups
   sudo mkdir -p /var/log
   
   # 设置权限
   sudo chown -R $USER:$USER /www/clip
   ```

3. **上传部署脚本**
   ```bash
   # 将 stop-and-deploy.sh 上传到服务器
   scp stop-and-deploy.sh 用户名@服务器IP:/www/clip/
   
   # 设置执行权限
   ssh 用户名@your-domain.com 'chmod +x /www/clip/stop-and-deploy.sh'
   ```

### 第三步：配置GitHub Secrets（关键步骤）

1. **生成SSH密钥对**
   ```bash
   # 在本地生成密钥（如果已有可跳过）
   ssh-keygen -t rsa -b 4096 -f github_deploy_key
   ```

2. **配置服务器SSH**
   ```bash
   # 将公钥添加到服务器的 authorized_keys
   cat github_deploy_key.pub | ssh 用户名@your-domain.com 'cat >> ~/.ssh/authorized_keys'
   ```

3. **在GitHub仓库设置Secrets**
   - 进入你的GitHub仓库
   - 点击 Settings → Secrets and variables → Actions
   - 点击 "New repository secret"
   - 添加以下secrets：

   | Secret名称 | 说明 | 示例值 |
   |------------|------|--------|
   | `DEPLOY_KEY` | SSH私钥内容 | 复制`github_deploy_key`文件的全部内容 |
   | `SERVER_HOST` | 服务器地址 | `your-domain.com` 或 `192.168.1.100` |
   | `SERVER_USER` | SSH用户名 | `ubuntu` 或 `root` |
   | `SERVER_PORT` | SSH端口（可选） | `22` |

### 第四步：推送代码触发部署

```bash
# 添加所有文件
git add .

# 提交更改
git commit -m "🚀 添加GitHub Actions自动化部署"

# 推送到GitHub
git push origin main
```

### 第五步：查看部署状态

1. **在GitHub上查看**
   - 进入你的仓库页面
   - 点击 "Actions" 标签
   - 可以看到部署进度和日志

2. **查看部署结果**
   - 绿色✅表示部署成功
   - 红色❌表示部署失败（点击查看日志）

## 📊 部署流程详解

### 🔄 自动部署触发条件
```yaml
on:
  push:
    branches: [ main, master ]  # 推送到main分支时触发
  pull_request:
    branches: [ main, master ]   # 合并PR时触发
```

### 🏗️ 构建过程
1. **代码检出** - 获取最新代码
2. **环境设置** - 安装Java 8和Maven
3. **依赖缓存** - 加速后续构建
4. **项目构建** - 执行 `mvn clean package`
5. **产物上传** - 保存构建的jar包

### 🚀 部署过程
1. **SSH连接** - 使用配置的密钥连接服务器
2. **停止旧服务** - 执行部署脚本停止旧应用
3. **上传新jar包** - 传输新的jar文件
4. **启动新服务** - 启动更新后的应用

## 🔧 高级配置

### 自定义部署脚本
你可以修改 `.github/workflows/deploy.yml` 来自定义部署行为：

```yaml
# 添加环境变量
env:
  JAVA_OPTS: "-Xms512m -Xmx1024m"
  SERVER_PORT: "2345"

# 添加健康检查
- name: 健康检查
  run: |
    sleep 10
    curl -f http://your-domain.com:2345 || exit 1
```

### 多环境部署
```yaml
# 开发环境
- name: 部署到开发环境
  if: github.ref == 'refs/heads/develop'
  env:
    SERVER_HOST: your-dev-domain.com

# 生产环境
- name: 部署到生产环境
  if: github.ref == 'refs/heads/main'
  env:
    SERVER_HOST: your-prod-domain.com
```

## 🚨 常见问题解决

### 问题1：部署失败，SSH连接超时
**解决方案：**
```bash
# 检查服务器防火墙
sudo ufw status
sudo ufw allow 22

# 检查SSH服务
sudo systemctl status sshd
```

### 问题2：端口被占用
**解决方案：**
```bash
# 使用部署脚本停止旧服务
./stop-and-deploy.sh

# 或者手动杀死进程
sudo netstat -tulpn | grep :2345
sudo kill -9 进程ID
```

### 问题3：构建失败
**解决方案：**
- 检查代码是否有编译错误
- 查看GitHub Actions详细日志
- 确保pom.xml配置正确

## 📈 最佳实践

### ✅ 提交规范
```bash
git commit -m "🐛 修复搜索功能bug"
git commit -m "✨ 添加用户登录功能"
git commit -m "📝 更新部署文档"
git commit -m "🚀 发布v1.2.0版本"
```

### ✅ 分支策略
```
main/master     # 生产环境
develop         # 开发环境
feature/xxx     # 功能开发
hotfix/xxx      # 紧急修复
```

### ✅ 版本管理
在 `pom.xml` 中管理版本：
```xml
<version>1.2.0</version>
```

## 🎉 部署成功验证

部署成功后，你可以：

1. **查看应用状态**
   ```bash
   # 检查进程
   ps aux | grep java
   
   # 检查端口
   netstat -tulpn | grep :2345
   
   # 查看日志
   tail -f /var/log/app-deployment.log
   ```

2. **访问应用**
   - 打开浏览器访问：`http://服务器IP:2345`
   - 确认功能正常

3. **查看GitHub Actions日志**
   - 进入GitHub仓库的Actions标签
   - 查看最新的部署记录

## 🚀 下一步

现在你已经实现了自动化部署，可以：

1. **添加更多功能** - 每次push都会自动部署
2. **配置监控** - 添加应用健康检查
3. **设置通知** - 部署成功/失败时发送通知
4. **扩展功能** - 添加数据库迁移、缓存清理等

---

**💡 提示：** 现在你只需要专注于开发，每次`git push`都会自动完成构建和部署，再也不用担心手动操作的繁琐和错误了！

**🎊 恭喜你！** 你已经从GitHub新手升级为自动化部署专家！🎊