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
    DETECT_MAGISK_DETAIL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    return 0

}

is_kernelsu() {
    if [ -n "$KSU" ]; then
        DETECT_KSU="true"
        DETECT_KSU_DETAIL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
        ROOT_SOL="KernelSU"
        return 0
    fi
    return 1
}

is_apatch() {
    if [ -n "$APATCH" ]; then
        DETECT_APATCH="true"
        DETECT_APATCH_DETAIL="APatch ($APATCH_VER_CODE)"
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
        ROOT_SOL_DETAIL="KernelSU (kernel:$KSU_KERNEL_VER_CODE, ksud:$KSU_VER_CODE)"
        if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
            ROOT_SOL="Multiple"
            if [ "$DETECT_APATCH" = "true" ] && [ "$DETECT_MAGISK" = "true" ]; then
                ROOT_SOL_DETAIL="Multiple (${DETECT_MAGISK_DETAIL};${DETECT_KSU_DETAIL};${DETECT_APATCH_DETAIL})"
            elif [ "$DETECT_APATCH" = "true" ]; then
                ROOT_SOL_DETAIL="Multiple (${DETECT_KSU_DETAIL};${DETECT_APATCH_DETAIL})"
            elif [ "$DETECT_MAGISK" = "true" ]; then
                ROOT_SOL_DETAIL="Multiple (${DETECT_MAGISK_DETAIL};${DETECT_KSU_DETAIL})"
            fi
        elif [ "$ROOT_SOL_COUNT" -eq 1 ]; then
            ROOT_SOL="KernelSU"
        fi
    elif [ "$DETECT_APATCH" = "true" ]; then
        ROOT_SOL_DETAIL="APatch ($APATCH_VER_CODE)"
        if [ "$ROOT_SOL_COUNT" -gt 1 ] && [ "$DETECT_MAGISK" = "true" ]; then
            ROOT_SOL="Multiple"
            ROOT_SOL_DETAIL="Multiple (${DETECT_MAGISK_DETAIL};${DETECT_APATCH_DETAIL})"
        elif [ "$ROOT_SOL_COUNT" -eq 1 ]; then
            ROOT_SOL="APatch"
        fi
    elif [ "$DETECT_MAGISK" = "true" ]; then
        ROOT_SOL="Magisk"
        ROOT_SOL_DETAIL="$MAGISK_BRANCH_NAME (${MAGISK_VER_CODE:-$MAGISK_V_VER_CODE})"
    fi

    if [ "$ROOT_SOL_COUNT" -lt 1 ]; then
        ROOT_SOL="Unknown"
        ROOT_SOL_DETAIL="Unknown"
    fi

}

module_intro() {

    install_env_check
    print_line
    logowl "$MOD_NAME"
    logowl "By $MOD_AUTHOR"
    logowl "Version: $MOD_VER"
    logowl "Root: $ROOT_SOL_DETAIL"
    logowl "Timestamp: $(date +"%Y-%m-%d %H:%M:%S")"
    logowl "Module dir: $MODDIR"
    print_line

}

logowl() {
    LOG_MSG="$1"
    LOG_MSG_LEVEL="$2"
    LOG_MSG_PREFIX=""

    [ -z "$LOG_MSG" ] && return 1

    case "$LOG_MSG_LEVEL" in
        "TIPS") LOG_MSG_PREFIX="> " ;;
        "WARN") LOG_MSG_PREFIX="- Warn: " ;;
        "ERROR") LOG_MSG_PREFIX="! ERROR: " ;;
        "FATAL") LOG_MSG_PREFIX="× FATAL: " ;;
        " ") LOG_MSG_PREFIX="  " ;;
        "-") LOG_MSG_PREFIX="" ;;
        *) LOG_MSG_PREFIX="- " ;;
    esac

    if [ -n "$LOG_FILE" ]; then
        if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
            echo "----------------------------------------" >> "$LOG_FILE"
            echo "${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
            echo "----------------------------------------" >> "$LOG_FILE"
        elif [ "$LOG_MSG_LEVEL" = "-" ]; then
            echo "$LOG_MSG" >> "$LOG_FILE"
        else
            echo "${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
        fi
    else
        if command -v ui_print >/dev/null 2>&1; then
            if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
                ui_print "----------------------------------------"
                ui_print "${LOG_MSG_PREFIX}${LOG_MSG}"
                ui_print "----------------------------------------"
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

    length=${1:-40}

    line=$(printf "%-${length}s" | tr ' ' '-')
    logowl "$line" "-"
}

update_config_var() {
    key_name="$1"
    key_value="$2"
    file_path="$3"

    [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ] && return 1
    [ ! -f "$file_path" ] && return 2

    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"

    result_update_value=$?
    return "$result_update_value"

}

show_system_info() {

    logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    logowl "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"

}

abort_verify() {

    [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ] && rm -rf "$VERIFY_DIR"
    logowl "$1" "ERROR"
    abort "This zip may be corrupted or has been maliciously modified!"

}

extract() {

    zip=$1
    file=$2
    dir=$3
    junk_paths=${4:-false}
    opts="-o"
    [ $junk_paths = true ] && opts="-oj"

    file_path=""
    hash_path=""
    if [ $junk_paths = true ]; then
        file_path="$dir/$(basename "$file")"
        hash_path="$VERIFY_DIR/$(basename "$file").sha256"
    else
        file_path="$dir/$file"
        hash_path="$VERIFY_DIR/$file.sha256"
    fi

    unzip $opts "$zip" "$file" -d "$dir" >&2
    [ -f "$file_path" ] || abort_verify "$file does NOT exist!"
    logowl "Extract $file → $file_path" >&1

    unzip $opts "$zip" "$file.sha256" -d "$VERIFY_DIR" >&2
    [ -f "$hash_path" ] || abort_verify "$file.sha256 does NOT exist!"

    expected_hash="$(cat "$hash_path")"
    calculated_hash="$(sha256sum "$file_path" | cut -d ' ' -f1)"

    if [ "$expected_hash" == "$calculated_hash" ]; then
        logowl "Verified $file" >&1
    else
        abort_verify "Failed to verify file $file"
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
