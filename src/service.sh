#!/bin/sh

MODPATH="/data/adb/modules/LickingT"
PIDFILE="$MODPATH/daemon.pid"
MYPID=$$

if [ -f "$PIDFILE" ]; then
    OPID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OPID" ] && [ "$OPID" != "$MYPID" ]; then
        if kill -0 "$OPID" 2>/dev/null; then
            kill -9 "$OPID" 2>/dev/null
        fi
    fi
fi

echo "$MYPID" > "$PIDFILE"

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 10
done

eko() {
local val="$1"; shift
for p in "$@"; do
[ -f "$p" ] || continue
chmod 644 "$p" 2>/dev/null
printf '%s' "$val" > "$p" 2>/dev/null
done
}

HAL=0
MODE=auto
PROP="$MODPATH/module.prop"
CONF="$MODPATH/thermal.conf"
ZPOLICY="$MODPATH/zpolicy"
PORN="$MODPATH/PornArchive/PornCategories.txt"
APP_CONFIGS="$MODPATH/AppConfigs.txt"
STATE_FILE="$MODPATH/CurrentState"
echo "NotHorny" > "$STATE_FILE"
for Tits in /sys/block/*/queue; do
eko "0" "$Tits/iostats"
eko "0" "$Tits/rotational"
eko "0" "$Tits/add_random"
done
PKG="com.xiaomi.joyose"
if pm list packages | grep -q "$PKG"; then
cmd package uninstall -k --user 0 "$PKG" >/dev/null 2>&1
fi

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
if [ -f "$CONF" ]; then
    . "$CONF"
    if [ "$DISABLE_PANIC" = "1" ]; then
        write_val() {
            local file="$1"
            local value="$2"
            if [ -f "$file" ]; then
                chmod +w "$file" 2>/dev/null
                echo "$value" > "$file"
            fi
        }

        set_tweak() {
            local name="$1"
            local val="$2"
            find /proc/sys /sys -name "$name" 2>/dev/null | while read -r path; do
                write_val "$path" "$val"
            done
        }

        for p in "*panic*" exception-trace sched_schedstats tracing_on log_ecn_error snapshot_crashdumper use_spi_crc; do
            set_tweak "$p" "0"
        done

        set_tweak "printk" "0 0 0 0"
        set_tweak "printk_devkmsg" "off"
    fi
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
        if [ "$current_mode" != "Horny" ] || [ "$CURRENT_PKG" != "STATIC" ]; then
            write_mode "Horny"
            CURRENT_PKG="STATIC"
            apply_policy "$GLOBAL_POLICY"
            if [ "$HAL" = "1" ]; then
                sh "$MODPATH/PornArchive/MILF.sh" &
                su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '🚀 Aggressive mode Apply (Static)'" > /dev/null 2>&1
            else
                sh "$MODPATH/PornArchive/amature.sh" &
                su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' 'Tag' '🤡 Amature mode Apply (Static)'" > /dev/null 2>&1
            fi
        fi
    fi
    description
    sleep 10
done
