#!/bin/sh

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 5
done

HAL=0
MODE=auto
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
        NotHorny)
            echo "$current_desc" | grep -q "Balance Mode" || sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ 😴 Balance Mode ] /g" "$PROP"
            ;;
        *)
            echo "$current_desc" | grep -q "Not Working" || sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ ❌ Not Working ] /g" "$PROP"
            ;;
    esac
}

while true; do
    if [ -f "$CONF" ]; then
        . "$CONF"
    fi
    current_mode="$(read_mode)"
    
    if [ "$MODE" = "auto" ]; then
        Hyper="NO"
        PornApp="$(get_PornApp)"
        while read -r pkg || [ -n "$pkg" ]; do
            echo "$PornApp" | grep -Eiq "$pkg" && {
                Hyper="YES"
                break
            }
        done < "$PORN"
        
        if [ "$Hyper" = "YES" ] && [ "$current_mode" != "Horny" ]; then
            write_mode "Horny"
            if [ "$HAL" = "1" ]; then
                LickT --milf &
                am start -a android.intent.action.MAIN -e toasttext "Aggressive LickT for $pkg" -n $TOAST_PKG/.MainActivity
            else
                LickT --amature &
                am start -a android.intent.action.MAIN -e toasttext "Amature LickT for $pkg" -n $TOAST_PKG/.MainActivity
            fi
        elif [ "$Hyper" = "NO" ] && [ "$current_mode" != "NotHorny" ]; then
            write_mode "NotHorny"
            LickT --anal &
            am start -a android.intent.action.MAIN -e toasttext "Balance mode active" -n $TOAST_PKG/.MainActivity
        fi
        
    elif [ "$MODE" = "static" ]; then
        if [ "$current_mode" != "Horny" ]; then
            write_mode "Horny"
            if [ "$HAL" = "1" ]; then
                LickT --milf &
                am start -a android.intent.action.MAIN -e toasttext "Aggressive LickT active" -n $TOAST_PKG/.MainActivity
            else
                LickT --amature &
                am start -a android.intent.action.MAIN -e toasttext "Amature LickT active" -n $TOAST_PKG/.MainActivity
            fi
        fi
    fi
    
    description
    sleep 10
done
