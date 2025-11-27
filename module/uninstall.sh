#!/system/bin/sh

rm -rf "/data/adb/anti_safetycore"

[ ! -d "/data/adb/service.d/" ] && mkdir -p "/data/adb/service.d"

cat > "/data/adb/service.d/uninstall_anti_safetycore.sh" << 'EOF'
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
pm uninstall com.google.android.safetycore
pm uninstall com.google.android.contactkeys
rm -f "/data/adb/service.d/uninstall_anti_safetycore.sh"
EOF

chmod +x "/data/adb/service.d/uninstall_anti_safetycore.sh"