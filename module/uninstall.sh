#!/system/bin/sh

PACKAGES="com.google.android.safetycore com.google.android.contactkeys"
LOG_DIR="/sdcard/Documents/"
LOG_FILE="$LOG_DIR/uninstall_anti_safetycore_$(date +"%Y%m%dT%H%M%S").txt"

eco() { echo "# $1" >> "$LOG_FILE" 2>/dev/null; }

ecol() {

    length=39
    symbol=#

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    echo "$line" >> "$LOG_FILE" 2>/dev/null

}

ecol
eco " AntiSafety Core Uninstall"
eco " By Astoritin"
ecol

for pkg in $PACKAGES; do
    pm uninstall --user all "$pkg" 2>/dev/null
    result_uninstall=$?
    eco " pm uninstall --user all $pkg ($result_uninstall)"
    if pm list packages | grep -q "$pkg"; then
        eco " $pkg still exists"
        for user in 0 10 11 12 13 14 15; do
            pm uninstall --user "$user" "$pkg" 2>/dev/null
            result_uninstall=$?
            eco "pm uninstall --user $user $pkg ($result_uninstall)"
        done
    fi
done

eco " Done"
rm -rf "/data/adb/anti_safetycore" && eco "Removed /data/adb/anti_safetycore"