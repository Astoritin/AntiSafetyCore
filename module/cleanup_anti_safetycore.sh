#!/system/bin/sh

POST_D="/data/adb/post-fs-data.d/"
CLEANUP_SH="cleanup_anti_safetycore.sh"
CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

MODS_DIR="/data/adb/modules"
[ -n "$(magisk -v | grep lite)" ] && MODS_DIR="/data/adb/lite_modules"

MOD_NAME="anti_safetycore"
MOD_DIR="$MODS_DIR/$MOD_NAME"
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

rm -f "${CLEANUP_PATH}"
