#!/system/bin/sh
MODDIR=${0%/*}

FORCE_REPLACE=true

CONFIG_DIR="/data/adb/antisafetycore"
PH_DIR="$CONFIG_DIR/placeholder"
decide_timeout=3

MOD_INTRO="Fight against SafetyCore and KeyVerifier."
SEPARATE_LINE="---------------------------------------------"

echo "$SEPARATE_LINE"
echo "- Anti SafetyCore"
echo "- By Astoritin Ambrosius"
echo "$SEPARATE_LINE"
echo "- $MOD_INTRO"
echo "$SEPARATE_LINE"
echo "- Replace SafetyCore and KeyVerifier"
echo "- with placeholder app forcefully"
echo "- (ignore different APKs check)"
echo "- will start after ${decide_timeout}s"
echo "$SEPARATE_LINE"
echo "- Press volume down button to skip replacing"
echo "$SEPARATE_LINE"

if [ ! -d "$PH_DIR" ]; then
    echo "- Placeholder dir does NOT exist!"
    return 1
fi

keypress_record=$(timeout "$decide_timeout" getevent -ql 2>/dev/null)
result_check_keypress=$?
if [ "$result_check_keypress" -eq 142 ]; then
    echo "- You do NOT press any key in ${timeout_seconds}s"
fi
if echo "$keypress_record" | grep -q "KEY_VOLUMEDOWN"; then
    echo "- You have pressed key volume down"
    echo "- Skip replacing"
    exit 0
fi

. "$MODDIR/service.sh" && echo "- Replace with placeholder apks"

echo "$SEPARATE_LINE"
echo "- Case closed!"