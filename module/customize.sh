#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/antisafetycore"
STUB_DIR="$CONFIG_DIR/stub"
LOG_DIR="$CONFIG_DIR/logs"
VERIFY_DIR="$TMPDIR/.aa_verify"
MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"

[ ! -d "$VERIFY_DIR" ] && mkdir -p "$VERIFY_DIR"

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
logowl "Extract module files"
extract "$ZIPFILE" 'aautilities.sh' "$MODPATH"
extract "$ZIPFILE" 'module.prop' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'action.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"
logowl "Extract stub apks"
extract "$ZIPFILE" 'stub/SafetyCoreStub.apk' "$STUB_DIR" "true"
extract "$ZIPFILE" 'stub/SystemKeyVerifierStub.apk' "$STUB_DIR" "true"
print_line "70"
logowl " "
logowl "NOTICE & WARNING" "TIPS"
logowl " "
logowl "Even though $MOD_NAME will uninstall and reinstall these APPs again automatically"
logowl "If you DO NOT want these APPs to come back"
logowl "Make sure you have DISABLED these options below:"
logowl " "
logowl "1. Allow downgrade" "TIPS"
logowl "2. Disable compare signatures" "TIPS"
logowl " "
logowl "TIPS: These options are often seen in Xposed module (e.g. Core Patch)"
logowl " "
print_line "70"
if [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ]; then
    rm -rf "$VERIFY_DIR"
fi
set_permission_recursive "$MODPATH" 0 0 0755 0644
logowl "Welcome to use $MOD_NAME!"
DESCRIPTION="[⏳Reboot to take effect.] A Magisk module to fight against Google Android System SafetyCore and Android System Key Verifier."
update_config_value "description" "$DESCRIPTION" "$MODPATH/module.prop" "true"
