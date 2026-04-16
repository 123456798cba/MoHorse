# MoHorse iOS 云端构建指南

## 方案一：Codemagic（推荐）

### 步骤 1：注册 Codemagic
1. 访问 https://codemagic.io
2. 点击 "Get started for free"
3. 使用 GitHub 账号登录（如果没有就注册一个）

### 步骤 2：上传代码到 GitHub
```bash
# 在项目目录执行
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/你的用户名/MoHorse.git
git push -u origin main
```

### 步骤 3：配置 Codemagic
1. 在 Codemagic 控制台点击 "Add application"
2. 选择 GitHub 仓库
3. 选择 Flutter 项目类型
4. 上传 `codemagic.yaml` 配置文件

### 步骤 4：配置 iOS 签名（需要 Apple Developer 账号）
1. 在 Codemagic 的 "iOS signing" 设置中：
   - 添加你的 Apple Developer 账号
   - 选择或创建证书和 Provisioning Profile
   - Bundle ID: `com.caifaxia.mohorse`

### 步骤 5：开始构建
1. 点击 "Start new build"
2. 选择 `ios-workflow`
3. 等待构建完成
4. 下载 `.ipa` 文件

---

## 方案二：GitHub Actions（免费）

### 步骤 1：创建 GitHub Actions 配置
项目已包含 `.github/workflows/build.yml`

### 步骤 2：推送到 GitHub
```bash
git push origin main
```

### 步骤 3：查看构建
1. 访问 GitHub 仓库的 Actions 页面
2. 查看构建进度
3. 构建完成后下载 Artifacts

**注意**：GitHub Actions 的 macOS runner 免费额度有限，可能需要付费账号。

---

## 方案三：Bitrise（免费额度）

### 步骤 1：注册 Bitrise
1. 访问 https://www.bitrise.io
2. 使用 GitHub 账号登录

### 步骤 2：添加应用
1. 点击 "Add new app"
2. 选择 GitHub 仓库
3. 选择 Flutter 项目

### 步骤 3：配置工作流
使用项目中的 `bitrise.yml` 配置

### 步骤 4：开始构建
点击 "Start a build"

---

## Apple Developer 账号说明

### 个人账号（$99/年）
- 可以发布到 App Store
- 可以安装到自己的设备测试

### 企业账号（$299/年）
- 可以内部分发
- 不需要 App Store 审核

### 免费账号（有限制）
- 只能安装到自己的设备
- 7 天后证书过期需要重新签名
- 不能发布到 App Store

---

## 项目配置信息

### Bundle ID
- iOS: `com.caifaxia.mohorse`
- Android: `com.caifaxia.daily_planner`

### App 名称
- MoHorse

### 支持平台
- iOS 12.0+
- Android 5.0+

---

## 常见问题

### Q: 没有Mac也能构建iOS吗？
A: 可以！使用 Codemagic、Bitrise 等云端服务，它们提供 macOS 构建环境。

### Q: 需要Apple Developer账号吗？
A: 
- 测试：可以用免费Apple ID（7天有效期）
- 发布App Store：需要付费账号（$99/年）

### Q: 构建失败怎么办？
A: 
1. 检查 Flutter 版本是否匹配
2. 检查 iOS 签名配置
3. 查看 Codemagic 的构建日志

### Q: 如何安装到iPhone测试？
A: 
1. 使用 Codemagic 构建 .ipa
2. 用 Apple Configurator 2 或 Xcode 安装
3. 或使用 TestFlight 分发

---

## 下一步

1. **注册 Codemagic 账号**
2. **上传代码到 GitHub**
3. **配置 iOS 签名**
4. **开始构建**
5. **下载并安装测试**

需要帮助可以随时问我！
