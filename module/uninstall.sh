#!/system/bin/sh

rm -rf "/data/adb/anti_safetycore"

[ ! -d "/data/adb/service.d/" ] && mkdir -p "/data/adb/service.d"

cat > "/data/adb/service.d/uninstall_anti_safetycore.sh" << 'EOF'
#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

uninstall_package() {
    package_name="$1"
    countdown=60
    elapsed=0

    while pm list packages | grep -q "$package_name"; do

        pm uninstall "$package_name"
        result_uninstall_package=$?
    
        if [ "$result_uninstall_package" -eq 0 ]; then
            return 0
        elif [ "$elapsed" -ge "$countdown" ]; then
            return 1
        fi
        elapsed=$((elapsed + 1))
        sleep 2
    done

    return 2
}

while [ "$(getprop vold.decrypt)" = "1" ]; do
    sleep 2
done

uninstall_package "com.google.android.safetycore"
uninstall_package "com.google.android.contactkeys"
rm -f "/data/adb/service.d/uninstall_anti_safetycore.sh"
EOF

chmod +x "/data/adb/service.d/uninstall_anti_safetycore.sh"