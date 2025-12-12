## Anti SafetyCore | 反 SafetyCore
A Magisk module to fight against the behavior of installing Android System SafetyCore and Android System Key Verifier by Google quietly | 一个对抗 Google 静默安装 SafetyCore 和 Key Verifier 这一行为的 Magisk 模块

### 1.2.0-RC1

- Add back /META-INF to module zip for compatibility (I won't remove this anymore...troublesome...)
- Add verifying process for scripts in /META-INF
- Add back logging function for investigation
- Try to deal with uninstalling old APPs process for data partition encrypted devices
> Wait for screen unlock before uninstalling APPs to fix the exit code 20 issue of uninstalling
> Sync the changes to uninstall.sh
---
- 将 /META-INF 再度添加至模块 zip 以提升兼容性 (不会再删掉了……真麻烦……)
- 新增 /META-INF 内脚本的完整性验证
- 再度增加日志函数以调查问题
- 尝试处理 data 分区加密的设备的旧版APP卸载流程
> 卸载APP前等待屏幕解锁以修复卸载过程中退出状态码20的问题
> 同步该逻辑至 uninstall.sh