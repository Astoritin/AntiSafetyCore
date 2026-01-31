## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against the behavior of installing Android System SafetyCore and Android System Key Verifier by Google quietly / 一个对抗 Google 静默安装 SafetyCore 和 Key Verifier 这一行为的 Magisk 模块

### 1.3.0

- Add background daemon mode: The module will periodically check the status of SafetyCore and KeyVerifier components. If Google Play Services restores them, or if the existing components mismatch the placeholder app, the module will automatically uninstall and reinstall the placeholder.
> Create an empty file `keep_running` (without extension) in `/data/adb/anti_safetycore/` to enable this feature (Reboot to take effect after creating file)
- Add systemize mode: Mount placeholder apps as system apps to avoid Google Play Services aggressively restoring apps to original ones.
> Create an empty file `systemize` (without extension) in `/data/adb/anti_safetycore/` to enable this feature (Reboot to take effect after creating file)
- Action/open button: Now action/open button will uninstall current SafetyCore and KeyVerifier app only   
- Fix the logic code of creating skip_mount flag in installation script   
   

**Compatibility Notice**   
For devices running KernelSU (KernelSU kernel version ≥ 22098) or APatch (APatch kernel version ≥ 11170), you must install the [Metamodule](https://kernelsu.org/guide/metamodule.html) to enable `systemize` feature. Without it, the placeholder will always be installed as user apps regardless of the configuration.   

***
- 新增后台守护模式：模块将周期性检测 SafetyCore 与 KeyVerifier 组件状态，若发现被 Google Play 服务还原或版本与占位符应用不符则自动执行卸载与重装操作
> 通过在 `/data/adb/anti_safetycore/` 下创建空文件 `keep_running` (无扩展名) 的方式启用该功能 (创建文件后重启生效)
- 新增系统化模式：现在支持将占位符应用挂载为系统应用以避免 Google Play 服务激进地恢复应用为原版应用
> 通过在 `/data/adb/anti_safetycore/` 下创建空文件 `systemize` (无扩展名) 的方式启用该功能 (创建文件后重启生效)
- 操作/打开按钮：现在操作/打开按钮仅卸载当前 SafetyCore 和 KeyVerifier 应用
- 修复安装脚本中创建标识符 skip_mount 的逻辑代码   
   
   
**兼容性提示**   
对于 KernelSU 的内核版本 ≥ 22098 或 APatch 的内核版本 ≥ 11170 的用户，如需启用系统化 (systemize) 功能，必须同时安装 **[元模块 (Metamodule)](https://kernelsu.org/guide/metamodule.html)** ，否则占位符应用仍将作为用户应用安装。   
