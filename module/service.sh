#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/anti_safetycore"
LOG_FILE="$CONFIG_DIR/asc_$(date +"%Y%m%dT%H%M%S").txt"
PH_DIR="$CONFIG_DIR/placeholder"

MODULE_PROP="$MODDIR/module.prop"
MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"

replaced_sc="false"
replaced_kv="false"
desc_state=""

eco() { echo "$1" >> "$LOG_FILE" 2>/dev/null; }

ecol() {

    length=64
    symbol=-

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    echo "$line" >> "$LOG_FILE" 2>/dev/null

}

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

show_system_info() {

    eco "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    eco "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"
    eco "Kernel: $(uname -r)"

}

get_config_var() {
    key=$1
    config_file=$2

    if [ -z "$key" ] || [ -z "$config_file" ]; then
        return 1
    elif [ ! -f "$config_file" ]; then
        return 2
    fi
    
    value=$(awk -v key="$key" '
        BEGIN {
            key_regex = "^" key "="
            found = 0
            in_quote = 0
            value = ""
        }
        $0 ~ key_regex && !found {
            sub(key_regex, "")
            remaining = $0

            sub(/^[[:space:]]*/, "", remaining)

            if (remaining ~ /^"/) {
                in_quote = 1
                remaining = substr(remaining, 2)

                if (match(remaining, /"([[:space:]]*)$/)) {
                    value = substr(remaining, 1, RSTART - 1)
                    in_quote = 0
                } else {
                    value = remaining
                    while ((getline remaining) > 0) {
                        if (match(remaining, /"([[:space:]]*)$/)) {
                            line_part = substr(remaining, 1, RSTART - 1)
                            value = value "\n" line_part
                            in_quote = 0
                            break
                        } else {
                            value = value "\n" remaining
                        }
                    }
                    if (in_quote) exit 1
                }
                found = 1
            } else {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", remaining)
                value = remaining
                found = 1
            }
            if (found) exit 0
        }
        END {
            if (!found) exit 1
            gsub(/[[:space:]]+$/, "", value)
            print value
        }
    ' "$config_file")

    awk_exit_state=$?
    case $awk_exit_state in
        1)  return 5 ;;
        0)  ;;
        *)  return 6 ;;
    esac

    value=$(echo "$value" | dos2unix | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/'\''/'\\\\'\'''\''/g' | sed 's/[$;&|<>`"()]/\\&/g')

    if [ -n "$value" ]; then
        echo "$value"
        return 0
    else
        return 1
    fi
}

module_intro() {

    MODULE_PROP="$MODDIR/module.prop"
    MOD_NAME="$(get_config_var "name" "$MODULE_PROP")"
    MOD_AUTHOR="$(get_config_var "author" "$MODULE_PROP")"
    MOD_VER="$(get_config_var "version" "$MODULE_PROP") ($(get_config_var "versionCode" "$MODULE_PROP"))"

    install_env_check
    ecol
    eco "$MOD_NAME"
    eco "By $MOD_AUTHOR"
    eco "Version: $MOD_VER"
    eco "Root: $ROOT_SOL_DETAIL"
    ecol

}

file_compare() {
    file_a="$1"
    file_b="$2"

    [ -z "$file_a" ] || [ ! -f "$file_a" ] && return 2
    [ -z "$file_b" ] || [ ! -f "$file_b" ] && return 3
    
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    
    [ "$hash_file_a" = "$hash_file_b" ] && return 0
    [ "$hash_file_a" != "$hash_file_b" ] && return 1

}

fetch_package_path_from_pm() {
    package_name=$1
    output_pm=$(pm path "$package_name")

    [ -z "$output_pm" ] && return 1

    package_path=$(echo "$output_pm" | cut -d':' -f2- | sed 's/^://' | head -n 1)

    echo "$package_path"
}

uninstall_package() {
    package_name="$1"
    countdown=60
    elapsed=0

    while pm list packages | grep -q "$package_name"; do

        pm uninstall "$package_name"
        result_uninstall_package=$?
    
        if [ "$result_uninstall_package" -eq 0 ]; then
            eco "Uninstall successfully"
            return 0
        elif [ "$elapsed" -ge "$countdown" ]; then
            eco "Uninstall failed (${result_uninstall_package}), elapsed ${elapsed} x 2"
            return 1
        fi
        elapsed=$((elapsed + 1))
        sleep 2
    done

    eco "Package ${package_name} not found"
    return 2
}

install_package() {
    package_path="$1"
    TMPDIR="/data/local/tmp"

    cp "$package_path" "$TMPDIR"
    eco "cp $package_path $TMPDIR"

    package_basename=$(basename "$package_path")
    package_tmp="$TMPDIR/$package_basename"

    pm install -i "com.android.vending" "$package_tmp"
    result_install_package=$?

    rm -f "$package_tmp"
    return "$result_install_package"
}

check_and_install_apk() {
    apk_to_install=$1
    apk_package_name=$2

    eco "Checking ${apk_package_name} (${apk_to_install})"
    uninstall_package "$apk_package_name"
    install_package "$apk_to_install"
    return $?
}

check_existed_app() {
    apk_to_install=$1
    apk_package_name=$2

    if [ ! -f "$apk_to_install" ]; then
        eco "${apk_to_install} does not exist"
        return 1
    fi
    if [ -z "$apk_package_name" ]; then
        eco "${apk_package_name} is empty"
        return 2
    fi

    if [ "$FORCE_REPLACE" = true ]; then
        check_and_install_apk "$apk_to_install" "$apk_package_name"
        return $?
    fi

    existed_apk_path=$(fetch_package_path_from_pm "$apk_package_name")
    file_compare "$apk_to_install" "$existed_apk_path"
    case "$?" in
    0)  eco "Same, no need to uninstall & install again"
        return 0;;
    1|3)    eco "Different, start uninstalling & installing" 
            check_and_install_apk "$apk_to_install" "$apk_package_name";;
    esac
}

update_config_var() {
    key_name="$1"
    file_path="$2"
    expected_value="$3"
    append_mode="${4:-false}"

    if [ -z "$key_name" ] || [ -z "$expected_value" ] || [ -z "$file_path" ]; then
        return 1
    elif [ ! -f "$file_path" ]; then
        return 2
    fi

    if grep -q "^${key_name}=" "$file_path"; then
        [ "$append_mode" = true ] && return 0
        sed -i "/^${key_name}=/c\\${key_name}=${expected_value}" "$file_path"
    else
        [ -n "$(tail -c1 "$file_path")" ] && echo >> "$file_path"
        printf '%s=%s\n' "$key_name" "$expected_value" >> "$file_path"
    fi

    result_update_value=$?
    return "$result_update_value"
}

module_cleanup_schedule() {

    POST_D="/data/adb/post-fs-data.d/"
    CLEANUP_SH="cleanup_anti_safetycore.sh"
    CLEANUP_PATH="${POST_D}/${CLEANUP_SH}"

    if [ ! -f "$CLEANUP_PATH" ]; then
        mkdir -p "$POST_D"
        cat "$MODDIR/${CLEANUP_SH}" > "$CLEANUP_PATH"
        chmod +x "$CLEANUP_PATH"
    fi

}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

init_dir "$CONFIG_DIR"
module_intro
show_system_info
ecol

SafetyCore="com.google.android.safetycore"
KeyVerifier="com.google.android.contactkeys"

PH_SafetyCore="$PH_DIR/SafetyCorePlaceHolder.apk"
PH_KeyVerifier="$PH_DIR/KeyVerifierPlaceHolder.apk"

check_existed_app "$PH_SafetyCore" "$SafetyCore" && replaced_sc=true
check_existed_app "$PH_KeyVerifier" "$KeyVerifier" && replaced_kv=true

mod_state="✅Done."
mod_prefix=""
mod_separator=", "
mod_slain_sc="✅SafetyCore"
mod_slain_kv="✅KeyVerifier"

if [ "$replaced_sc" = "false" ] && [ "$replaced_kv" = "false" ]; then
    mod_state="❌No effect."
    mod_prefix="Something went wrong!"
    mod_separator=""
elif [ "$replaced_sc" = "true" ] && [ "$replaced_kv" = "true" ]; then
    mod_state="✅All done."
elif [ "$replaced_sc" = "true" ]; then
    mod_slain_kv=""
elif [ "$replaced_kv" = "true" ]; then
    mod_slain_sc=""
fi

DESCRIPTION="[${mod_state} ${mod_prefix}${mod_slain_sc}${mod_separator}${mod_slain_kv}] $MOD_INTRO"
update_config_var "description" "$MODULE_PROP" "$DESCRIPTION"
module_cleanup_schedule