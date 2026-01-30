English / [简体中文](webpage/locales/README_ZH-CN.md)

# **Anti SafetyCore**
A Magisk module to fight against the behavior of installing Android System SafetyCore and Android System Key Verifier by Google quietly.

## Supported Root Solution
[Magisk](https://github.com/topjohnwu/Magisk) / [KernelSU](https://github.com/tiann/KernelSU) / [APatch](https://github.com/bmax121/APatch)

## Why this module exists?
1. **I hate installing apps silently so much.** *——As installing apps silently in the background, uninstalling apps silently and updating apps automatically & silently are the most favorite dirty things Google loves to do, LOL.*
Therefore, sorry for any inconvenience. Would you feel better if I apology?
2. **In order to hide its dark intentions of further collecting users' data in the background quietly, Google deliberately named the apps in a way that resembles the names of system critical components.** *——Thank you, but not all the users are the fools*
3. **The apps Google installed is useless for me** *——LOL, Google.*

## How does this module work?
**In a standard and well-behave ROM, APKs with the same package name but different signatures cannot be overwrite installed casually.**
So, to stop Google from installing quietly in the background, just installing a placeholder APK with a different signature will do the trick.
Even with its special system level permissions, Google can't do upgrade or downgrade installations.
This effectively blocks Google from repeatedly installing stuff like SafetyCore and Key Verifier on the sly.

## Configuration
Since version 1.3.0, you can place **empty files (without extension)** with the following names in the configuration directory `/data/adb/anti_safetycore` to enable respective features:
1. **`keep_running`**: Enables background daemon mode. The module will periodically check the status of SafetyCore and KeyVerifier components. If Google Play Services restores them, or if the existing components mismatch the placeholder app, the module will automatically uninstall and reinstall the placeholder.
2. **`systemize`**: Promotes the placeholder app to system app privilege level. In this mode, Google Play Services cannot forcibly uninstall or replace the placeholder, even with system-level permissions.
      
### **Compatibility Notice**   
For devices running KernelSU (KernelSU kernel version ≥ 22098) or APatch (APatch kernel version ≥ 11170), you must install the [Metamodule](https://kernelsu.org/guide/metamodule.html) to enable `systemize` feature. Without it, the placeholder will always be installed as a user app regardless of the configuration.
   
### **Default Behavior**   
By default, the module installs the placeholders as **user apps**, which is sufficient for most devices.   
Only enable additional configurations in the following scenarios:   
- Placeholder is frequently restored to the official app by Google Play Services
- Device runs for long periods without rebooting, with concerns about silent component restoration

### Notes
1. If you have installed and enabled modules like [Core Patch](https://github.com/LSPosed/CorePatch) or similar options, Google may successfully perform a background silent update of the placeholder app.
> When these options are enabled, your ROM will ignore the different signatures and allow Google's actions.
2. To reduce resource consumption and system intervention, this module only uninstalls the two apps and replaces them with placeholder apps at booting.
> This means that if Google successfully replaces them with the original apps, you just need to click on the action/open button or restart your device to restore the placeholder apps.

## Help and Support
- If you encounter any problems, please [click here](https://github.com/Astoritin/AntiSafetyCore/issues) to submit feedback.
- [Pull Request](https://github.com/Astoritin/AntiSafetyCore/pulls) is always welcome to improve this module.

## Credits
- [Magisk](https://github.com/topjohnwu/Magisk) - the foundation which makes everything possible
- [Zygisk Next](https://github.com/Dr-TSNG/ZygiskNext) - the implementation of function extract and root solution check
- [LSPosed](https://github.com/LSPosed/LSPosed) - the implementation of function extract and root solution check
