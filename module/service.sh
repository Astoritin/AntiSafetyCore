#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"

LOG_DIR="$CONFIG_DIR/logs"
PH_DIR="$CONFIG_DIR/placeholder"
LOG_FILE="$LOG_DIR/asc_core_$(date +"%Y%m%dT%H%M%S").log"
TMP_DIR="/data/local/tmp"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_INTRO="A Magisk module to fight against Safety Core and Key Verifier installed by Google quietly."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")

deal_with_app() {
    pkg_name=$1
    opt=$2

    [ -z "$pkg_name" ] || [ -z "$opt" ] && return 1

    pkg_basename=$(basename "$pkg_name")
    pkg_tmp_path="$TMP_DIR/$pkg_basename"

    if [ "$opt" = "install" ]; then
        cp "$pkg_name" "$TMP_DIR"
        pm install -i "com.android.vending" "$pkg_tmp_path"
    elif [ "$opt" = "uninstall" ]; then
        pm uninstall "$pkg_name"
    fi

    result_deal_with_app=$?
    if [ "$result_deal_with_app" -eq 0 ]; then
        if [ "$opt" = "install" ]; then
            install_count=$((install_count + 1))
            rm -f "$pkg_tmp_path"
        elif [ "$opt" = "uninstall" ]; then
            uninstall_count=$((uninstall_count + 1))
        fi
        return 0
    else
        [ "$opt" = "install" ] && rm -f "$pkg_tmp_path"
        return "$result_deal_with_app"
    fi

}

install_placeholder_app()  {

    ph_sc=""
    ph_kv=""
    desc_state=""

    deal_with_app "com.google.android.safetycore" "uninstall"
    deal_with_app "com.google.android.contactkeys" "uninstall"

    [ -f "$PH_DIR/SafetyCorePlaceHolder.apk" ] && deal_with_app "$PH_DIR/SafetyCorePlaceHolder.apk" "install" && ph_sc="true"
    [ -f "$PH_DIR/KeyVerifierPlaceHolder.apk" ] && deal_with_app "$PH_DIR/KeyVerifierPlaceHolder.apk" "install" && ph_kv="true"

    if [ "$ph_sc" = "true" ] && [ "$ph_kv" = "true" ]; then
        desc_state="✅All Done. Neutralized: ✅Safety Core, ✅Key Verifier"
    elif [ "$ph_sc" = "true" ]; then
        desc_state="✅Done. Neutralized: ✅Safety Core"
    elif [ "$ph_kv" = "true" ]; then
        desc_state="✅Done. Neutralized: ✅Key Verifier"
    else
        desc_state="❌No effect. Maybe something went wrong?"
    fi

    DESCRIPTION="[$desc_state] $MOD_INTRO"
    update_config_var "description" "$DESCRIPTION" "$MODULE_PROP" "true"

}

. "$MODDIR/aa-util.sh"

[ ! -d "$CONFIG_DIR" ] && return 1
[ ! -d "$PH_DIR" ] && return 1
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
install_placeholder_app
