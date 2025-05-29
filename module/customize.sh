#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/antisafetycore"
PH_DIR="$CONFIG_DIR/placeholder"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"
MOD_INTRO="A Magisk module to fight against Safety Core and Key Verifier installed by Google quietly."

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"

echo "- Extract aa-util.sh"
unzip -o "$ZIPFILE" 'aa-util.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
    echo "! Failed to extract aa-util.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
install_env_check
show_system_info
logowl "Install from $ROOT_SOL app"
logowl "Essential check"
rm -rf "$PH_DIR"
extract "$ZIPFILE" 'aa-util.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
logowl "Extract module files"
mkdir -p "$PH_DIR"
extract "$ZIPFILE" 'aa-util.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
logowl "Extract placeholder apks"
extract "$ZIPFILE" 'placeholder/SafetyCorePlaceHolder.apk' "$PH_DIR" "true"
extract "$ZIPFILE" 'placeholder/KeyVerifierPlaceHolder.apk' "$PH_DIR" "true"
print_line "50"
logowl " " "NONE"
logowl "NOTICE & WARNING" " "
logowl " " "NONE"
logowl "Even though $MOD_NAME will uninstall these components:" " "
logowl "SafetyCore and KeyVerifier" " "
logowl "and then reinstall placeholder APPs automatically" " "
logowl "during each time system booting" " "
logowl "If you DO NOT want these APPs to come back during daily use" " "
logowl "(update by Google in the background quietly)" " "
logowl "Make sure you have DISABLED these options below:" " "
logowl " " "NONE"
logowl "1. Allow downgrade installation" " "
logowl "2. Disable compare signatures / Disable signature verification" " "
logowl " " "NONE"
logowl "TIPS: These options are often seen in Xposed module (e.g. Core Patch)" " "
logowl "or some custom ROM's inbuilt options or features" " "
logowl " " "NONE"
print_line "50"
rm -rf "$VERIFY_DIR"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[✨Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop" "true"
