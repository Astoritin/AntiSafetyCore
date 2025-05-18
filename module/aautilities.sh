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

init_logowl() {

    LOG_DIR="$1"

    if [ -z "$LOG_DIR" ]; then
        logowl "Log dir is NOT ordered! (1)" "ERROR"
        return 1
    fi

    if [ ! -d "$LOG_DIR" ]; then
        logowl "Log dir $LOG_DIR does NOT exist"
        mkdir -p "$LOG_DIR" || {
            logowl "Failed to create $LOG_DIR (2)" "ERROR"
            return 2
        }
        logowl "Created $LOG_DIR"
    fi

}

logowl() {

    LOG_MSG="$1"
    LOG_MSG_LEVEL="$2"
    LOG_MSG_PREFIX=""

    [ -z "$LOG_MSG" ] && return 1

    case "$LOG_MSG_LEVEL" in
        "TIPS") LOG_MSG_PREFIX="* " ;;
        "WARN") LOG_MSG_PREFIX="- Warn: " ;;
        "ERROR") LOG_MSG_PREFIX="! ERROR: " ;;
        "FATAL") LOG_MSG_PREFIX="× FATAL: " ;;
        "SPACE") LOG_MSG_PREFIX="  " ;;
        "NONE") LOG_MSG_PREFIX="" ;;
        *) LOG_MSG_PREFIX="- " ;;
    esac

    if [ -n "$LOG_FILE" ]; then
        if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
            echo "----------------------------------------------------------------------" >> "$LOG_FILE"
            echo "${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
            echo "----------------------------------------------------------------------" >> "$LOG_FILE"
        elif [ "$LOG_MSG_LEVEL" = "NONE" ]; then
            echo "$LOG_MSG" >> "$LOG_FILE"
        else
            echo "${LOG_MSG_PREFIX}${LOG_MSG}" >> "$LOG_FILE"
        fi
    else
        if command -v ui_print >/dev/null 2>&1; then
            if [ "$LOG_MSG_LEVEL" = "ERROR" ] || [ "$LOG_MSG_LEVEL" = "FATAL" ]; then
                ui_print "----------------------------------------------------------------------"
                ui_print "${LOG_MSG_PREFIX}${LOG_MSG}"
                ui_print "----------------------------------------------------------------------"
            elif [ "$LOG_MSG_LEVEL" = "NONE" ]; then
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

    length=${1:-70}

    line=$(printf "%-${length}s" | tr ' ' '-')
    logowl "$line" "NONE"
}

init_variables() {
    key="$1"
    config_file="$2"

    if [ -z "$key" ]; then
        logowl "Key is NOT ordered! (1)" "ERROR"
        return 1
    fi

    if [ ! -f "$config_file" ]; then
        logowl "Config file $config_file does NOT exist (1)" "ERROR" >&2
        return 1
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
                    if (in_quote) {
                        print "! Error: Unclosed quote for key " key > "/dev/stderr"
                        exit 1
                    }
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

    awk_exit_status=$?

    case $awk_exit_status in
        1)
            logowl "Key '$key' does NOT exist in $config_file (5)" "WARN" >&2
            return 5
            ;;
        0)  ;;
        *)  logowl "Error occurred as processing key '$key' in $config_file ($awk_exit_status)" "WARN" >&2
            return 6
            ;;
    esac

    value=$(printf "%s" "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if check_value_safety "$key" "$value"; then
        echo "$value"
        return 0
    else
        return $?
    fi
}

check_value_safety() {

    key="$1"
    value="$2"

    check_param_safety "$key"
    result_check_key=$?

    if [ "$result_check_key" = 0 ]; then
        if [ "$value" = true ] || [ "$value" = false ]; then
            logowl "Verified $key=$value (boolean)"
            return 0
        fi
    fi

    check_param_safety "$value"
    result_check_value=$?

    if [ "$result_check_key" = 0 ] && [ "$result_check_value" = 0 ]; then
        logowl "Verified $key=$value"
        return 0
    else
        logowl "Safety check failed, key: $result_check_key, value: $result_check_value)"
        return 1
    fi

}

