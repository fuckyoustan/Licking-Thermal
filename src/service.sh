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
    sleep 7
done

eko() {
    local val="$1"; shift
    for p in "$@"; do
        [ -f "$p" ] || continue
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
CHARGE_BACKUP="$MODPATH/chargebackup.txt"
LIMIT_CHARGE="$(find /sys/devices -name charge_control_limit 2>/dev/null)"
rm -f /data/vendor/thermal/config
rm -f /data/vendor/thermal/thermal.dump
rm -f /data/vendor/thermal/thermal_history.dump

Msbreewc() {
    local BASE=/sys/class/power_supply
    local TARGET_CURRENT=5750000
    local TARGET_VOLTAGE=12500000
    local TARGET_SIOP=100
    local TARGET_TEMP_LIMIT=500
    local CURRENT_PATHS=$(ls $BASE/*/constant_charge_current_max $BASE/*/input_current_limit $BASE/*/charge_control_limit $BASE/*/current_max 2>/dev/null)
    local VOLTAGE_PATHS=$(ls $BASE/*/input_voltage_limit $BASE/*/voltage_max 2>/dev/null)
    local SIOP_PATHS=$(ls $BASE/*/siop_level 2>/dev/null)
    local TEMP_LIMIT_PATHS=$(ls $BASE/*/temp_warm $BASE/*/temp_hot 2>/dev/null)
    > "$CHARGE_BACKUP"

    apply_and_backup() {
        local target_val="$1"; shift
        for node in "$@"; do
            [ -f "$node" ] || continue

            local orig_val=$(cat "$node" 2>/dev/null)
            orig_val=${orig_val%"$(printf '\r')"}
            echo "$node|$orig_val" >> "$CHARGE_BACKUP"

            chmod 0666 "$node" 2>/dev/null
            echo "$target_val" > "$node" 2>/dev/null
            chmod 0644 "$node" 2>/dev/null
        done
    }

    apply_and_backup "$TARGET_CURRENT" $CURRENT_PATHS
    apply_and_backup "$TARGET_VOLTAGE" $VOLTAGE_PATHS
    apply_and_backup "$TARGET_SIOP" $SIOP_PATHS
    apply_and_backup "$TARGET_TEMP_LIMIT" $TEMP_LIMIT_PATHS
    
    for a in $LIMIT_CHARGE; do
        eko "0" "$a"
    done
    find /sys/kernel /sys/class -type f \( -iname '*fast_charge*' -o -iname '*boost_mode*' -o -iname '*turbo_mode*' -o -iname '*force_fast_charge*' -o -iname '*fastcharge*' \) 2>/dev/null | while read -r b; do
        eko "1" "$b"
    done
}

Siskaeee() {
    if [ -f "$CHARGE_BACKUP" ]; then
        while IFS='|' read -r node val; do
            if [ -f "$node" ] && [ -n "$val" ]; then
                chmod 0666 "$node" 2>/dev/null
                echo "$val" > "$node" 2>/dev/null
                chmod 0664 "$node" 2>/dev/null
            fi
        done < "$CHARGE_BACKUP"
        rm -f "$CHARGE_BACKUP"
    fi
    
    for a in $LIMIT_CHARGE; do
        eko "1" "$a"
    done
    find /sys/kernel /sys/class -type f \( -iname '*fast_charge*' -o -iname '*boost_mode*' -o -iname '*turbo_mode*' -o -iname '*force_fast_charge*' -o -iname '*fastcharge*' \) 2>/dev/null | while read -r b; do
        eko "0" "$b"
    done
}

echo "NotHorny" > "$STATE_FILE"
for Tits in /sys/block/*/queue; do
    eko "0" "$Tits/iostats"
    eko "0" "$Tits/rotational"
    eko "0" "$Tits/add_random"
    eko "0" "$Tits/iosched/slice_idle"
done

apply_policy() {
    local pol="$1"
    [ -z "$pol" ] && return
    for z in /sys/class/thermal/thermal_zone*; do
        if [ -f "$z/policy" ]; then
            chmod 644 "$z/policy" 2>/dev/null
            echo "$pol" > "$z/policy" 2>/dev/null
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
            [ -f "$1" ] && { chmod +w "$1" 2>/dev/null; echo "$2" > "$1" 2>/dev/null; }
        }
        find /proc/sys /sys -type f \( -name "*panic*" -o -name "exception-trace" -o -name "sched_schedstats" -o -name "tracing_on" -o -name "log_ecn_error" -o -name "snapshot_crashdumper" -o -name "use_spi_crc" \) 2>/dev/null | while read -r path; do
            write_val "$path" "0"
        done
        write_val "/proc/sys/kernel/printk" "0 0 0 0"
        write_val "/proc/sys/kernel/printk_devkmsg" "off"
    fi
fi

read_mode() {
    cat "$STATE_FILE" 2>/dev/null
}

write_mode() {
    printf "%s" "$1" > "$STATE_FILE"
}

Notip() { 
    su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' '$1' '$2'" > /dev/null 2>&1
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
THERMAL_DISABLED="false"
FAST_CHARGE_STATE="false"

sleep 10
while true; do
    if [ -f "$CONF" ]; then
        . "$CONF"
    fi
    
    current_mode="$(read_mode)"
    GLOBAL_POLICY=$(cat "$ZPOLICY" 2>/dev/null)
    GLOBAL_ZONE=$(grep -i '^ZONE=' "$CONF" 2>/dev/null | cut -d'=' -f2)    
    TARGET_STATE="NotHorny"
    active_pkg=""
    USE_HAL="$HAL"
    USE_POLICY="$GLOBAL_POLICY"
    USE_ZONE="${GLOBAL_ZONE:-0}"    
    [ -z "$Charge" ] && Charge="0"
    BAT_STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)

    if [ "$MODE" = "auto" ]; then
        PornApp="$(get_PornApp)"        
        
        if [ -f "$APP_CONFIGS" ]; then
            while read -r line || [ -n "$line" ]; do
                [ -z "$line" ] && continue
                pkg="$(echo "$line" | cut -d':' -f1)"
                if echo "$PornApp" | grep -q "$pkg"; then
                    TARGET_STATE="Horny"
                    active_pkg="$pkg"
                    custom_agg="$(echo "$line" | cut -d':' -f2)"
                    custom_pol="$(echo "$line" | cut -d':' -f3)"
                    custom_zone="$(echo "$line" | cut -d':' -f4)"                
                    
                    [ -n "$custom_agg" ] && USE_HAL="$custom_agg"
                    [ -n "$custom_pol" ] && USE_POLICY="$custom_pol"
                    [ -n "$custom_zone" ] && USE_ZONE="$custom_zone"
                    break
                fi
            done < "$APP_CONFIGS"
        fi

        if [ "$TARGET_STATE" != "Horny" ] && [ -f "$PORN" ]; then
            while read -r pkg || [ -n "$pkg" ]; do
                [ -z "$pkg" ] && continue
                if echo "$PornApp" | grep -q "$pkg"; then
                    TARGET_STATE="Horny"
                    active_pkg="$pkg"
                    break
                fi
            done < "$PORN"
        fi        
    elif [ "$MODE" = "static" ]; then
        TARGET_STATE="Horny"
        active_pkg="STATIC"
    fi

    if [ "$MODE" = "auto" ]; then
        if [ "$Charge" = "1" ] && [ "$BAT_STATUS" = "Charging" ]; then
            if [ "$FAST_CHARGE_STATE" != "true" ]; then
                Msbreewc
                Notip FastCharge "⚡ Fast Charge Enabled: turn off temp for better current"
                FAST_CHARGE_STATE="true"
            fi
        else
            if [ "$FAST_CHARGE_STATE" = "true" ]; then
                Siskaeee
                Notip FastCharge "🔋 Fast Charge Disabled: Restoring normal thermal state."
                FAST_CHARGE_STATE="false"
            fi
        fi
    fi
    
    if [ "$TARGET_STATE" = "Horny" ]; then        
        if [ "$THERMAL_DISABLED" = "false" ] || [ "$CURRENT_PKG" != "$active_pkg" ]; then
            write_mode "Horny"
            CURRENT_PKG="$active_pkg"
            apply_policy "$USE_POLICY"            
            echo "$USE_HAL" > "$MODPATH/CurrentHalState"
            
            if [ "$USE_HAL" = "1" ]; then
                sh "$MODPATH/PornArchive/MILF.sh" "$USE_POLICY" "$USE_ZONE" &
                Notip Tag "🚀 Aggressive mode Apply for $active_pkg"
            else
                sh "$MODPATH/PornArchive/amature.sh" "$USE_POLICY" "$USE_ZONE" &
                Notip Tag "🤡 Amature mode Apply for $active_pkg"
            fi            
            THERMAL_DISABLED="true"
            sleep 3
        fi
    elif [ "$TARGET_STATE" = "NotHorny" ]; then
        if [ "$THERMAL_DISABLED" = "true" ]; then
            write_mode "NotHorny"
            CURRENT_PKG=""
            sh "$MODPATH/PornArchive/anal.sh" &
            Notip Tag "😴 Normal mode Apply"
            THERMAL_DISABLED="false"
            rm -f "$MODPATH/CurrentHalState"
            sleep 3
        fi
    fi
    
    description
    sleep 7
done
