## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against Android System SafetyCore and Android System Key Verifier installed by Google quietly / 一个对抗 Google 静默安装的 SafetyCore 和 Key Verifier 的 Magisk 模块

### 1.1.9

- Optimize minor codes
- Introduce module description cleanup script
> It is weird if you disabled this module but the module description is still keeping as the last time status
- Introduce new uninstall script to make uninstall more clever
> You don't need to uninstall placeholder apks manually after uninstalling this module...since this version
- Remove folder /META-INF again to reduce the size
> Since KernelSU Metamodule template module doesn't has this folder, so I think it is okay to drop it now
---
- 优化少量代码
- 引入模块描述清理脚本
> 当你已禁用本模块但模块描述仍然是上一次的状态时，这很诡异
- 引入新的卸载脚本，使得卸载更智能
> 从本版本起，你无需在卸载本模块以后手动卸载占位符apk
- 再度移除 /META-INF 文件夹以减小文件大小
> 由于 KernelSU 的元模块模板中不再包含此文件夹，因此我觉得现在移除了也没有什么问题了