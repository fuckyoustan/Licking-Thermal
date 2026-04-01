#!/bin/sh

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 5
done

HAL=0
MODE=auto
MODPATH="/data/adb/modules/LickingT"
PROP="$MODPATH/module.prop"
CONF="$MODPATH/thermal.conf"
ZPOLICY="$MODPATH/zpolicy"
PORN="$MODPATH/PornArchive/PornCategories.txt"
APP_CONFIGS="$MODPATH/AppConfigs.txt"
STATE_FILE="$MODPATH/CurrentState"

[ -f "$STATE_FILE" ] || echo "NotHorny" > "$STATE_FILE"

apply_policy() {
    local pol="$1"
    [ -z "$pol" ] && return
    for z in /sys/class/thermal/thermal_zone*; do
        if [ -f "$z/policy" ]; then
            chmod 644 "$z/policy"
            echo "$pol" > "$z/policy"
        fi
    done
}

if [ -f "$ZPOLICY" ]; then
    SELECTED_POLICY=$(cat "$ZPOLICY")
    apply_policy "$SELECTED_POLICY"
fi

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

CURRENT_PKG=""

while true; do
    if [ -f "$CONF" ]; then
        . "$CONF"
    fi
    current_mode="$(read_mode)"
    GLOBAL_POLICY=$(cat "$ZPOLICY" 2>/dev/null)
    [ -z "$GLOBAL_POLICY" ] && GLOBAL_POLICY="step_wise"

    if [ "$MODE" = "auto" ]; then
        Hyper="NO"
        PornApp="$(get_PornApp)"
        active_pkg=""
        USE_HAL="$HAL"
        USE_POLICY="$GLOBAL_POLICY"

        while read -r pkg || [ -n "$pkg" ]; do
            [ -z "$pkg" ] && continue
            echo "$PornApp" | grep -Eiq "$pkg" && {
                Hyper="YES"
                active_pkg="$pkg"
                break
            }
        done < "$PORN"

        if [ "$Hyper" = "YES" ] && [ -f "$APP_CONFIGS" ]; then
            custom_line="$(grep "^$active_pkg:" "$APP_CONFIGS")"
            if [ -n "$custom_line" ]; then
                custom_agg="$(echo "$custom_line" | cut -d':' -f2)"
                custom_pol="$(echo "$custom_line" | cut -d':' -f3)"
                
                if [ -n "$custom_agg" ] && [ -n "$custom_pol" ]; then
                    USE_HAL="$custom_agg"
                    USE_POLICY="$custom_pol"
                fi
            fi
        fi

        if [ "$Hyper" = "YES" ]; then
            if [ "$current_mode" != "Horny" ] || [ "$CURRENT_PKG" != "$active_pkg" ]; then
                write_mode "Horny"
                CURRENT_PKG="$active_pkg"
                apply_policy "$USE_POLICY"
                
                if [ "$USE_HAL" = "1" ]; then
                    sh "$MODPATH/PornArchive/MILF.sh" &
                    su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '🚀 Aggressive mode Apply for $active_pkg'" > /dev/null 2>&1
                else
                    sh "$MODPATH/PornArchive/amature.sh" &
                    su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '🤡 Amature mode Apply for $active_pkg'" > /dev/null 2>&1
                fi
            fi
        elif [ "$Hyper" = "NO" ] && [ "$current_mode" != "NotHorny" ]; then
            write_mode "NotHorny"
            CURRENT_PKG=""
            apply_policy "$GLOBAL_POLICY"
            sh "$MODPATH/PornArchive/anal.sh" &
            su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '😴 Normal mode Apply'" > /dev/null 2>&1
        fi
        
    elif [ "$MODE" = "static" ]; then
        if [ "$current_mode" != "Horny" ]; then
            write_mode "Horny"
            CURRENT_PKG="STATIC"
            apply_policy "$GLOBAL_POLICY"
            if [ "$HAL" = "1" ]; then
                sh "$MODPATH/PornArchive/MILF.sh" &
                su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '🚀 Aggressive mode Apply'" > /dev/null 2>&1
            else
                sh "$MODPATH/PornArchive/amature.sh" &
                su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '🤡 Amature mode Apply'" > /dev/null 2>&1
            fi
        fi
    fi
    description
    sleep 10
done
