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
rm -rf "$PH_DIR"
mkdir -p "$PH_DIR"
extract "$ZIPFILE" 'customize.sh' "$TMPDIR"
extract "$ZIPFILE" 'aa-util.sh' "$TMPDIR"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
extract "$ZIPFILE" 'placeholder/SafetyCorePlaceHolder.apk' "$PH_DIR" "true"
extract "$ZIPFILE" 'placeholder/KeyVerifierPlaceHolder.apk' "$PH_DIR" "true"
print_line "42" "*"
logowl "NOTICE & WARNING" " "
print_line "42" "*"
logowl "Even though $MOD_NAME will uninstall"
logowl "and reinstall these components:"
logowl "    SafetyCore and KeyVerifier"
logowl "with placeholder APPs automatically"
logowl "during each time boot"
logowl "If you DO NOT want these APPs to"
logowl "come back during daily use (update"
logowl "by Google in the background quietly)"
logowl "Make sure you have DISABLED these options:"
logowl " " " "
logowl "  1. Allow downgrade installation"
logowl "  2. Disable compare signatures"
logowl "     or disable signature verification"
logowl " " " "
logowl "  These options are often seen in:"
logowl "  1. Xposed module (e.g. Core Patch)"
logowl "  2. Some custom ROM's inbuilt options"
logowl " " " "
print_line "42" "*"
logowl "Set permissions"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Reboot to take effect"
DESCRIPTION="[⏳Reboot to take effect.] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODPATH/module.prop"
logowl "Welcome to use $MOD_NAME!"
