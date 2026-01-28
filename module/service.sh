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

is_magisk() {

    command -v magisk >/dev/null 2>&1 || return 1

    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    case "$MAGISK_V_VER_NAME" in
        *"-alpha"*) MAGISK_BRANCH_NAME="Alpha" ;;
        *) MAGISK_BRANCH_NAME="Magisk" ;;
    esac
    DETECT_MAGISK="true"
    return 0

}

is_kernelsu() {
    if [ -n "$KSU" ]; then
        DETECT_KSU="true"
        ROOT_SOL="KernelSU"
        return 0
    fi
    return 1
}

is_apatch() {
    if [ -n "$APATCH" ]; then
        DETECT_APATCH="true"
        ROOT_SOL="APatch"
        return 0
    fi
    return 1
}

install_env_check() {

    ROOT_SOL="Magisk"
    ROOT_SOL_COUNT=0

    is_kernelsu && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_apatch && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_magisk && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))

    if [ "$DETECT_KSU" = "true" ]; then
        ROOT_SOL="KernelSU"
        ROOT_SOL_DETAIL="KernelSU ($KSU_KERNEL_VER_CODE)"
    elif [ "$DETECT_APATCH" = "true" ]; then
        ROOT_SOL="APatch"
        ROOT_SOL_DETAIL="APatch ($APATCH_VER_CODE)"
    elif [ "$DETECT_MAGISK" = "true" ]; then
        ROOT_SOL="Magisk"
        ROOT_SOL_DETAIL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        ROOT_SOL="Multiple"
        ROOT_SOL_DETAIL="Multiple"
    elif [ "$ROOT_SOL_COUNT" -lt 1 ]; then
        ROOT_SOL="Unknown"
        ROOT_SOL_DETAIL="Unknown"
    fi

}

checkout_modules_dir() {

    current_modules_dir="/data/adb/modules"
    update_modules_dir="/data/adb/modules_update"

    if magisk -v | grep -q "lite"; then
        current_modules_dir="/data/adb/lite_modules"
        update_modules_dir="/data/adb/lite_modules_update"
    fi

}

scan_metamodule() {

    for moddir in "$current_modules_dir" "$update_modules_dir"; do
        [ -d "$moddir" ] || continue
        for current_module_dir in "$moddir"/*; do
            current_module_prop="$current_module_dir/module.prop"
            [ -e "$current_module_prop" ] || continue

            is_metamodule=$(get_key_value "metamodule" "$current_module_prop")
            current_module_name=$(get_key_value "name" "$current_module_prop")
            current_module_ver_name=$(get_key_value "version" "$current_module_prop")
            current_module_ver_code=$(get_key_value "versionCode" "$current_module_prop")
            case "$is_metamodule" in
                1|true ) [ ! -f "$current_module_dir/disable" ] && [ ! -f "$current_module_dir/remove" ] && return 0;;
            esac

        done
    done
    return 1

}

try_metamodule() {

    : ${2:=0} ${3:=0}
    [ "$1" = true ] && [ "$2" -ge "$3" ]

}

require_metamodule() {
    
    try_metamodule "$1" "$2" "$3" && scan_metamodule || {
        mode="user"
        mod_mode=" ❌Metamodule is required for systemizing apps on $4!"
        return 1
    }

}

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

update_key_value() {
    key="$1"
    conf="$2"
    expected="$3"
    append="${4:-false}"

    [ -z "$key" ] || [ -z "$expected" ] || [ -z "$conf" ] || [ ! -f "$conf" ] && return 1

    if grep -q "^${key}=" "$conf"; then
        [ "$append" = true ] && return 0
        sed -i "/^${key}=/c\\${key}=${expected}" "$conf"
    else
        [ -n "$(tail -c1 "$conf")" ] && echo >> "$conf"
        printf '%s=%s\n' "$key" "$expected" >> "$conf"
    fi
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
        require_metamodule "$DETECT_KSU" "$KSU_KERNEL_VER_CODE" "$MIN_VER_KERNELSU_TRY_METAMODULE" "KernelSU"
        require_metamodule "$DETECT_APATCH" "$APATCH_VER_CODE" "$MIN_VER_APATCH_TRY_METAMODULE" "APatch"
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
        DESCRIPTION="[${mod_state}${mod_mode}${mod_replace_sc}${mod_replace_kv} ✅Replace ${checkout_count} time(s) ✅Root: ${ROOT_SOL_DETAIL}] $MOD_INTRO"
    else
        DESCRIPTION="[${mod_state}${mod_mode}${mod_replace_sc}${mod_replace_kv} ✅Root: ${ROOT_SOL_DETAIL}] $MOD_INTRO"
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

