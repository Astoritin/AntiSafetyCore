#!/system/bin/sh
MODDIR=${0%/*}

FORCE_REPLACE=true

CONFIG_DIR="/data/adb/antisafetycore"
PH_DIR="$CONFIG_DIR/placeholder"

wait_timeout=4

MOD_INTRO="Fight against SafetyCore and KeyVerifier"
SEPARATE_LINE="---------------------------------------------"

echo "$SEPARATE_LINE"
echo "- Anti SafetyCore"
echo "- By Astoritin Ambrosius"
echo "$SEPARATE_LINE"
echo "- $MOD_INTRO"
echo "$SEPARATE_LINE"
echo "- Replace SafetyCore and KeyVerifier"
echo "- with placeholder app forcefully"
echo "$SEPARATE_LINE"
echo "- Will start after $((wait_timeout - 1)) seconds"
echo "- Press any key or"
echo "- touch screen at once"
echo "- to skip replacing"
echo "$SEPARATE_LINE"

if [ ! -d "$PH_DIR" ]; then
    echo "- Placeholder dir does NOT exist!"
    return 1
fi

if read -r -t "$wait_timeout" _ < <(getevent -ql); then
    echo "- You have pressed a key"
    echo "- or touch screen at once"
    echo "- skip replacing"
    return 0
fi
echo "- Replace with placeholder apks"

. "$MODDIR/service.sh"

echo "$SEPARATE_LINE"
echo "- Case closed!"