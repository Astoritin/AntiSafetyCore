#!/system/bin/sh
MODDIR=${0%/*}

data_state=$(getprop "ro.crypto.state")

CONFIG_DIR="/data/adb/anti_safetycore"
PLACEHOLDER_DIR="$CONFIG_DIR/placeholder"

MARK_KEEP_RUNNING="$CONFIG_DIR/keep_running"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"
LOCAL_TMP="/data/local/tmp"

MIN_VER_KERNELSU_TRY_METAMODULE=22098
MIN_VER_APATCH_TRY_METAMODULE=11170

. "$MODDIR/wanderer.sh"

check_data_encrypted() { [ "$data_state" = "encrypted" ]; }

file_compare() {

    file_a="$1"
    file_b="$2"
    
    [ -z "$file_a" ] || [ ! -f "$file_a" ] && return 2
    [ -z "$file_b" ] || [ ! -f "$file_b" ] && return 3
    
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    
    [ "$hash_file_a" = "$hash_file_b" ] && return 0
    [ "$hash_file_a" != "$hash_file_b" ] && return 1

}

uninstall_app() {

    package_name="$1"

    if check_data_encrypted; then
        while ! check_screen_unlock; do
            sleep 1
        done
    fi

    pm uninstall "$package_name"

}

install_apk() {

    apk_path="$1"

    cp "$apk_path" "/data/local/tmp"

    package_basename=$(basename "$apk_path")
    apk_path="/data/local/tmp/$package_basename"

    pm install -i "com.android.vending" "$apk_path"
    result_install_package=$?

    rm -f "$apk_path"
    return "$result_install_package"

}

let_us_do_it() {

    package_name=$1
    apk_to_install=$2

    uninstall_app "$package_name"
    install_apk "$apk_to_install"

}

fetch_app_path() {

    package_name=$1
    output_pm=$(pm path "$package_name")

    [ -n "$output_pm" ] || return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' | head -n 1)
    
    [ -f "$package_path" ] || return 2
    echo "$package_path"

}

check_system_app() { [ -z "$1" ] && return 1; pm list packages -s 2>/dev/null | grep -Fxq "package:$1"; }

checkout_app() {

    package_name=$1
    apk_to_install=$2

    if [ "$MARK_ACTION_REPLACE" = true ]; then
        let_us_do_it "$package_name" "$apk_to_install"
        return
    fi

    if [ "$mode" = "user" ]; then
        existed_apk_path=$(fetch_app_path "$package_name")
        if file_compare "$apk_to_install" "$existed_apk_path"; then
            return 0
        else
            let_us_do_it "$package_name" "$apk_to_install"
        fi
    elif [ "$mode" = "system" ]; then
        if check_system_app "$package_name"; then
            return 0
        fi
        return 1
    fi

}

check_screen_unlock() {

    keyguard_state=$(dumpsys window policy 2>/dev/null)
    if echo "$keyguard_state" | grep -A5 "KeyguardServiceDelegate" | grep -q "showing=false"; then
        return 0
    fi
    if echo "$keyguard_state" | grep -q -E "mShowingLockscreen=false|mDreamingLockscreen=false"; then
        return 0
    fi

    screen_focus=$(dumpsys window 2>/dev/null | grep -i mCurrentFocus)
    case $screen_focus in
    *keyguard*|*lockscreen*) return 1 ;;
    esac

    case $screen_focus in
    *[Ll][Aa][Uu][Nn][Cc][Hh][Ee][Rr]*|*[Ss][Ee][Tt][Tt][Ii][Nn][Gg][Ss]*) return 0 ;;
    *) return 1 ;;
    esac

    return 1

}

module_description_cleanup_schedule() {

    POST_D="/data/adb/post-fs-data.d/"
    CLEANUP_SH="cleanup_anti_safetycore.sh"
    CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

    if [ ! -f "$CLEANUP_PATH" ]; then
        mkdir -p "$POST_D"
        cat "$MODDIR/${CLEANUP_SH}" > "$CLEANUP_PATH"
        chmod +x "$CLEANUP_PATH"
    fi

}

anti_safetycore() {

    mod_state="✅Done."
    mode="user"
    mod_mode=" ✅User"
    mod_replace_sc=" ✅SafetyCore"
    mod_replace_kv=" ✅KeyVerifier"
    replaced_sc="false"
    replaced_kv="false"

    PH_SafetyCore="$PLACEHOLDER_DIR/com.google.android.safetycore.apk"
    PH_KeyVerifier="$PLACEHOLDER_DIR/com.google.android.contactkeys.apk"

    install_env_check

    if [ -f "$MARK_SYSTEMIZE" ] && [ ! -e "$MODDIR/skip_mount" ]; then
        mode="system"
        mod_mode=" ✅Systemized"
        [ "$DETECT_KSU" = true ] && require_metamodule "$DETECT_KSU" "$KSU_KERNEL_VER_CODE" "$MIN_VER_KERNELSU_TRY_METAMODULE" "KernelSU"
        [ "$DETECT_APATCH" = true ] && require_metamodule "$DETECT_APATCH" "$APATCH_VER_CODE" "$MIN_VER_APATCH_TRY_METAMODULE" "APatch"
    fi

    checkout_app "com.google.android.safetycore" "$PH_SafetyCore" && replaced_sc=true
    checkout_app "com.google.android.contactkeys" "$PH_KeyVerifier" && replaced_kv=true

    if [ "$replaced_sc" = "false" ] && [ "$replaced_kv" = "false" ]; then
        mod_state="❌No effect. Something went wrong!"
        mod_replace_kv=""
        mod_replace_sc=""
    elif [ "$replaced_sc" = "true" ] && [ "$replaced_kv" = "true" ]; then
        mod_state="✅All done."
    elif [ "$replaced_sc" = "true" ]; then
        mod_replace_kv=""
    elif [ "$replaced_kv" = "true" ]; then
        mod_replace_sc=""
    fi

    if [ "$checkout_count" -gt 0 ]; then
        DESCRIPTION="[${mod_state}${mod_mode}${mod_replace_sc}${mod_replace_kv} ✅${checkout_count} time(s) ✅${ROOT_SOL_DETAIL}] $MOD_INTRO"
    else
        DESCRIPTION="[${mod_state}${mod_mode}${mod_replace_sc}${mod_replace_kv} ✅${ROOT_SOL_DETAIL}] $MOD_INTRO"
    fi

    update_key_value "description" "$MODULE_PROP" "$DESCRIPTION"

}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

module_description_cleanup_schedule
checkout_count=0
checkout_modules_dir

while true; do

    anti_safetycore

    [ -f "$MARK_KEEP_RUNNING" ] || exit 0
    [ -f "$MARK_SYSTEMIZE" ] || exit 0
    [ -e "$MODDIR/skip_mount" ] || exit 0
    [ "$MARK_ACTION_REPLACE" = true ] && exit 0

    checkout_count=$((checkout_count + 1))
    sleep 1800

done

