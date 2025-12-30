## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against the behavior of installing Android System SafetyCore and Android System Key Verifier by Google quietly / 一个对抗 Google 静默安装 SafetyCore 和 Key Verifier 这一行为的 Magisk 模块

### 1.2.0

- Fix issue #3
> Optimize the uninstallation process for legacy placeholder apps on devices with encrypted data partitions
> For devices with encrypted data partitions, always wait until the user has unlocked the screen for the first time before uninstalling the app, in order to fix the exit-status-20 issue that occurs during uninstallation on devices whose data partition has not yet been decrypted.
- Add back /META-INF to module zip for compatibility
---
- 修复问题 #3
> 优化处理 data 分区加密的设备中的旧版本占位符 APP 的卸载流程
> 对于 data 分区加密设备，在卸载 APP 前始终等待，直到用户第一次解锁屏幕后再卸载 APP 以修复在未解密 Data 分区的设备的卸载过程中退出状态码20的问题
- 将 /META-INF 再度添加至模块 zip 以提升兼容性
