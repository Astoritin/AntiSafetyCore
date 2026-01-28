#!/system/bin/sh

ecol() {
    length=39
    symbol=*

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    echo " 
$line
 "
}

uninstall_app() {
    package_name=$1
    app_name=$2

    if pm list packages | grep -Fxq "package:$package_name"; then
        echo "Uninstalling current $app_name app"
        pm uninstall "$package_name" >/dev/null 2>&1 && return 0
        echo "$app_name uninstall failed, state $?"
    else
        echo "$app_name not present, skipped"
    fi
}

MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"

ecol
echo "Anti SafetyCore"
echo "By Astoritin"
ecol
echo "$MOD_INTRO"
ecol
echo "This action will uninstall current"
echo "SafetyCore & KeyVerifier app"
ecol
echo "Just a workaround of shameless Google"
echo "installing original apps in the background again"
ecol
echo "Don't worry"
echo "PlaceHolder apps will be installed"
echo "again after once reboot"
ecol
sleep 2
echo "Uninstalling current SafetyCore app..."
uninstall_app "com.google.android.safetycore" "SafetyCore"
sleep 1
echo "Uninstalling current KeyVerifier app..."
uninstall_app "com.google.android.contactkeys" "KeyVerifier"
ecol
echo "Done"