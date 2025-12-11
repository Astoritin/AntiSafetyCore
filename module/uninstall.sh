#!/system/bin/sh

rm -rf "/data/adb/anti_safetycore"

[ ! -d "/data/adb/service.d/" ] && mkdir -p "/data/adb/service.d"

cat > "/data/adb/service.d/uninstall_anti_safetycore.sh" << 'EOF'
#!/system/bin/sh

data_state=$(resetprop "ro.crypto.state")

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

check_data_encrypted() {
    if [ "$data_state" = "encrypted" ]; then
        return 0
    else
        return 1
    fi
}

check_screen_unlock() {
    keyguard_state=$(dumpsys window policy 2>/dev/null)
    if echo "$keyguard_state" | grep -A5 "KeyguardServiceDelegate" | grep -q "showing=false"; then
        return 0
    fi
    if echo "$keyguard_state" | grep -q -E "mShowingLockscreen=false"; then
        return 0
    fi
    if echo "$keyguard_state" | grep -q -E "mDreamingLockscreen=false"; then
        return 0
    fi

    screen_focus=$(dumpsys window 2>/dev/null | grep -i mCurrentFocus)
    if echo "$screen_focus" | grep -q -E "LAUNCHER|SETTINGS" && ! echo "$screen_focus" | grep -q -i "keyguard|lockscreen"; then
        return 0
    fi
    return 1
}

uninstall_package() {
    package_name="$1"

    if check_data_encrypted; then
        while ! check_screen_unlock; do
            sleep 1
        done
    fi
    pm uninstall "$package_name"

}

while [ "$(getprop vold.decrypt)" = "1" ]; do
    sleep 2
done

uninstall_package "com.google.android.safetycore"
uninstall_package "com.google.android.contactkeys"
rm -f "/data/adb/service.d/uninstall_anti_safetycore.sh"
EOF

chmod +x "/data/adb/service.d/uninstall_anti_safetycore.sh"