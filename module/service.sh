#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"

PH_DIR="$CONFIG_DIR/placeholder"
TMP_DIR="/data/local/tmp"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="Fight against SafetyCore and KeyVerifier."

fetch_package_path_from_pm() {
    package_name=$1
    output_pm=$(pm path "$package_name")

    [ -z "$output_pm" ] && return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' )

    echo "$package_path"    
}

uninstall_package() {

    package_name="$1"

    pm uninstall "$package_name"
    result_uninstall_package=$?

    return "$result_uninstall_package"

}

install_package() {

    package_path="$1"

    cp "$package_path" "$TMP_DIR"

    package_basename=$(basename "$package_path")
    package_tmp="$TMP_DIR/$package_basename"

    pm install -i "com.android.vending" "$package_tmp"
    result_install_package=$?

    rm -f "$package_tmp"
    return "$result_install_package"    

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

file_compare() {
    file_a="$1"
    file_b="$2"
    
    [ -z "$file_a" ] || [ -z "$file_b" ] && return 2
    [ ! -f "$file_a" ] || [ ! -f "$file_b" ] && return 3
    
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    
    [ "$hash_file_a" = "$hash_file_b" ] && return 0
    [ "$hash_file_a" != "$hash_file_b" ] && return 1

}

install_placeholder_app() {

    PN_SC="com.google.android.safetycore"
    PN_KV="com.google.android.contactkeys"

    PATH_PH_SC="$PH_DIR/SafetyCorePlaceHolder.apk"
    PATH_PH_KV="$PH_DIR/KeyVerifierPlaceHolder.apk"

    PATH_C_SC=$(fetch_package_path_from_pm "$PN_SC")
    PATH_C_KV=$(fetch_package_path_from_pm "$PN_KV")

    replaced_sc="false"
    replaced_kv="false"
    desc_state=""

    if file_compare "$PATH_C_SC" "$PATH_PH_SC"; then
        replaced_sc="true"
    else
        replaced_sc="false"
        uninstall_package "$PN_SC"
        [ -f "$PATH_PH_SC" ] && install_package "$PATH_PH_SC" && replaced_sc="true"
    fi

    if file_compare "$PATH_C_KV" "$PATH_PH_KV"; then
        replaced_kv="true"
    else
        replaced_kv="false"
        uninstall_package "$PN_KV"
        [ -f "$PATH_PH_KV" ] && install_package "$PATH_PH_KV" && replaced_kv="true"
    fi

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

}

[ ! -d "$PH_DIR" ] && return 1

boot_count=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    boot_count=$((boot_count + 1))
    sleep 1
done

install_placeholder_app