#!/system/bin/sh
SKIPUNZIP=1

CONFIG_DIR="/data/adb/anti_safetycore"
MARK_KEEP_RUNNING="$CONFIG_DIR/keep_running"
MARK_SYSTEMIZE="$CONFIG_DIR/systemize"

MODS_DIR="/data/adb/modules"
MODS_UPDATE_DIR="/data/adb/modules_update"
magisk -v | grep -q "lite" && { MODS_DIR="/data/adb/lite_modules"; MODS_UPDATE_DIR="/data/adb/lite_modules_update"; }

MOD_ID="$(grep_prop id "$TMPDIR/module.prop")"
MOD_NAME="$(grep_prop name "$TMPDIR/module.prop")"
MOD_VER="$(grep_prop version "$TMPDIR/module.prop") ($(grep_prop versionCode "$TMPDIR/module.prop"))"

MOD_ID_OLD="antisafetycore"
MOD_PATH_OLD="$MODS_DIR/$MOD_ID_OLD"
MOD_UPDATE_PATH_OLD="$MODS_UPDATE_DIR/$MOD_ID_OLD"
CONFIG_DIR_OLD="/data/adb/$MOD_ID_OLD"

POST_D="/data/adb/post-fs-data.d/"
CLEANUP_SH="cleanup_anti_safetycore.sh"
CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

mark_keep_running=false
mark_systemize=false

init_dir() {
	[ $# -eq 0 ] && return 1

    for dir_to_init in "$@"; do
		[ -z "$dir_to_init" ] && continue
		[ ! -d "$dir_to_init" ] && mkdir -p "$dir_to_init"
	done
}

ecos() { ui_print "  $1"; }
ecoe() { ui_print " "; }
ecol() {

    length=39
    symbol=*

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    ui_print "$line"

}

extract "com.google.android.contactkeys/com.google.android.contactkeys.apk" "$MODPATH/system/app"
extract "com.google.android.safetycore/com.google.android.safetycore.apk" "$MODPATH/system/app"

extract() {
    file="$1"
    dir="${2:-$MODPATH}"
    junk="${3:-false}"
    opts="-o"

    file_path="$dir/$file"  
    hash_path="$TMPDIR/$file.sha256"

    if [ "$junk" = true ]; then
        opts="-oj"
        file_path="$dir/$(basename "$file")"
        hash_path="$TMPDIR/$(basename "$file").sha256"
    fi

    file_dir="$(dirname $file_path)"
    mkdir -p "$file_dir" || abort "! Failed to create dir $dir!"

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
[ -f "$MARK_KEEP_RUNNING" ] && mark_keep_running=true
[ -f "$MARK_SYSTEMIZE" ] && mark_systemize=true
[ -d "$MOD_PATH_OLD" ] && touch "$MOD_PATH_OLD/remove"
rm -f "$MOD_PATH_OLD/update" > /dev/null 2>&1
rm -rf "$CONFIG_DIR_OLD" "$CONFIG_DIR" > /dev/null 2>&1
init_dir "$CONFIG_DIR"
extract "module.prop"
extract "service.sh"
extract "action.sh"
extract "uninstall.sh"
extract "$CLEANUP_SH"
cat "$MODPATH/$CLEANUP_SH" > "$CLEANUP_PATH"
chmod +x "$CLEANUP_PATH"
extract "com.google.android.contactkeys/com.google.android.contactkeys.apk" "$MODPATH/system/app"
extract "com.google.android.safetycore/com.google.android.safetycore.apk" "$MODPATH/system/app"
[ "$mark_keep_running" = false ] || touch "$MARK_KEEP_RUNNING"
[ "$mark_systemize" = false ] || touch "$MARK_SYSTEMIZE" && touch "$MODPATH/skip_mount"
ecol
ecoe
ecos "              NOTICE"
ecoe
ecol
ecoe
ecos "Although $MOD_NAME will automatically"
ecos "uninstall and reinstall SafetyCore"
ecos "and KeyVerifier with placeholder APPs"
ecos "on every boot"
ecoe
ecos "To prevent these APPs from being"
ecos "quietly restored by Google background updates"
ecos "during daily use, please ensure"
ecos "the following options are DISABLED:"
ecoe
ecos "• Allow downgrade installation"
ecos "• Disable compare signatures"
ecos "  (or disable signature verification)"
ecoe
ecos "These settings are commonly found in:"
ecoe
ecos "• Xposed modules (e.g. Core Patch)"
ecos "• Some custom ROMs' built-in options"
ecoe
ecos "        REBOOT TO TAKE EFFECT"
ecoe
ecol
ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644
ui_print "- Welcome to $MOD_NAME!"
