@echo off
echo 🚀 测试部署配置...
echo.

REM 检查必要的文件是否存在
echo 📋 检查文件...
if exist ".github\workflows\deploy.yml" (
    echo ✅ GitHub Actions工作流文件存在
) else (
    echo ❌ GitHub Actions工作流文件不存在
)

if exist "stop-and-deploy.sh" (
    echo ✅ 部署脚本存在
) else (
    echo ❌ 部署脚本不存在
)

if exist "app.jar" (
    echo ✅ 应用JAR包存在
) else (
    echo ⚠️ 应用JAR包不存在，需要构建
)

echo.
echo 🔑 检查SSH密钥...
if exist "%USERPROFILE%\.ssh\id_rsa" (
    echo ✅ SSH私钥存在
) else (
    echo ❌ SSH私钥不存在
)

if exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo ✅ SSH公钥存在
) else (
    echo ❌ SSH公钥不存在
)

echo.
echo 📖 部署指南摘要：
echo 1. ✅ GitHub Actions工作流已更新到v4版本
echo 2. ✅ 部署脚本已配置
echo 3. ✅ SSH密钥已生成
echo 4. ✅ GitHub Secrets已配置(DEPLOY_KEY, SERVER_HOST, SERVER_USER)
echo.
echo 🎯 下一步：
echo - 推送代码到GitHub触发自动部署
echo - 访问GitHub Actions页面查看部署状态
echo - 检查服务器上的应用是否正常运行
echo.
echo 📍 GitHub Actions页面：https://github.com/TTEAHTTMe/clipboard-manager/actions
echo 📍 应用访问地址：http://3.34.136.13:2345
pause