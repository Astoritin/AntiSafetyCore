#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR_OLD="/data/adb/antisafetycore"
CONFIG_DIR="/data/adb/anti_safetycore"

PH_DIR="$CONFIG_DIR/placeholder"

MOD_UPDATE_PATH="$(dirname "$MODPATH")"
MOD_PATH="${MOD_UPDATE_PATH%_update}"
MOD_PATH_OLD="$MOD_PATH/antisafetycore"

MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"

is_magisk() {

    if ! command -v magisk >/dev/null 2>&1; then
        return 1
    fi

    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    case "$MAGISK_V_VER_NAME" in
        *"-alpha"*) MAGISK_BRANCH_NAME="Alpha" ;;
        *"-lite"*)  MAGISK_BRANCH_NAME="Magisk Lite" ;;
        *"-kitsune"*) MAGISK_BRANCH_NAME="Kitsune Mask" ;;
        *"-delta"*) MAGISK_BRANCH_NAME="Magisk Delta" ;;
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

    MAGISK_BRANCH_NAME="Official"
    ROOT_SOL="Magisk"
    ROOT_SOL_COUNT=0

    is_kernelsu && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_apatch && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))
    is_magisk && ROOT_SOL_COUNT=$((ROOT_SOL_COUNT + 1))

    if [ "$DETECT_KSU" = "true" ]; then
        ROOT_SOL="KernelSU"
        ROOT_SOL_DETAIL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
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

init_dir() {
	[ $# -eq 0 ] && return 1

    for dir_to_init in "$@"; do
		[ -z "$dir_to_init" ] && continue
		[ ! -d "$dir_to_init" ] && mkdir -p "$dir_to_init"
	done
}

ecos() { ui_print "  $1"; }

ecol() {

    length=39
    symbol=*

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    ui_print "$line"

}

show_system_info() {

    ui_print "- Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    ui_print "- OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"
    ui_print "- Kernel: $(uname -r)"

}

extract() {
    file=$1
    dir=$2
    junk=${3:-false}
    opts="-o"

    [ -z "$dir" ] && dir="$MODPATH"
    file_path="$dir/$file"
    hash_path="$TMPDIR/$file.sha256"

    if [ "$junk" = true ]; then
        opts="-oj"
        file_path="$dir/$(basename "$file")"
        hash_path="$TMPDIR/$(basename "$file").sha256"
    fi

    unzip $opts "$ZIPFILE" "$file" -d "$dir" >&2
    [ -f "$file_path" ] || abort "! $file does NOT exist"

    unzip $opts "$ZIPFILE" "${file}.sha256" -d "$TMPDIR" >&2
    [ -f "$hash_path" ] || abort "! ${file}.sha256 does NOT exist"

    expected_hash="$(cat "$hash_path")"
    calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

    if [ "$expected_hash" == "$calculated_hash" ]; then
        ui_print "- Verified $file" >&1
    else
        abort "! Failed to verify $file"
    fi
}

extract "customize.sh" "$TMPDIR"

ui_print "- Setting up $MOD_NAME"
ui_print "- Version: $MOD_VER"
show_system_info
install_env_check
ui_print "- Installing from $ROOT_SOL app"
ui_print "- Root: $ROOT_SOL_DETAIL"
[ -d "$MOD_PATH_OLD" ] && rm -f "$MOD_PATH_OLD/update" && ui_print "- Removed update flag from old module id dir"
[ -d "$MOD_PATH_OLD" ] && touch "$MOD_PATH_OLD/remove" && ui_print "- Set remove flag to old module id dir"
[ -d "$CONFIG_DIR_OLD" ] && rm -rf "$CONFIG_DIR_OLD" && ui_print "- Removed old module id configuration dir"
[ -d "$CONFIG_DIR" ] && rm -rf "$CONFIG_DIR" && ui_print "- Removed old configuration dir"
init_dir "$PH_DIR"
extract "module.prop"
extract "service.sh"
extract "action.sh"
extract "uninstall.sh"
extract "placeholder/SafetyCorePlaceHolder.apk" "$CONFIG_DIR"
extract "placeholder/KeyVerifierPlaceHolder.apk" "$CONFIG_DIR"
ecos " "
ecos "NOTICE & WARNING"
ecol
ecos " "
ecos "Although $MOD_NAME will automatically"
ecos "uninstall and reinstall SafetyCore"
ecos "and KeyVerifier with placeholder APPs"
ecos "on every boot"
ecos " "
ecos "To prevent these APPs from being"
ecos "quietly restored by Google background updates"
ecos "during daily use, please ensure"
ecos "the following options are DISABLED:"
ecos " "
ecos "• Allow downgrade installation"
ecos "• Disable compare signatures"
ecos "  (or disable signature verification)"
ecos " "
ecos "These settings are commonly found in:"
ecos " "
ecos "• Xposed modules (e.g. Core Patch)"
ecos "• Some custom ROMs' built-in options"
ecos " "
ecos "    REBOOT TO TAKE EFFECT    "
ecos " "
ecol
ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644
ui_print "- Welcome to use $MOD_NAME!"
