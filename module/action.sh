#!/system/bin/sh

ecol() {

    length=39
    symbol=*

    line=$(printf "%-${length}s" | tr ' ' "$symbol")
    echo "$line"

}

MOD_INTRO="GET LOST, SafetyCore & KeyVerifier!"

ecol
echo " Anti SafetyCore"
echo " By Astoritin"
ecol
echo " $MOD_INTRO"
ecol
echo " This action is to"
echo " uninstall current SafetyCore"
echo " and KeyVerifier APPs"
ecol
pm uninstall "com.google.android.safetycore"
pm uninstall "com.google.android.contactkeys"
ecol
echo " Done"