check_param_safety() {
    param=$1

    [ -z "$param" ] && return 1

    param=$(printf "%s" "$param" | sed 's/'\''/'\\\\'\'''\''/g' | sed 's/[$;&|<>`"()]/\\&/g')
    first_char=$(printf '%s' "$param" | cut -c1)

    [ "$first_char" = "#" ] && return 2
    
    param=$(echo "$param" | cut -d'#' -f1 | xargs)

    regex='^[a-zA-Z0-9/_\. @-]*$'
    dangerous_chars='[`$();|<>]'

    if echo "$param" | grep -Eq "$dangerous_chars"; then
        return 3
    fi

    if ! echo "$param" | grep -Eq "$regex"; then
        return 4
    fi

    return 0
}

verify_variables() {
  
    config_var_name="$1"
    config_var_value="$2"
    validation_pattern="$3"
    default_value="${4:-}"

    script_var_name=$(echo "$config_var_name" | tr '[:lower:]' '[:upper:]')

    if [ -z "$config_var_name" ] || [ -z "$config_var_value" ] || [ -z "$validation_pattern" ]; then
        return 1    
    elif echo "$config_var_value" | grep -qE "$validation_pattern"; then
        export "$script_var_name"="$config_var_value"
        logowl "Set $script_var_name=$config_var_value" "TIPS"
        return 0
    else
        if [ -n "$default_value" ]; then
            if eval "[ -z \"\${$script_var_name+x}\" ]"; then
                logowl "Set $script_var_name=$default_value (default)" "TIPS"
                export "$script_var_name"="$default_value"
            fi
        fi
        return 2
    fi
}

update_config_value() {

    key_name="$1"
    key_value="$2"
    file_path="$3"

    [ -z "$key_name" ] || [ -z "$key_value" ] || [ -z "$file_path" ] && return 1
    [ ! -f "$file_path" ] && return 2

    sed -i "/^${key_name}=/c\\${key_name}=${key_value}" "$file_path"

    result_update_value=$?
    return "$result_update_value"

}

debug_print_values() {

    print_line
    logowl "All Environment variables"
    print_line
    env | sed 's/^/- /'
    print_line
    logowl "All Shell variables"
    print_line
    ( set -o posix; set ) | sed 's/^/- /'
    print_line

}

show_system_info() {

    logowl "Device: $(getprop ro.product.brand) $(getprop ro.product.model) ($(getprop ro.product.device))"
    logowl "OS: Android $(getprop ro.build.version.release) (API $(getprop ro.build.version.sdk)), $(getprop ro.product.cpu.abi | cut -d '-' -f1)"

}

file_compare() {

    file_a="$1"
    file_b="$2"
    
    [ -z "$file_a" ] || [ -z "$file_b" ] && return 2
    
    [ ! -f "$file_a" ] || [ ! -f "$file_b" ] && return 3
    
    hash_file_a=$(sha256sum "$file_a" | awk '{print $1}')
    hash_file_b=$(sha256sum "$file_b" | awk '{print $1}')
    
    [ "$hash_file_a" = "$hash_file_b" ] && return 0
    [ "$hash_file_a" != "$hash_file_b" ] && return 1

}

abort_verify() {

    if [ -n "$VERIFY_DIR" ] && [ -d "$VERIFY_DIR" ] && [ "$VERIFY_DIR" != "/" ]; then
        rm -rf "$VERIFY_DIR"
    fi
    print_line
    logowl "$1" "WARN"
    abort "This zip may be corrupted or have been maliciously modified!"

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
        abort_verify "Failed to verify $file"
    fi
}

clean_old_logs() {
 
    log_dir="$1"
    files_max="$2"
    
    if [ -z "$log_dir" ] || [ ! -d "$log_dir" ]; then
        logowl "$log_dir is not found or is not a dir! (1)" "ERROR"
        return 1
    fi

    if [ -z "$files_max" ]; then
        files_max=30
    fi

    logowl "Current log dir: $log_dir"
    files_count=$(ls -1 "$log_dir" | wc -l)
    if [ "$files_count" -gt "$files_max" ]; then
        logowl "Clear old logs ($files_count as max allowed $files_max)"
        ls -1t "$log_dir" | tail -n +$((files_max + 1)) | while read -r file; do
            rm -f "$log_dir/$file"
        done
    else
        logowl "$files_count files in $log_dir (max allowed $files_max)"
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

clean_duplicate_items() {

    filed=$1

    if [ -z "$filed" ]; then
        logowl "File is NOT provided! (1)" "ERROR"
        return 1
    elif [ ! -f "$filed" ]; then
        logowl "$filed does NOT exist or is NOT a file! (2)" "ERROR"
        return 2
    fi

    awk '!seen[$0]++' "$filed" > "${filed}.tmp"
    mv "${filed}.tmp" "$filed"
    return 0

}

debug_get_prop() {

    prop_name=$1

    if [ -z "$prop_name" ]; then
        logowl "Property name does NOT exist! (1)" "WARN"
        return 1
    fi
    logowl "$prop_name=$(getprop "$prop_name")"
    return 0
}
