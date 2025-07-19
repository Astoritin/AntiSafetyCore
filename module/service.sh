#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"
PH_DIR="$CONFIG_DIR/placeholder"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="Fight against SafetyCore and KeyVerifier."

replaced_sc="false"
replaced_kv="false"
desc_state=""

PM="$(command -v pm)"

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
    output_pm=$(${PM} path "$package_name")

    [ -z "$output_pm" ] && return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' | head -n 1)

    echo "$package_path"
}

uninstall_package() {
    package_name="$1"

    "$PM" uninstall "$package_name" || su -c "${PM} uninstall $package_name"
    result_uninstall_package=$?
    return "$result_uninstall_package"
}

install_package() {
    package_path="$1"
    TMPDIR="/data/local/tmp"

    cp "$package_path" "$TMPDIR"

    package_basename=$(basename "$package_path")
    package_tmp="$TMPDIR/$package_basename"

    "$PM" install -i "com.android.vending" "$package_tmp" || su -c "${PM} install -i "com.android.vending" $package_tmp"
    result_install_package=$?

    rm -f "$package_tmp"
    return "$result_install_package"
}

check_existed_app() {
    path_apk_toinstall=$1
    apk_package_name=$2

    [ -z "$apk_package_name" ] && return 2

    path_existed_apk=$(fetch_package_path_from_pm "$apk_package_name")

    [ ! -f "$path_apk_toinstall" ] && return 1

    if [ "$FORCE_REPLACE" = true ]; then
        check_and_install_apk "$path_apk_toinstall" "$apk_package_name"
        return $?
    fi

    file_compare "$path_apk_toinstall" "$path_existed_apk"
    result_file_compare=$?

    case "$result_file_compare" in
    0) return 0;;
    1|3) check_and_install_apk "$path_apk_toinstall" "$apk_package_name";;
    esac
}

check_and_install_apk() {
    path_apk_toinstall=$1
    apk_package_name=$2

    uninstall_package "$apk_package_name"
    install_package "$path_apk_toinstall"
    return $?
}

update_config_var() {
    key_name="$1"
    key_value="$2"
    file_path="$3"

    if [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ]; then
        return 1
    elif [ ! -f "$file_path" ]; then
        return 2
    fi

    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"
    result_update_value=$?
    return "$result_update_value"
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

SafetyCore="com.google.android.safetycore"
KeyVerifier="com.google.android.contactkeys"

PH_SafetyCore="$PH_DIR/SafetyCorePlaceHolder.apk"
PH_KeyVerifier="$PH_DIR/KeyVerifierPlaceHolder.apk"

check_existed_app "$PH_SafetyCore" "$SafetyCore" && replaced_sc=true
check_existed_app "$PH_KeyVerifier" "$KeyVerifier" && replaced_kv=true

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
