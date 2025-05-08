#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aautilities.sh"

CONFIG_DIR="/data/adb/antisafetycore"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/asc_action_$(date +"%Y%m%dT%H%M%S").log"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

ROOT_FILE_MANAGERS="
com.speedsoftware.rootexplorer/com.speedsoftware.rootexplorer.RootExplorer
com.mixplorer/com.mixplorer.activities.BrowseActivity
bin.mt.plus/.Main
bin.mt.plus/bin.mt.plus.Main
com.ghisler.android.TotalCommander/com.ghisler.android.TotalCommander.MainActivity
pl.solidexplorer2/pl.solidexplorer.activities.MainActivity
com.amaze.filemanager/com.amaze.filemanager.activities.MainActivity
io.github.muntashirakon.AppManager/io.github.muntashirakon.AppManager.fm.FmActivity
io.github.muntashirakon.AppManager.debug/io.github.muntashirakon.AppManager.fm.FmActivity
nextapp.fx/nextapp.fx.ui.ExplorerActivity
me.zhanghai.android.files/me.zhanghai.android.files.filelist.FileListActivity
"

init_logowl "$LOG_DIR"
module_intro
logowl "Start action.sh"

IFS=$'\n'

for fm in $ROOT_FILE_MANAGERS; do

    PKG=${fm%/*}
    ACT=${fm#*/}

    if pm path "$PKG" >/dev/null 2>&1; then
        logowl "Attempt to use $PKG to open config dir"
        su -c "am start -n $fm file://$CONFIG_DIR"
        result_action="$?"
        logowl "Execute: am start -n $fm file://$CONFIG_DIR (code: $result_action)"
        if [ $result_action -eq 0 ]; then
            print_line
            logowl "action.sh case closed!"
            exit 0
        fi
    else
          logowl "$PKG is NOT installed yet!" "ERROR"
    fi

done

sleep 7

logowl "No available Root Explorer detected!" "WARN"
logowl "Please open config dir manually if needed" "WARN"
print_line
logowl "action.sh case closed!"
