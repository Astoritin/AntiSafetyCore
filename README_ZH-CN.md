[English](README.md) | 简体中文

# **反 SafetyCore / Anti SafetyCore**
一个对抗 Google 静默安装的 SafetyCore 和 Key Verifier 的 Magisk 模块。

## 支持的 Root 方案
[Magisk](https://github.com/topjohnwu/Magisk) (推荐!) 丨 [KernelSU](https://github.com/tiann/KernelSU) (推荐!) 丨 [APatch](https://github.com/bmax121/APatch) (尚未测试，理论可用)

## 为什么存在这个模块?

1. **我很反感静默安装这一行为。** *——而谷歌偏偏最喜欢做包括但不限于在后台静默安装 、静默卸载、后台自动更新等在阴暗中爬行的事情。*
所以对不起咯。如果我道歉，你会好受些吗？
2. **为了掩盖自己进一步在后台静默收集用户数据的阴暗心思，故意起了看起来像是系统关键核心组件的名字作为应用名。** *——谢谢，不是每个用户都是傻子。*
3. **安装的应用对我而言并没有什么用处。** *——呵呵，谷歌。*

## 该模块的工作原理是什么？

**在行为规范的 ROM 中，包名相同但是签名不同的 APK 应用无法覆盖安装。**
也就是说，如果需要防止谷歌后台阴暗爬行，只需要安装一个签名不同的占位符 APK 即可轻松针对。
谷歌即使因为自身的特殊性拿到了系统级权限，也无法覆盖安装或者升级/降级安装，进而就防止了谷歌在后台反复静默安装 SafetyCore 和 Key Verifier。

## 注意

1. 如果你安装并启用了 [核心破解](https://github.com/LSPosed/CorePatch) 之类的模块，或启用了类似的选项，那么谷歌可能成功后台静默换掉占位符应用。
> 因为在启用这些选项的前提下，你的 ROM 会忽视不同签名这一情况并放任谷歌的恶劣行径。
2. 为了减少资源占用和系统干预，本模块仅在每次开机时卸载这两个应用并替换安装为占位符应用。
> 也就是说如果被谷歌成功替换回原版应用，重新启动你的设备即可恢复为占位符应用。

## 帮助与支持
- 如果遇到问题，请点击 [此处](https://github.com/Astoritin/AntiSafetyCore/issues) 提交反馈
- 欢迎 [提交代码](https://github.com/Astoritin/AntiSafetyCore/pulls)，让该模块变得更好
