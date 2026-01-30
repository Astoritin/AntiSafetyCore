## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against the behavior of installing Android System SafetyCore and Android System Key Verifier by Google quietly / 一个对抗 Google 静默安装 SafetyCore 和 Key Verifier 这一行为的 Magisk 模块

### 1.3.0

- Add background daemon mode: The module will periodically check the status of SafetyCore and KeyVerifier components. If Google Play Services restores them, or if the existing components mismatch the placeholder app, the module will automatically uninstall and reinstall the placeholder.
> Create an empty file `keep_running` (without extension) in `/data/adb/anti_safetycore/` to enable this feature
- Add systemize mode: Mount placeholder apps as system apps to avoid Google Play Services aggressively restoring apps to original ones.
> Create an empty file `systemize` (without extension) in `/data/adb/anti_safetycore/` to enable this feature
- Action/open button: Now action/open button will uninstall current SafetyCore and KeyVerifier apps only
---
- 新增后台守护模式：模块将周期性检测 SafetyCore 与 KeyVerifier 组件状态，若发现被系统还原或版本与占位符应用不符则自动执行卸载与重装操作
> 通过在 `/data/adb/anti_safetycore/` 下创建空文件 `keep_running` (无扩展名) 的方式启用该功能
- 新增系统化模式：现在支持将占位符应用挂载为系统应用以避免 Google Play 服务激进地恢复应用为原版应用
> 通过在 `/data/adb/anti_safetycore/` 下创建空文件 `systemize` (无扩展名) 的方式启用该功能
- 操作/打开按钮：现在操作/打开按钮仅卸载当前 SafetyCore 和 KeyVerifier 应用