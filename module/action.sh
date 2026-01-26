#!/system/bin/sh
MODDIR=${0%/*}

MARK_ACTION_REPLACE=true

ecol() {

    length=39
    symbol=*

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    echo "$line"

}

CONFIG_DIR="/data/adb/anti_safetycore"
PH_DIR="$CONFIG_DIR/placeholder"

wait_timeout=3

MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"

ecol
echo " Anti SafetyCore"
echo " By Astoritin"
ecol
echo " $MOD_INTRO"
ecol
echo " This action is to"
echo " Replace SafetyCore and KeyVerifier"
echo " with placeholder app forcefully"
ecol
echo " Will start after $((wait_timeout - 1)) seconds"
echo " Press any key or"
echo " touch screen at once"
echo " to skip replacing"
ecol

if [ ! -d "$PH_DIR" ]; then
    echo " Placeholder dir does NOT exist!"
    return 1
fi

if read -r -t "$wait_timeout" _ < <(getevent -ql); then
    echo " You have pressed a key"
    echo " or touch screen at once"
    echo " skip replacing"
    return 0
fi
echo " Replace with placeholder apks"

. "$MODDIR/service.sh"

ecol
echo " Done"