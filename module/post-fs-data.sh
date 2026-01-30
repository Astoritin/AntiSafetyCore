#!/system/bin/sh

CONFIG_DIR="/data/adb/anti_safetycore"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

MODS_DIR="/data/adb/modules"
MODS_UPDATE_DIR="/data/adb/modules_update"
magisk -v | grep -q "lite" && { MODS_DIR="/data/adb/lite_modules"; MODS_UPDATE_DIR="/data/adb/lite_modules_update"; }

MOD_ID="anti_safetycore"
MOD_DIR="$MODS_DIR/$MOD_ID"
MOD_UPDATE_DIR="$MODS_UPDATE_DIR/$MOD_ID"

if [ -f "$MARK_SYSTEMIZE" ]; then
    rm -f "$MOD_DIR/skip_mount" "$MOD_UPDATE_DIR/skip_mount"
else
    touch "$MOD_UPDATE_DIR/skip_mount"
    touch "$MOD_DIR/skip_mount"
fi