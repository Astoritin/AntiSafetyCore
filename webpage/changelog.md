## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against Android System SafetyCore and Android System Key Verifier installed by Google quietly / 一个对抗 Google 静默安装的 SafetyCore 和 Key Verifier 的 Magisk 模块

### 1.1.7

#### EN

- Fix a serious bug which caused Anti SafetyCore does NOT work at all
> I have found this today since I am updating Google APPs in my Android 11 device
> And as updating APPs in Google Play Store, I find SafetyCore appears
> in my device quietly lol, after I installed my module 
> and what I found is it does NOT work at all, which makes me confused a lot
> Finally I found the careless but serious logic codes problem and correct it T^T
- Improve the compatibility (explicitly add `su -c` back for some special cases)

#### CN

- 修复一个严重bug，该bug曾导致反 SafetyCore 压根没生效
> 我发现这个是因为今天我在自己的 安卓 11 的设备更新谷歌系 APP
> 当在 Play 商店更新 APP时，我发现 SafetyCore 悄悄出现在我设备内
> 在我刷入自己的模块时发现它压根没生效，这让我很困惑
> 最终我找到了粗心大意但很严重的逻辑代码问题然后更正了它
- 提升兼容性 (重新显式添加 `su -c` 以应对一些特殊情形)
