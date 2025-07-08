#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"
PH_DIR="$CONFIG_DIR/placeholder"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/asc_core_$(date +"%Y%m%dT%H%M%S").log"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="Fight against SafetyCore and KeyVerifier."

replaced_sc="false"
replaced_kv="false"
desc_state=""

. "$MODDIR/aa-util.sh"

logowl_init "$LOG_DIR"
logowl_clean "30"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line

check_installed_apk() {
    path_apk_toinstall=$1
    package_name=$2
    
    path_apk_installed=$(fetch_package_path_from_pm "$package_name")

    if [ ! -f "$path_apk_toinstall" ]; then
        logowl "APK to install does NOT exist!" "E"
        return 1
    fi

    if [ "$FORCE_REPLACE" = true ]; then
        logowl "Find force mode enabled"
        check_and_install_apk "$path_apk_toinstall" "$path_apk_installed"
        return $?
    fi

    file_compare "$path_apk_toinstall" "$path_apk_installed"
    result_file_compare=$?

    case "$result_file_compare" in
    0)  logowl "Same"
        return 0
        ;;
    1|3)  logowl "Different"
        check_and_install_apk "$path_apk_toinstall" "$path_apk_installed"
        ;;
    esac
}

check_and_install_apk() {
    $path_apk_toinstall=$1
    $path_apk_installed=$2

    if [ -f "$path_apk_installed" ]; then
        logowl "Find installed apk"
        uninstall_package "$path_apk_installed"
    fi
    install_package "$path_apk_toinstall" && return 0
    return 1
}

boot_count=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    boot_count=$((boot_count + 1))
    sleep 1
done

logowl "Boot complete after ${boot_count}s!"

SafetyCore="com.google.android.safetycore"
KeyVerifier="com.google.android.contactkeys"

PH_SafetyCore="$PH_DIR/SafetyCorePlaceHolder.apk"
PH_KeyVerifier="$PH_DIR/KeyVerifierPlaceHolder.apk"

check_installed_apk "$PH_SafetyCore" && replaced_sc=true
check_installed_apk "$PH_KeyVerifier" && replaced_kv=true

if [ "$replaced_sc" = "true" ] && [ "$replaced_kv" = "true" ]; then
    desc_state="✅Cleared. Slain: ✅SafetyCore, ✅KeyVerifier"
elif [ "$replaced_sc" = "true" ]; then
    desc_state="✅Done. Slain: ✅SafetyCore"
elif [ "$replaced_kv" = "true" ]; then
    desc_state="✅Done. Slain: ✅KeyVerifier"
else
    desc_state="❌No effect. Something went wrong!"
fi

DESCRIPTION="[$desc_state] $MOD_INTRO"
update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
logowl "$SEPARATE_LINE"
logowl "Case closed!"