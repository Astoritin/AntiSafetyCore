#!/system/bin/sh
MODDIR=${0%/*}

data_state=$(getprop "ro.crypto.state")

CONFIG_DIR="/data/adb/anti_safetycore"
PH_DIR="$CONFIG_DIR/placeholder"
MARK_KEEP_RUNNING="$CONFIG_DIR/keep_running"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"
LOCAL_TMP="/data/local/tmp"

replaced_sc="false"
replaced_kv="false"
desc_state=""

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

fetch_package_path_from_pm() {

    package_name=$1
    output_pm=$(pm path "$package_name")

    [ -z "$output_pm" ] && return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' | head -n 1)
    echo "$package_path"

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

uninstall_package() {

    package_name="$1"

    if check_data_encrypted; then
        while ! check_screen_unlock; do
            sleep 1
        done
    fi

    pm uninstall "$package_name"

}

install_package() {

    package_path="$1"

    cp "$package_path" "$LOCAL_TMP"

    package_basename=$(basename "$package_path")
    package_tmp="$LOCAL_TMP/$package_basename"

    pm install -i "com.android.vending" "$package_tmp"
    result_install_package=$?

    rm -f "$package_tmp"
    return "$result_install_package"

}

check_and_install_apk() {

    apk_to_install=$1
    apk_package_name=$2

    uninstall_package "$apk_package_name"
    install_package "$apk_to_install"

}

check_existed_app() {

    apk_to_install=$1
    apk_package_name=$2

    if [ ! -f "$apk_to_install" ]; then
        return 1
    fi
    if [ -z "$apk_package_name" ]; then
        return 2
    fi

    if [ "$FORCE_REPLACE" = true ]; then
        check_and_install_apk "$apk_to_install" "$apk_package_name"
        return $?
    fi

    existed_apk_path=$(fetch_package_path_from_pm "$apk_package_name")
    file_compare "$apk_to_install" "$existed_apk_path"
    case "$?" in
    0)  return 0;;
    1|3)    check_and_install_apk "$apk_to_install" "$apk_package_name";;
    esac

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

    SafetyCore="com.google.android.safetycore"
    KeyVerifier="com.google.android.contactkeys"

    PH_SafetyCore="$PH_DIR/SafetyCorePlaceHolder.apk"
    PH_KeyVerifier="$PH_DIR/KeyVerifierPlaceHolder.apk"

    check_existed_app "$PH_SafetyCore" "$SafetyCore" && replaced_sc=true
    check_existed_app "$PH_KeyVerifier" "$KeyVerifier" && replaced_kv=true

}

anti_safetycore_description_update() {

    mod_state="✅Done."
    mod_prefix=""
    mod_separator=", "
    mod_replace_sc="✅SafetyCore"
    mod_replace_kv="✅KeyVerifier"

    if [ "$replaced_sc" = "false" ] && [ "$replaced_kv" = "false" ]; then
        mod_state="❌No effect."
        mod_prefix="Something went wrong!"
        mod_separator=""
    elif [ "$replaced_sc" = "true" ] && [ "$replaced_kv" = "true" ]; then
        mod_state="✅All done."
    elif [ "$replaced_sc" = "true" ]; then
        mod_replace_kv=""
    elif [ "$replaced_kv" = "true" ]; then
        mod_replace_sc=""
    fi

    if [ "$checkout_count" -gt 0 ]; then
        DESCRIPTION="[${mod_state} ${mod_prefix}${mod_replace_sc}${mod_separator}${mod_replace_kv}, ⏰${checkout_count} time(s)] $MOD_INTRO"
    else
        DESCRIPTION="[${mod_state} ${mod_prefix}${mod_replace_sc}${mod_separator}${mod_replace_kv}] $MOD_INTRO"
    fi
    update_key_value "description" "$MODULE_PROP" "$DESCRIPTION"

}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

module_description_cleanup_schedule
checkout_count=0

while true; do

    anti_safetycore
    anti_safetycore_description_update

    [ -f "$MARK_KEEP_RUNNING" ] || exit 0

    checkout_count=$((checkout_count + 1))
    sleep 1800

done

