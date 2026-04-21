#!/system/bin/sh

module_dir="/data/adb/modules/anti_safetycore"
module_update_dir="/data/adb/modules_update/anti_safetycore"
module_description="GET LOST, SafetyCore & KeyVerifier!"

update_description() { [ -n "$1" ] || return 1; ; }

[ -f "$module_dir/disable" ] && sed -i "s/^description=.*/description=${module_description}/" "$module_dir/module.prop"

if [ -f "/data/adb/anti_safetycore/systemize" ]; then
    rm -f "$module_dir/skip_mount" "$module_update_dir/skip_mount"
else
    touch "$module_update_dir/skip_mount"
    touch "$module_dir/skip_mount"
fi

rm -f "/data/adb/post-fs-data.d/cleanup_anti_safetycore.sh"