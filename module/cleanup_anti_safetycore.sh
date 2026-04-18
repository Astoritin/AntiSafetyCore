#!/system/bin/sh

CONFIG_DIR="/data/adb/anti_safetycore"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

POST_D="/data/adb/post-fs-data.d/"
CLEANUP_SH="cleanup_anti_safetycore.sh"
CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

current_modules_dir="/data/adb/modules"
update_modules_dir="/data/adb/modules_update"

module_id="anti_safetycore"
module_dir="$current_modules_dir/$module_id"
module_update_dir="$update_modules_dir/$module_id"
module_description="GET LOST, SafetyCore & KeyVerifier!"

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

[ -f "$module_dir/disable" ] && update_key_value "description" "$module_dir/module.prop" "$module_description"

if [ -f "$MARK_SYSTEMIZE" ]; then
    rm -f "$module_dir/skip_mount" "$module_update_dir/skip_mount"
else
    touch "$module_update_dir/skip_mount"
    touch "$module_dir/skip_mount"
fi

rm -f "${CLEANUP_PATH}"