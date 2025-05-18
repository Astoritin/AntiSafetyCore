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
MOD_INTRO="A Magisk module to fight against Google Android System SafetyCore and Android System Key Verifier."

MOD_DESC_OLD="$(sed -n 's/^description=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_ROOT_DIR=$(dirname "$MODDIR")

check_module_env() {

    logowl "Essential check"
    if [ ! -d "$CONFIG_DIR" ]; then
        logowl "Config dir $CONFIG_DIR does NOT exist!" "FATAL"
        return 1
    elif [ ! -d "$PH_DIR" ]; then
        logowl "Placeholder dir $PH_DIR does NOT exist!" "FATAL"
        return 1
    fi

}

deal_with_app() {
    pkg_name=$1
    opt=$2

    [ -z "$pkg_name" ] || [ -z "$opt" ] && return 1

    pkg_basename=$(basename "$pkg_name")
    pkg_tmp_path="$TMP_DIR/$pkg_basename"


    if [ "$opt" = "install" ]; then

        cp "$pkg_name" "$TMP_DIR"

        logowl "Install package: $pkg_name"
        logowl "Execute: pm install -i com.android.vending $pkg_tmp_path" "TIPS"

        pm install -i "com.android.vending" "$pkg_tmp_path"

    elif [ "$opt" = "uninstall" ]; then

        logowl "Uninstall package: $pkg_name"
        logowl "Execute: pm uninstall $pkg_name" "TIPS"
    
        pm uninstall "$pkg_name"
    
    fi

    result_deal_with_app=$?
    if [ "$result_deal_with_app" -eq 0 ]; then

        if [ "$opt" = "install" ]; then
            logowl "$pkg_name has been installed"
            install_count=$((install_count + 1))

            rm -f "$pkg_tmp_path"

        elif [ "$opt" = "uninstall" ]; then
            logowl "$pkg_name has been slain"

            uninstall_count=$((uninstall_count + 1))

        fi
        return 0
    else
        logowl "Failed (code: $result_deal_with_app)"

        [ "$opt" = "install" ] && rm -f "$pkg_tmp_path"
        return "$result_deal_with_app"
    fi

}

install_placeholder_app()  {

    logowl "Install placeholder APPs"

    desc_sc=""
    desc_kv=""
    desc_state=""

    deal_with_app "com.google.android.safetycore" "uninstall"
    deal_with_app "com.google.android.contactkeys" "uninstall"

    [ -f "$PH_DIR/SafetyCorePlaceHolder.apk" ] && deal_with_app "$PH_DIR/SafetyCorePlaceHolder.apk" "install" && desc_sc="✅SafetyCore neutralized. "
    [ -f "$PH_DIR/KeyVerifierPlaceHolder.apk" ] && deal_with_app "$PH_DIR/KeyVerifierPlaceHolder.apk" "install" && desc_kv="✅KeyVerifier neutralized."

    if [ -n "$desc_sc" ] && [ -n "$desc_kv" ]; then
        desc_state="✅All Done."
    elif [ -n "$desc_sc" ] || [ -n "$desc_kv" ]; then
        desc_state="✅Done."
    else
        desc_state="❌No effect. Maybe something went wrong?"
    fi

    DESCRIPTION="[$desc_state ${desc_sc}${desc_kv}] $MOD_INTRO"
    update_config_value "description" "$DESCRIPTION" "$MODULE_PROP" "true"

}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Start service.sh"
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
logowl "Boot complete!"
check_module_env && install_placeholder_app
print_line
logowl "service.sh case closed!"
