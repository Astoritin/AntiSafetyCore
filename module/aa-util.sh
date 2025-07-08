#!/system/bin/sh
MODDIR=${0%/*}

is_magisk() {

    if ! command -v magisk >/dev/null 2>&1; then
        return 1
    fi

    MAGISK_V_VER_NAME="$(magisk -v)"
    MAGISK_V_VER_CODE="$(magisk -V)"
    case "$MAGISK_V_VER_NAME" in
        *"-alpha"*) MAGISK_BRANCH_NAME="Magisk Alpha" ;;
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

logowl_init() {
    LOG_DIR="$1"

    [ -z "$LOG_DIR" ] && return 1
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR" && logowl "Create $LOG_DIR"

}

logowl_clean() {
    log_dir="$1"
    files_max="$2"
    
    [ -z "$log_dir" ] || [ ! -d "$log_dir" ] && return 1
    [ -z "$files_max" ] && files_max=30

    files_count=$(ls -1 "$log_dir" | wc -l)
    if [ "$files_count" -gt "$files_max" ]; then
        ls -1t "$log_dir" | tail -n +$((files_max + 1)) | while read -r file; do
            rm -f "$log_dir/$file"
        done
    fi
    return 0
}

logowl() {
    LOG_MSG="$1"
    LOG_MSG_LEVEL="$2"
    LOG_MSG_PREFIX=""
    SEPARATE_LINE="---------------------------------------------"
    TIMESTAMP_FORMAT="%02d:%02d:%02d:%03d | "

    [ -z "$LOG_MSG" ] && return 1

    case "$LOG_MSG_LEVEL" in
        "W") LOG_MSG_PREFIX="? Warn: " ;;
        "E") LOG_MSG_PREFIX="! ERROR: " ;;
        "F") LOG_MSG_PREFIX="× FATAL: " ;;
        ">") LOG_MSG_PREFIX="> " ;;
        "*" ) LOG_MSG_PREFIX="* " ;; 
        " ") LOG_MSG_PREFIX="  " ;;
        "-") LOG_MSG_PREFIX="" ;;
        *) if [ -n "$LOG_FILE" ]; then
            LOG_MSG_PREFIX=""
            else
            LOG_MSG_PREFIX="- "
            fi
            ;;
    esac

    if [ -n "$LOG_FILE" ]; then
        CURRENT_HOUR=$(date +%H)
        CURRENT_MIN=$(date +%M)
        CURRENT_SEC=$(date +%S)
        CURRENT_MS=$(date +%3N)
        TIME_STAMP=$(printf "$TIMESTAMP_FORMAT" "$CURRENT_HOUR" "$CURRENT_MIN" "$CURRENT_SEC" "$CURRENT_MS")
        if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
            echo "$SEPARATE_LINE" >> "$LOG_FILE"
            echo "${TIME_STAMP}${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
            echo "$SEPARATE_LINE" >> "$LOG_FILE"
        elif [ "$LOG_MSG_LEVEL" = "-" ]; then
            echo "${LOG_MSG}" >> "$LOG_FILE"
        else
            echo "${TIME_STAMP}${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
        fi
    else
        if command -v ui_print >/dev/null 2>&1; then
            if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
                ui_print "$SEPARATE_LINE"
                ui_print "${LOG_MSG_PREFIX}${LOG_MSG}"
                ui_print "$SEPARATE_LINE"
            elif [ "$LOG_MSG_LEVEL" = "-" ]; then
                ui_print "$LOG_MSG"
            else
                ui_print "${LOG_MSG_PREFIX}${LOG_MSG}"
            fi
        else
            echo "${LOG_MSG_PREFIX}${LOG_MSG}"
        fi
    fi
}

print_line() {

    length=${1:-51}
    symbol=${2:--}

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    logowl "$line" "-"

}

grep_config_var() {
    regex="s/^$1=//p"
    config_file="$2"

    [ -z "$config_file" ] && config_file="/system/build.prop"
    cat "$config_file" 2>/dev/null | dos2unix | sed -n "$regex" | head -n 1

}

update_config_var() {
    key_name="$1"
    key_value="$2"
    file_path="$3"

    if [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ]; then
        return 1
    elif [ ! -f "$file_path" ]; then
        return 2
    fi

    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"
    result_update_value=$?
    return "$result_update_value"

}

show_system_info() {

    logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    logowl "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"
    logowl "Kernel: $(uname -r)"

}

module_intro() {

    MODULE_PROP="$MODDIR/module.prop"
    MOD_NAME="$(grep_config_var "name" "$MODULE_PROP")"
    MOD_AUTHOR="$(grep_config_var "author" "$MODULE_PROP")"
    MOD_VER="$(grep_config_var "version" "$MODULE_PROP") ($(grep_config_var "versionCode" "$MODULE_PROP"))"

    install_env_check
    print_line
    logowl "$MOD_NAME"
    logowl "By $MOD_AUTHOR"
    logowl "Version: $MOD_VER"
    logowl "Root: $ROOT_SOL_DETAIL"
    print_line

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
        logowl "Verified $file" >&1
    else
        abort "! Failed to verify $file"
    fi
}

set_permission() {

    chown $2:$3 $1 || return 1    
    chmod $4 $1 || return 1
    
    selinux_content=$5
    [ -z "$selinux_content" ] && selinux_content=u:object_r:system_file:s0
    chcon $selinux_content $1 || return 1

}

set_permission_recursive() {

    find $1 -type d 2>/dev/null | while read dir; do
        set_permission $dir $2 $3 $4 $6
    done

    find $1 -type f -o -type l 2>/dev/null | while read file; do
        set_permission $file $2 $3 $5 $6
    done

}
