#!/system/bin/sh

ecol() {
    length=39
    symbol=*

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    echo " 
$line
 "
}

eco() { echo "- $1"; }

uninstall_app() {
    package_name=$1
    app_name=$2

    if pm list packages | grep -Fxq "package:$package_name"; then
        eco "Uninstalling current $app_name app"
        pm uninstall "$package_name" >/dev/null 2>&1 && return 0
        eco "Failed, state $?"
    else
        eco "$app_name not present, skipped"
    fi
}

MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"

ecol
eco "Anti SafetyCore"
eco "By Astoritin"
ecol
eco "$MOD_INTRO"
ecol
eco "This action will uninstall current"
eco "SafetyCore & KeyVerifier app"
ecol
eco "Just a workaround of shameless Google"
eco "installing original apps"
eco "in the background again"
ecol
eco "Don't worry"
eco "PlaceHolder apps will be installed"
eco "again after once reboot"
ecol
sleep 2
uninstall_app "com.google.android.safetycore" "SafetyCore"
sleep 1
uninstall_app "com.google.android.contactkeys" "KeyVerifier"
ecol
eco "Done"