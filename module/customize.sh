#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/antisafetycore"
LOG_DIR="$CONFIG_DIR/logs"

PH_DIR="$CONFIG_DIR/placeholder"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"
MOD_INTRO="Fight against SafetyCore and KeyVerifier."

unzip -o "$ZIPFILE" 'aa-util.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aa-util.sh" ]; then
    echo "! Failed to extract aa-util.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aa-util.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
show_system_info
install_env_check
logowl "Install from $ROOT_SOL app"
logowl "Root: $ROOT_SOL_DETAIL"
[ -d "$LOG_DIR" ] && rm -rf "$LOG_DIR"
rm -rf "$PH_DIR"
mkdir -p "$PH_DIR"
extract "$ZIPFILE" 'customize.sh' "$TMPDIR"
extract "$ZIPFILE" 'aa-util.sh' "$TMPDIR"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
extract "$ZIPFILE" 'placeholder/SafetyCorePlaceHolder.apk' "$PH_DIR" "true"
extract "$ZIPFILE" 'placeholder/KeyVerifierPlaceHolder.apk' "$PH_DIR" "true"
print_line "26" "*"
logowl "NOTICE & WARNING"
print_line "26" "*"
logowl "Even though $MOD_NAME will"
logowl "uninstall these components:"
logowl "  SafetyCore and KeyVerifier"
logowl "and then reinstall placeholder APPs"
logowl "automatically during each time boot"
logowl "If you DO NOT want these APPs"
logowl "to come back during daily use"
logowl "(update by Google in the background quietly)"
logowl "Make sure you have DISABLED these options below:"
print_line "26" "*"
logowl "  1. Allow downgrade installation"
logowl "  2. Disable compare signatures"
logowl "     or disable signature verification"
print_line "26" "*"
logowl "TIPS: These options are often seen in:"
logowl "  1. Xposed module (e.g. Core Patch)"
logowl "  2. Some custom ROM's inbuilt options"
print_line "26" "*"
set_permission_recursive "$MODPATH" 0 0 0755 0644
DESCRIPTION="[⏳Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
logowl "Welcome to use $MOD_NAME!"
