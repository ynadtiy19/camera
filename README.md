## 🤖 Android 打包指南 (分 CPU 架构)

为了优化应用体积并提高安全性，生产环境建议开启 **分 CPU 架构打包** 与 **Dart 代码混淆**。

### 核心打包命令

```bash
flutter build apk --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```

### 📋 参数详解

| 参数名 | 作用描述 | 优势 / 目的 |
| :--- | :--- | :--- |
| `--release` | 编译为生产环境 Release 模式 | 开启 AOT 编译，提升运行性能 |
| `--split-per-abi` | **按 CPU 架构拆分 APK** | **显著减小安装包体积**（单个 APK 约减少 50%+） |
| `--obfuscate` | 开启 Dart 代码混淆 | 保护核心代码逻辑，防止被反编译 |
| `--split-debug-info` | 剥离并独立保存调试符号表 (`.symbols`) | 减小 APK 体积，同时保留崩溃还原凭证 |

### 📂 输出产物路径

命令执行成功后，产物将生成在以下目录：

```text
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk     # 👈 主流安卓机型 (推荐测试与分发)
├── app-armeabi-v7a-release.apk   # 👈 老旧安卓机型
└── app-x86_64-release.apk        # 👈 安卓模拟器 / 部分 Intel 芯片设备
```

> **符号表备份路径**：`build/app/outputs/symbols/`  
> ⚠️ **注意**：请妥善保存编译生成的 `.symbols` 符号表文件，线上发生 Crash 时需依赖此文件还原堆栈。

---

## 🍎 iOS 打包指南 (IPA 生成)

iOS 构建需要确保已在 Xcode 中正确配置了 **Apple Developer 团队签名** 及 **Provisioning Profile**。

### 核心打包命令

```bash
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/ios/outputs/symbols
```

### 📋 构建流程说明

1. **导出 `.xcarchive` 与 `.ipa`**：上述命令会自动完成编译并生成标准的 App Store 导出包。
2. **产物目录**：
   ```text
   build/ios/ipa/
   └── Camera.ipa                 # 👈 最终提交审核或分发的 IPA 安装包
   ```
3. **上架部署**：
    - 使用 **Transporter** 应用将 `Camera.ipa` 拖入并交付至 App Store Connect。
    - 或使用 Xcode Organizer 进行归档上传。

---

## 🔒 代码混淆与符号表还原

由于打包时开启了 `--obfuscate` 参数，线上的错误日志（Crash Stack Trace）将会是混淆后的随机字符串。

### 如何还原报错堆栈？

使用 Flutter 官方自带的 `symbolize` 命令，结合打包时保存的符号表进行解码还原：

#### Android 堆栈还原示例：
```bash
flutter symbolize \
  --input=crash_log.txt \
  --data=build/app/outputs/symbols/app.android-arm64.symbols
```

#### iOS 堆栈还原示例：
```bash
flutter symbolize \
  --input=crash_log.txt \
  --data=build/ios/outputs/symbols/Runner.app.dSYM
```

---

## ❓ 常见问题排查

<details>
<summary><b>1. 打包提示 KeyStore 未签名 (Android)</b></summary>

请检查 `android/app/build.gradle` 中的 `signingConfigs` 配置，确保已配置正式的证书秘钥：
```groovy
signingConfigs {
    release {
        keyAlias 'your-key-alias'
        keyPassword 'your-key-password'
        storeFile file('your-keystore-path.jks')
        storePassword 'your-store-password'
    }
}
```
</details>

<details>
<summary><b>2. iOS 编译报 Pod 依赖错误</b></summary>

可以尝试重新重置 CocoaPods 依赖环境：
```bash
cd ios
pod deintegrate
pod install
cd ..
```
</details>

---
