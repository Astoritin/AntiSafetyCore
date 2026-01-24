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

keep_running_mark=false
KEEP_RUNNING_MARK="$CONFIG_DIR/keep_running"

POST_D="/data/adb/post-fs-data.d/"
CLEANUP_SH="cleanup_anti_safetycore.sh"
CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

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
[ -f "$KEEP_RUNNING_MARK" ] && keep_running_mark=true
[ -d "$MOD_PATH_OLD" ] && rm -f "$MOD_PATH_OLD/update" && ui_print "- Removed update flag from old module id dir"
[ -d "$MOD_PATH_OLD" ] && touch "$MOD_PATH_OLD/remove" && ui_print "- Set remove flag to old module id dir"
[ -d "$CONFIG_DIR_OLD" ] && rm -rf "$CONFIG_DIR_OLD" && ui_print "- Removed old module id configuration dir"
[ -d "$CONFIG_DIR" ] && rm -rf "$CONFIG_DIR" && ui_print "- Removed old configuration dir"
init_dir "$PH_DIR"
[ "$keep_running_mark" = true ] && touch "$KEEP_RUNNING_MARK"
extract "module.prop"
extract "service.sh"
extract "action.sh"
extract "uninstall.sh"
extract "$CLEANUP_SH"
cat "$MODPATH/$CLEANUP_SH" > "$CLEANUP_PATH"
chmod +x "$CLEANUP_PATH"
extract "placeholder/SafetyCorePlaceHolder.apk" "$CONFIG_DIR"
extract "placeholder/KeyVerifierPlaceHolder.apk" "$CONFIG_DIR"
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
ecos "    REBOOT TO TAKE EFFECT    "
ecoe
ecol
ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644
ui_print "- Welcome to $MOD_NAME!"
