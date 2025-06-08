#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/asc_core_$(date +"%Y%m%dT%H%M%S").log"

PH_DIR="$CONFIG_DIR/placeholder"
TMP_DIR="/data/local/tmp"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_INTRO="Fight against SafetyCore and KeyVerifier installed by Google quietly."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")

fetch_package_path_from_pm() {
    package_name=$1
    output_pm=$(pm path "$package_name")

    if [ -z "$output_pm" ]; then
        logowl "Package $package_name is NOT available!" "ERROR"
        return 1
    fi
    logowl "Output from pm: $output_pm"

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' )
    logowl "Full apk file path of ${package_name}: $package_path"

    echo "$package_path"    
}

fetch_file_size() {
    file_path=$1
    output_du=$(du -k "$file_path")

    if [ -z "$output_du" ]; then
        logowl "File path $file_path is NOT available!" "ERROR"
        return 1
    fi

    logowl "Output from du: $output_du"

    file_size=$(echo "$output_du" | grep -o -E '^[0-9]+')
    logowl "Size of file ${file_path}: $file_size K"

    if [ -n "$file_size" ]; then
        echo "$file_size"
        return 0
    else
        return 1
    fi

}

compare_file_size() {
    file_path_a=$1
    file_path_b=$2

    [ ! -f "$file_path_a" ] || [ ! -f "$file_path_b" ] && return 1

    size_file_a=$(fetch_file_size "$file_path_a")
    size_file_b=$(fetch_file_size "$file_path_b")

    if [ "$size_apk_a" -ne "$size_apk_b" ]; then
        logowl "A != B"
        return 1
    else
        logowl "A == B"
        return 0
    fi

}

uninstall_package() {

    package_name="$1"

    logowl "Execute: pm uninstall $package_name"
    pm uninstall "$package_name"
    result_uninstall_package=$?

    return "$result_uninstall_package"

}

install_package() {

    package_path="$1"

    logowl "Execute: cp $package_path $TMP_DIR"

    cp "$package_path" "$TMP_DIR"

    package_basename=$(basename "$package_path")
    package_tmp="$TMP_DIR/$package_basename"

    logowl "Execute: pm install -i com.android.vending $package_tmp"
    pm install -i "com.android.vending" "$package_tmp"
    result_install_package=$?

    logowl "Execute: rm -f $package_tmp"
    rm -f "$package_tmp"
    return "$result_install_package"    

}

install_placeholder_app()  {

    PN_SC="com.google.android.safetycore"
    PN_KV="com.google.android.contactkeys"

    PATH_PH_SC="$PH_DIR/SafetyCorePlaceHolder.apk"
    PATH_PH_KV="$PH_DIR/KeyVerifierPlaceHolder.apk"

    PATH_C_SC=$(fetch_package_path_from_pm "$PN_SC")
    PATH_C_KV=$(fetch_package_path_from_pm "$PN_KV")

    replaced_sc="false"
    replaced_kv="false"
    desc_state=""

    if compare_file_size "$PATH_C_SC" "$PATH_PH_SC"; then
        logowl "No needs to reintall SafetyCore PlaceHolder APP"
        replaced_sc="true"
    else
        replaced_sc="false"
        uninstall_package "$PN_SC"
        [ -f "$PATH_PH_SC" ] && install_package "$PATH_PH_SC" && replaced_sc="true"
    fi

    if compare_file_size "$PATH_C_KV" "$PATH_PH_KV"; then
        logowl "No needs to reintall KeyVerifier PlaceHolder APP"
        replaced_kv="true"
    else
        replaced_kv="false"
        uninstall_package "$PN_KV"
        [ -f "$PATH_PH_KV" ] && install_package "$PATH_PH_KV" && replaced_kv="true"
    fi

    if [ "$replaced_sc" = "true" ] && [ "$replaced_kv" = "true" ]; then
        desc_state="✅All Done. Neutralized: ✅SafetyCore, ✅KeyVerifier"
    elif [ "$replaced_sc" = "true" ]; then
        desc_state="✅Done. Neutralized: ✅SafetyCore"
    elif [ "$replaced_kv" = "true" ]; then
        desc_state="✅Done. Neutralized: ✅KeyVerifier"
    else
        desc_state="❌No effect. Maybe something went wrong?"
    fi

    DESCRIPTION="[$desc_state] $MOD_INTRO"
    update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"

}

[ ! -d "$PH_DIR" ] && return 1

. "$MODDIR/aa-util.sh"

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Start service.sh"
print_line
logowl "Wait for boot complete"
boot_count=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    boot_count=$((boot_count + 1))
    sleep 1
done

logowl "Boot completed after ${boot_count}s!"
install_placeholder_app
logowl_clean "$LOG_DIR" 20