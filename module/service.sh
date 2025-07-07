#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/antisafetycore"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/asc_core_$(date +"%Y%m%dT%H%M%S").log"

PH_DIR="$CONFIG_DIR/placeholder"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="Fight against SafetyCore and KeyVerifier."

. "$MODDIR/aa-util.sh"

logowl_init "$LOG_DIR"
logowl_clean "30"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line

if [ ! -d "$PH_DIR" ]; then
    logowl "Placeholder dir does NOT exist!" "F"
    return 1
fi

boot_count=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    boot_count=$((boot_count + 1))
    sleep 1
done

logowl "Boot complete after ${boot_count}s!"

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
    logowl "Find installed SafetyCore different from placeholder APP"
    uninstall_package "$PN_SC"
    [ -f "$PATH_PH_SC" ] && install_package "$PATH_PH_SC" && replaced_sc="true"
fi

if file_compare "$PATH_C_KV" "$PATH_PH_KV"; then
    replaced_kv="true"
else
    replaced_kv="false"
    logowl "Find installed KeyVerifier different from placeholder APP"
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
logowl "$SEPARATE_LINE"
logowl "Case closed!"