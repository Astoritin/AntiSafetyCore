## Anti SafetyCore / 反 SafetyCore
A Magisk module to fight against Android System SafetyCore and Android System Key Verifier installed by Google quietly / 一个对抗 Google 静默安装的 SafetyCore 和 Key Verifier 的 Magisk 模块

### 1.1.2

- Decouple aa-util.sh from Anit SafetyCore. Now `aa-util.sh` will NOT be extracted into module directory anymore.
  > Q: Why so?
  > A: Because Anti SafetyCore is a simple module doing simple things, which does NOT need to use `aa-util.sh` to bring convenience
  > This will increase the size of module.zip (for a bit) but decrease the size of module files installed in your device
- Update module description

- 从 Anti SafetyCore 中解耦 `aa-util.sh`。现在 `aa-util.sh` 不会再被解压到模块目录。
  > Q: 为什么？
  > A: 因为 Anti SafetyCore 只是一个做很简单的事情的简单的模块，并不需要通过用 `aa-util.sh` 带来更多便利
  > 这将稍微增加模块压缩包的大小，但也将减少安装到你的设备的模块文件的大小。
- 更新模块描述
