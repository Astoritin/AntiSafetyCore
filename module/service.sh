#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"
STUB_DIR="$CONFIG_DIR/stub"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/asc_core_$(date +"%Y%m%dT%H%M%S").log"
TMP_DIR="/data/local/tmp"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")

check_module_env() {

    logowl "Essential check"
    if [ ! -d "$CONFIG_DIR" ]; then
        logowl "Config dir $CONFIG_DIR does NOT exist!" "FATAL"
        return 1
    elif [ ! -d "$STUB_DIR" ]; then
        logowl "Stub dir $STUB_DIR does NOT exist!" "FATAL"
        return 1
    fi

}

deal_with_app() {
    pkg_name=$1
    opt=$2

    if [ -z "$pkg_name" ]; then
        logowl "Package name is NOT ordered!" "ERROR"
        return 1
    fi
    if [ -z "$opt" ]; then
        logowl "Operation is NOT ordered!" "ERROR"
        return 1
    fi

    if [ "$opt" = "install" ]; then
        pkg_basename=$(basename "$pkg_name")
        pkg_tmp_path="$TMP_DIR/$pkg_basename"
        cp "$pkg_name" "$TMP_DIR"
        logowl "Install package: $pkg_name"
        logowl "Execute: pm install -i com.android.vending $pkg_tmp_path"
        su -c "pm install -i com.android.vending $pkg_tmp_path" 2>&1 | tee "$LOG_FILE"
    elif [ "$opt" = "uninstall" ]; then
        logowl "Uninstall package: $pkg_name"
        logowl "Execute: pm uninstall $pkg_name"
        su -c "pm uninstall $pkg_name" 2>&1 | tee "$LOG_FILE"
    fi

    result_deal_with_app=$?
    if [ "$result_deal_with_app" -eq 0 ]; then
        if [ "$opt" = "install" ]; then
            logowl "$pkg_name has been installed"
            install_count=$((install_count + 1))
            rm -f "$pkg_tmp_path"
        elif [ "$opt" = "uninstall" ]; then
            logowl "$pkg_name has been slain"
            uninstall_count=$((uninstall_count + 1))
        fi
        return 0
    else
        logowl "Failed (code: $result_deal_with_app)"
        [ "$opt" = "install" ] && rm -f "$pkg_tmp_path"
        return "$result_deal_with_app"
    fi

}

install_stub_app()  {

    logowl "Install mirror stub APPs"

    deal_with_app "com.google.android.safetycore" "uninstall"
    deal_with_app "com.google.android.contactkeys" "uninstall"

    [ -f "$STUB_DIR/SafetyCoreStub.apk" ] && deal_with_app "$STUB_DIR/SafetyCoreStub.apk" "install"
    [ -f "$STUB_DIR/SystemKeyVerifierStub.apk" ] && deal_with_app "$STUB_DIR/SystemKeyVerifierStub.apk" "install"

}

module_status_update() {

    logowl "Update module description"

    max_uninstall_count=2
    max_install_count=2

    DESCRIPTION="A Magisk module to fight against Google Android System SafetyCore and Android System Key Verifier."
    if [ $install_count -eq $max_install_count ]; then
        DESCRIPTION="[✅All Done.] A Magisk module to fight against Google Android System SafetyCore and Android System Key Verifier."
    elif [ $install_count -gt 0 ]; then
        DESCRIPTION="[✅Partially Done.] A Magisk module to fight against Google Android System SafetyCore and Android System Key Verifier."
    else
        DESCRIPTION="[❌No effect. Please check logs!] A Magisk module to fight against Google Android System SafetyCore and Android System Key Verifier."
    fi
    
    update_config_value "description" "$DESCRIPTION" "$MODULE_PROP" "true"
}

. "$MODDIR/aautilities.sh"

uninstall_count=0
install_count=0

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Start service.sh"
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
logowl "Boot complete!"
check_module_env && install_stub_app && module_status_update
print_line
logowl "Service.sh case closed!"
