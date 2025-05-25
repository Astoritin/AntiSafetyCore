#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/antisafetycore"

LOG_DIR="$CONFIG_DIR/logs"
PH_DIR="$CONFIG_DIR/placeholder"

VERIFY_DIR="$TMPDIR/.aa_verify"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"
MOD_INTRO="A Magisk module to fight against Android System SafetyCore and Android System Key Verifier installed by Google quietly."

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"


migrate_old_files() {

    logowl "Migrate old files"

    rm -rf /data/adb/antisafetycore/stub
    rm -rf /data/adb/antisafetycore/placeholder

}

echo "- Extract aautilities.sh"
unzip -o "$ZIPFILE" 'aautilities.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/aautilities.sh" ]; then
    echo "! Failed to extract aautilities.sh!"
    abort "! This zip may be corrupted!"
fi

. "$TMPDIR/aautilities.sh"

logowl "Setting up $MOD_NAME"
logowl "Version: $MOD_VER"
init_logowl "$LOG_DIR"
install_env_check
show_system_info
logowl "Install from $ROOT_SOL app"
logowl "Essential check"
extract "$ZIPFILE" 'aautilities.sh' "$VERIFY_DIR"
extract "$ZIPFILE" 'customize.sh' "$VERIFY_DIR"
clean_old_logs "$LOG_DIR" 20
migrate_old_files
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
logowl "Extract placeholder apks"
extract "$ZIPFILE" 'placeholder/SafetyCorePlaceHolder.apk' "$PH_DIR" "true"
extract "$ZIPFILE" 'placeholder/KeyVerifierPlaceHolder.apk' "$PH_DIR" "true"
print_line "50"
logowl " " "SPACE"
logowl "NOTICE & WARNING" "SPACE"
logowl " " "SPACE"
logowl "Even though $MOD_NAME will uninstall these components:" "SPACE"
logowl "SafetyCore and KeyVerifier" "SPACE"
logowl "and then reinstall placeholder APPs automatically" "SPACE"
logowl "during each time system booting" "SPACE"
logowl "If you DO NOT want these APPs to come back during daily using" "SPACE"
logowl "(update by Google in the background quietly)" "SPACE"
logowl "Make sure you have DISABLED these options below:" "SPACE"
logowl " " "SPACE"
logowl "  1. Allow downgrade installation" "SPACE"
logowl "  2. Disable compare signatures / Disable signature verification" "SPACE"
logowl " " "SPACE"
logowl "TIPS: These options are often seen in Xposed module (e.g. Core Patch)" "SPACE"
logowl "or some custom ROM's inbuilt options or features" "SPACE"
logowl " " "SPACE"
print_line "50"
rm -rf "$VERIFY_DIR"
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[⏳Reboot to take effect.] $MOD_INTRO"
update_config_value "description" "$DESCRIPTION" "$MODPATH/module.prop" "true"
