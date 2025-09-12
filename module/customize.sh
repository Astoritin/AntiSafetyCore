#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR_OLD="/data/adb/antisafetycore"
CONFIG_DIR="/data/adb/anti_safetycore"

PH_DIR="$CONFIG_DIR/placeholder"

MOD_UPDATE_PATH="$(dirname "$MODPATH")"
MOD_PATH="${MOD_UPDATE_PATH%_update}"
MOD_PATH_OLD="$MOD_PATH/antisafetycore"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"

unzip -o "$ZIPFILE" "verify.sh" -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/verify.sh" ]; then
    ui_print "! Failed to extract verify.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/verify.sh"

eco "Set up $MOD_NAME"
eco "Version: $MOD_VER"
show_system_info
install_env_check
eco "Install from $ROOT_SOL app"
eco "Root: $ROOT_SOL_DETAIL"
eco "[DEBUG] MODPATH: $MODPATH"
eco "[DEBUG] MOD_UPDATE_PATH: $MOD_UPDATE_PATH"
eco "[DEBUG] MOD_PATH: $MOD_PATH"
[ -d "$MOD_PATH_OLD" ] && rm -f "$MOD_PATH_OLD/update" && eco "[DEBUG] Remove $MOD_PATH_OLD/update"
[ -d "$MOD_PATH_OLD" ] && touch "$MOD_PATH_OLD/remove" && eco "[DEBUG] Create $MOD_PATH_OLD/remove"
rm -rf "$CONFIG_DIR_OLD"
rm -rf "$CONFIG_DIR"
mkdir -p "$PH_DIR"
extract "customize.sh" "$TMPDIR"
extract "verify.sh" "$TMPDIR"
extract "module.prop"
extract "service.sh"
extract "action.sh"
extract "uninstall.sh"
extract "placeholder/SafetyCorePlaceHolder.apk" "$CONFIG_DIR"
extract "placeholder/KeyVerifierPlaceHolder.apk" "$CONFIG_DIR"
print_line "42" "*"
eco "NOTICE & WARNING" " "
print_line "42" "*"
eco " " " "
eco "Even though $MOD_NAME will uninstall" " "
eco "and reinstall SafetyCore and KeyVerifier" " "
eco "with placeholder APPs automatically" " "
eco "during each time boot" " "
eco " " " "
eco "If you DO NOT want these APPs to" " "
eco "come back during daily use (update" " "
eco "by Google in the background quietly)" " "
eco "Make sure you have DISABLED these options:" " "
eco " " " "
eco "1. Allow downgrade installation" " "
eco "2. Disable compare signatures" " "
eco "   or disable signature verification" " "
eco " " " "
eco "These options are often seen in:" " "
eco " " " "
eco "1. Xposed module (e.g. Core Patch)" " "
eco "2. Some custom ROM's inbuilt options" " "
eco " " " "
eco "    REBOOT TO TAKE EFFECT    " " "
eco " " " "
print_line "42" "*"
eco "Set permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644
eco "Welcome to use $MOD_NAME!"
