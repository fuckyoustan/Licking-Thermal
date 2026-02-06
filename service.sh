#!/system/bin/sh

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 5
done

MODPATH="/data/adb/modules/LickingT"
PROP="$MODPATH/module.prop"
CONF="$MODPATH/thermal.conf"
PORN="$MODPATH/PornArchive/PornCategories.txt"
STATE_FILE="$MODPATH/CurrentState"
TOAST_FILE="/data/local/tmp/ToastProvider"
TOAST_PKG="bellavita.toast"
[ -f "$TOAST_FILE" ] && TOAST_PKG="$(cat "$TOAST_FILE")"
[ -f "$STATE_FILE" ] || echo "NotHorny" > "$STATE_FILE"
read_mode() {
    cat "$STATE_FILE" 2>/dev/null
}
write_mode() {
    printf "%s" "$1" > "$STATE_FILE"
}
get_PornApp() {
    dumpsys window 2>/dev/null | grep "Session Session{" | awk '{print $3}' | awk -F':' '{print $1}' | while read -r pid; do
        [ -r "/proc/$pid/cmdline" ] || continue
        tr '\0' ' ' < /proc/"$pid"/cmdline
    done
}
description() {
    state="$(read_mode)"
    current_desc="$(grep '^description=' "$PROP" 2>/dev/null)"
    case "$state" in
        Horny)
            echo "$current_desc" | grep -q "Running" || sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ ✨ Running ] /g" "$PROP"
            ;;
        *)
            echo "$current_desc" | grep -q "Idle" || sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ 😴 Idle ] /g" "$PROP"
            ;;
    esac
}
HAL=0
MODE=auto
last_conf_hash=""
last_mode=""

while true; do
    current_conf_hash=""
    [ -f "$CONF" ] && {
        . "$CONF"
        current_conf_hash="$(cat "$CONF" 2>/dev/null | md5sum | cut -d' ' -f1)"
    }
    
    current_mode="$(read_mode)"
    
    [ "$current_conf_hash" != "$last_conf_hash" ] || [ "$MODE" != "$last_mode" ] || {
        sleep 10
        continue
    }
    
    last_conf_hash="$current_conf_hash"
    last_mode="$MODE"
    
    if [ "$MODE" = "auto" ]; then
        Hyper="NO"
        PornApp="$(get_PornApp)"
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            case "$PornApp" in
                *$pkg*) Hyper="YES"; break ;;
            esac
        done < "$PORN"
        
        if [ "$Hyper" = "YES" ] && [ "$current_mode" != "Horny" ]; then
            write_mode "Horny"
            if [ "$HAL" = "1" ]; then
                sh "$MODPATH/PornArchive/MILF.sh" &
                am start -a android.intent.action.MAIN -e toasttext "Aggressive LickT for $pkg" -n $TOAST_PKG/.MainActivity &
            else
                sh "$MODPATH/PornArchive/amature.sh" &
                am start -a android.intent.action.MAIN -e toasttext "Amature LickT for $pkg" -n $TOAST_PKG/.MainActivity &
            fi
            wait
        elif [ "$Hyper" = "NO" ] && [ "$current_mode" != "NotHorny" ]; then
            write_mode "NotHorny"
            sh "$MODPATH/PornArchive/anal.sh" &
            am start -a android.intent.action.MAIN -e toasttext "Balance mode active" -n $TOAST_PKG/.MainActivity &
            wait
        fi
    elif [ "$MODE" = "static" ] && [ "$current_mode" != "Horny" ]; then
        write_mode "Horny"
        if [ "$HAL" = "1" ]; then
            sh "$MODPATH/PornArchive/MILF.sh" &
            am start -a android.intent.action.MAIN -e toasttext "Aggressive LickT active" -n $TOAST_PKG/.MainActivity &
        else
            sh "$MODPATH/PornArchive/amature.sh" &
            am start -a android.intent.action.MAIN -e toasttext "Amature LickT active" -n $TOAST_PKG/.MainActivity &
        fi
        wait
    fi
    
    description &
    wait
    sleep 10
done
