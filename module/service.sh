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

    if [ "$work_mode" = "user" ]; then
        existed_apk_path=$(fetch_app_path "$package_name")
        if file_compare "$apk_to_install" "$existed_apk_path"; then
            return 0
        else
            let_us_do_it "$package_name" "$apk_to_install"
        fi
    elif [ "$work_mode" = "system" ]; then
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

update_metamodule_description() {
    
    try_metamodule "$1" "$2" "$3" && scan_metamodule || {
        work_mode="user"
        can_systemize=false
        return 1
    }

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

    work_mode=user
    can_systemize=true
    replaced_safetycore=false
    replaced_keyverifier=false

    install_env_check

    if [ -f "$MARK_SYSTEMIZE" ] && [ ! -e "$MODDIR/skip_mount" ]; then
        work_mode=system
        [ "$DETECT_KSU" = true ] && update_metamodule_description "$DETECT_KSU" "$KSU_KERNEL_VER_CODE" "$MIN_VER_KERNELSU_TRY_METAMODULE" "KernelSU"
        [ "$DETECT_APATCH" = true ] && update_metamodule_description "$DETECT_APATCH" "$APATCH_VER_CODE" "$MIN_VER_APATCH_TRY_METAMODULE" "APatch"
    fi

    checkout_app "com.google.android.safetycore" "$PLACEHOLDER_DIR/com.google.android.safetycore.apk" && replaced_safetycore=true
    checkout_app "com.google.android.contactkeys" "$PLACEHOLDER_DIR/com.google.android.contactkeys.apk" && replaced_keyverifier=true

}

module_description_update() {

    if [ "$work_mode" = "system" ]; then
        desc_work_mode="✅Systemize"
        if [ "$can_systemize" = false ]; then
            desc_work_mode="❌Metamodule required!"
        fi
    elif [ "$work_mode" = "user" ]; then
        desc_work_mode="✅User apps "
    fi

    [ "$replaced_safetycore" = true ] && desc_safetycore=" ✅SafetyCore,"
    [ "$replaced_keyverifier" = true ] && desc_keyverifier=" ✅KeyVerifier,"

    [ "$checkout_count" -gt 0 ] && desc_schedule=" ✅$checkout_count time(s),"

    DESCRIPTION="[${desc_work_mode}${desc_safetycore}${desc_keyverifier}${desc_schedule} ${ROOT_SOL_DETAIL}] $MOD_INTRO"
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
    module_description_update

    [ -f "$MARK_KEEP_RUNNING" ] || exit 0
    [ -f "$MARK_SYSTEMIZE" ] || exit 0
    [ -e "$MODDIR/skip_mount" ] || exit 0

    checkout_count=$((checkout_count + 1))
    sleep 1800

done

