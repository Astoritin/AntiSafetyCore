#!/system/bin/sh

CONFIG_DIR="/data/adb/anti_safetycore"
PH_DIR="$CONFIG_DIR/placeholder"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

POST_D="/data/adb/post-fs-data.d/"
CLEANUP_SH="cleanup_anti_safetycore.sh"
CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

MODS_DIR="/data/adb/modules"
magisk -v | grep -q "lite" && MODS_DIR="/data/adb/lite_modules"

SYSTEMIZE_DIR="$MODS_DIR/system/app"

MOD_NAME="anti_safetycore"
MOD_DIR="$MODS_DIR/$MOD_NAME"
MOD_DESC="GET LOST, SafetyCore & KeyVerifier!"

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

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
    rm -f "$MODS_DIR/skip_mount"
    mkdir -p "$SYSTEMIZE_DIR"
    cp "$PH_DIR" "$SYSTEMIZE_DIR"
    set_perm_recursive "$SYSTEMIZE_DIR" 0 0 0755 0644
else
    rm -rf "$MODS_DIR/system"
fi

rm -f "${CLEANUP_PATH}"