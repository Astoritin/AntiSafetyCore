is_magisk() {

    command -v magisk >/dev/null 2>&1 || return 1

    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    case "$MAGISK_V_VER_NAME" in
        *"-alpha"*) MAGISK_BRANCH_NAME="Alpha" ;;
        *) MAGISK_BRANCH_NAME="Magisk" ;;
    esac
    DETECT_MAGISK="true"
    return 0

}

is_kernelsu() {
    if [ -n "$KSU" ]; then
        DETECT_KSU="true"
        ROOT_SOL="KernelSU"
        return 0
    fi
    return 1
}

is_apatch() {
    if [ -n "$APATCH" ]; then
        DETECT_APATCH="true"
        ROOT_SOL="APatch"
        return 0
    fi
    return 1
}

install_env_check() {

    ROOT_SOL="Magisk"
    ROOT_SOL_COUNT=0

    is_kernelsu && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_apatch && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_magisk && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))

    if [ "$DETECT_KSU" = "true" ]; then
        ROOT_SOL="KernelSU"
        ROOT_SOL_DETAIL="KernelSU ($KSU_KERNEL_VER_CODE)"
    elif [ "$DETECT_APATCH" = "true" ]; then
        ROOT_SOL="APatch"
        ROOT_SOL_DETAIL="APatch ($APATCH_VER_CODE)"
    elif [ "$DETECT_MAGISK" = "true" ]; then
        ROOT_SOL="Magisk"
        ROOT_SOL_DETAIL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        ROOT_SOL="Multiple"
        ROOT_SOL_DETAIL="Multiple"
    elif [ "$ROOT_SOL_COUNT" -lt 1 ]; then
        ROOT_SOL="Unknown"
        ROOT_SOL_DETAIL="Unknown"
    fi

}

checkout_modules_dir() {

    current_modules_dir="/data/adb/modules"
    update_modules_dir="/data/adb/modules_update"

    if magisk -v | grep -q "lite"; then
        current_modules_dir="/data/adb/lite_modules"
        update_modules_dir="/data/adb/lite_modules_update"
    fi

}

scan_metamodule() {

    for moddir in "$current_modules_dir" "$update_modules_dir"; do
        [ -d "$moddir" ] || continue
        for current_module_dir in "$moddir"/*; do
            current_module_prop="$current_module_dir/module.prop"
            [ -e "$current_module_prop" ] || continue

            is_metamodule=$(get_key_value "metamodule" "$current_module_prop")
            current_module_name=$(get_key_value "name" "$current_module_prop")
            current_module_ver_name=$(get_key_value "version" "$current_module_prop")
            current_module_ver_code=$(get_key_value "versionCode" "$current_module_prop")
            case "$is_metamodule" in
                1|true ) [ ! -f "$current_module_dir/disable" ] && [ ! -f "$current_module_dir/remove" ] && return 0;;
            esac

        done
    done
    return 1

}

try_metamodule() { [ "$1" = true ] && [ "$2" -ge "$3" ]; }

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
