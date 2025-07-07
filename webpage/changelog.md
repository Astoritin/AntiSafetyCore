## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against Android System SafetyCore and Android System Key Verifier installed by Google quietly / 一个对抗 Google 静默安装的 SafetyCore 和 Key Verifier 的 Magisk 模块

### 1.1.5

- Now, Anti SafetyCore will check the path of pm command first before executing
- Add action/open button: as clicking on the action/open button of Anti SafetyCore
  placeholder apks will be installed forcefully and immediately after 3 seconds
- You can click on the action/open button instead of rebooting your device
  as finding placeholder apks has been uninstalled by Google Play Store
- NOTICE: This action can be cancelled by pressing volume down button in 3 seconds
  if you accidentally click on the action/open button 
- Coupling aa-util.sh with module again because of the usage of action.sh 
  and to reduce the repeatedly appearence of some codes

- 现在，Anti SafetyCore 在执行前会先检查pm命令的路径
- 增加操作/打开按钮：点击 Anti SafetyCore 的操作/打开按钮时，将在3秒后立即强制安装占位符APK
- 在发现占位符 apk 被谷歌 Play 商店卸载时，只需简单点击一下操作/打开按钮即可，无需重新启动设备
- 注意：当你误点操作/打开按钮时，可以在三秒内按下音量减键取消
- 由于 `action.sh` 的存在，且减少部分代码的重复出现频率，将 `aa-util.sh` 再度与模块耦合