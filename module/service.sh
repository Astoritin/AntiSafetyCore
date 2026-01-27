#!/system/bin/sh
MODDIR=${0%/*}

data_state=$(getprop "ro.crypto.state")

CONFIG_DIR="/data/adb/anti_safetycore"
PH_DIR="$MODDIR/system/app"

MARK_KEEP_RUNNING="$CONFIG_DIR/keep_running"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

SYSTEMIZE_DIR="$MODDIR/system/app"

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

uninstall_and_install() {

    apk_package_name=$1
    apk_to_install=$2

    uninstall_package "$apk_package_name"
    install_package "$apk_to_install"

}

pm_fetch_package_path() {

    package_name=$1
    output_pm=$(pm path "$package_name")

    [ -n "$output_pm" ] || return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' | head -n 1)
    
    [ -f "$package_path" ] || return 2
    echo "$package_path"

}

checkout_apps() {

    apk_mode=$1
    apk_to_install=$2
    apk_package_name=$3

    if [ "$apk_mode" = "user" ]; then
        [ -f "$apk_to_install" ] || return 1
        [ -n "$apk_package_name" ] || return 2
    elif [ "$apk_mode" = "system" ]; then
        [ -z "$apk_package_name" ] && return 1
        [ -d "$SYSTEMIZE_DIR/$apk_package_name" ] || return 1
        [ -d "/system/app/$apk_package_name" ] || return 2
    fi

    if [ "$MARK_ACTION_REPLACE" = true ]; then
        uninstall_and_install "$apk_to_install" "$apk_package_name"
        return $?
    fi

    existed_apk_path=$(pm_fetch_package_path "$apk_package_name")
    if file_compare "$apk_to_install" "$existed_apk_path"; then
        return 0
    else
        uninstall_and_install "$apk_to_install" "$apk_package_name"
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

anti_safetycore_description_update() {

    mod_state="✅Done."
    mod_replace_sc="✅SafetyCore"
    mod_replace_kv="✅KeyVerifier"

    if [ "$replaced_sc" = "false" ] && [ "$replaced_kv" = "false" ]; then
        mod_state="❌No effect. Something went wrong!"
    elif [ "$replaced_sc" = "true" ] && [ "$replaced_kv" = "true" ]; then
        mod_state="✅All done."
    elif [ "$replaced_sc" = "true" ]; then
        mod_replace_kv=""
    elif [ "$replaced_kv" = "true" ]; then
        mod_replace_sc=""
    fi

    if [ "$checkout_count" -gt 0 ]; then
        DESCRIPTION="[${mod_state} ${mod_mode} ${mod_replace_sc} ${mod_replace_kv} ✅${checkout_count} time(s)] $MOD_INTRO"
    else
        DESCRIPTION="[${mod_state} ${mod_mode} ${mod_replace_sc} ${mod_replace_kv}] $MOD_INTRO"
    fi
    update_key_value "description" "$MODULE_PROP" "$DESCRIPTION"

}

anti_safetycore() {

    SafetyCore="com.google.android.safetycore"
    KeyVerifier="com.google.android.contactkeys"

    PH_SafetyCore="$PH_DIR/$SafetyCore/${SafetyCore}.apk"
    PH_KeyVerifier="$PH_DIR/$KeyVerifier/${KeyVerifier}.apk"

    if [ -f "$MARK_SYSTEMIZE" ] && [ ! -e "$MODDIR/skip_mount" ]; then
        mod_mode="✅Systemized"
        checkout_apps "system" "$SafetyCore" "$PH_SafetyCore" && replaced_sc=true
        checkout_apps "system" "$KeyVerifier" "$PH_KeyVerifier" && replaced_kv=true
    else
        mod_mode="✅Installed"
        checkout_apps "user" "$SafetyCore" "$PH_SafetyCore" && replaced_sc=true
        checkout_apps "user" "$KeyVerifier" "$PH_KeyVerifier" && replaced_kv=true
    fi

    anti_safetycore_description_update

}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

module_description_cleanup_schedule
checkout_count=0

while true; do

    anti_safetycore

    [ -f "$MARK_KEEP_RUNNING" ] || exit 0
    [ -f "$MARK_SYSTEMIZE" ] || exit 0
    [ -d "$SYSTEMIZE_DIR" ] || exit 0
    [ -e "$MODDIR/skip_mount" ] || exit 0
    [ "$MARK_ACTION_REPLACE" = true ] && exit 0

    checkout_count=$((checkout_count + 1))
    sleep 1800

done

