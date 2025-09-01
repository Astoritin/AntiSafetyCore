## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against Android System SafetyCore and Android System Key Verifier installed by Google quietly / 一个对抗 Google 静默安装的 SafetyCore 和 Key Verifier 的 Magisk 模块

### 1.1.8

- Optimize minor codes
- Add back /META-INF to fix module cannot be flashed in KernelSU manager by choosing the zip file itself
> Magisk has ignored the /META-INF folder completely, as KernelSU ignores it too, but only for online updating
> that means if you choose to flash modules offline (by choosing the zip in your storage)
> KernelSU will still check the existence of /META-INF (even if module itself doesn't need it at all)
> If it does NOT exist...the result is failed to flash in manager offline
> I think the method of KernelSU dealing with /META-INF is weird but thinking about some old modules will add their custom scripts in /META-INF so...
---
- 优化少量代码
- 将 /META-INF 文件夹再度添加回模块中以修复在 KernelSU 无法从本地刷入该模块的问题
> Magisk 已经做到完全忽略 /META-INF 文件夹，而 KernelSU 仅在在线更新模块时忽略下载的zip里的 /META-INF 文件夹
> 这意味着你如果选择离线刷入模块（即从你的存储中选择zip刷入）
> KernelSU 仍然会检查 /META-INF 是否存在 （哪怕模块其实并不需要这个文件夹）
> 如果 /META-INF 不存在就会刷入失败
> 我个人认为 KernelSU 对 /META-INF 的处理很奇怪，但是考虑到有部分古早模块会添加自定义脚本到 /META-INF ，所以……