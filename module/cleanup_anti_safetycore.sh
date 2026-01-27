#!/system/bin/sh

CONFIG_DIR="/data/adb/anti_safetycore"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

POST_D="/data/adb/post-fs-data.d/"
CLEANUP_SH="cleanup_anti_safetycore.sh"
CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

MODS_DIR="/data/adb/modules"
MODS_UPDATE_DIR="/data/adb/modules_update"
magisk -v | grep -q "lite" && { MODS_DIR="/data/adb/lite_modules"; MODS_UPDATE_DIR="/data/adb/lite_modules_update"; }

MOD_ID="anti_safetycore"
MOD_DIR="$MODS_DIR/$MOD_ID"
MOD_UPDATE_DIR="$MODS_UPDATE_DIR/$MOD_ID"
MOD_DESC="GET LOST, SafetyCore & KeyVerifier!"

update_key_value() {
    key="$1"
    conf="$2"
    expected="$3"
    append="${4:-false}"

    [ -z "$key" ] || [ -z "$expected" ] || [ -z "$conf" ] || [ ! -f "$conf" ] && return 1

    if grep -q "^${key}=" "$conf"; then
        [ "$append" = true ] && return 0
        sed -i "/^${key}=/c\\${key}=${expected}" "$conf"
    else
        [ -n "$(tail -c1 "$conf")" ] && echo >> "$conf"
        printf '%s=%s\n' "$key" "$expected" >> "$conf"
    fi
}

[ -f "$MOD_DIR/disable" ] && update_key_value "description" "$MOD_DIR/module.prop" "$MOD_DESC"

if [ -f "$MARK_SYSTEMIZE" ]; then
    rm -f "$MOD_DIR/skip_mount" "$MOD_UPDATE_DIR/skip_mount"
else
    touch "$MOD_UPDATE_DIR/skip_mount"
    touch "$MOD_DIR/skip_mount"
fi

rm -f "${CLEANUP_PATH}"