#!/bin/sh

MODPATH="/data/adb/modules/LickingT"
PIDFILE="$MODPATH/daemon.pid"
MYPID=$$

# --- concise debug log (LickT.log) — must never block the module ----------
LICKT_LOG="$MODPATH/LickT.log"
if [ -f "$LICKT_LOG" ] && [ "$(wc -c < "$LICKT_LOG" 2>/dev/null || echo 0)" -gt 262144 ]; then
    tail -n 1000 "$LICKT_LOG" > "${LICKT_LOG}.t.$$" 2>/dev/null && mv -f "${LICKT_LOG}.t.$$" "$LICKT_LOG" 2>/dev/null
fi
lick_log() {
    # $1 = OK | ERR | SKIP | INFO ; $2 = message
    echo "$(date '+%m-%d %H:%M:%S') $1 ${0##*/}: $2" 2>/dev/null >> "$LICKT_LOG" || :
}

# kill a pid only when its /proc cmdline really belongs to this module:
# PIDs are recycled and a stale pidfile must never kill an unrelated root
# process (P1-6)
is_our_process() {
    # $1 = pid; remaining args = glob patterns (one must match the cmdline)
    local pid="$1"; shift
    [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ] || return 1
    local cmd pat
    cmd="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)"
    for pat in "$@"; do
        case "$cmd" in
            $pat) return 0 ;;
        esac
    done
    return 1
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
PANIC_BACKUP="$MODPATH/panicbackup.txt"
BLOCK_BACKUP="$MODPATH/blockbackup.txt"
TRANS_PIDFILE="$MODPATH/transition.pid"
HEARTBEAT="$MODPATH/heartbeat"
LIMIT_CHARGE="$(find /sys/devices -name charge_control_limit 2>/dev/null)"

eko() {
    local val="$1"; shift
    for p in "$@"; do
        [ -f "$p" ] || continue
        printf '%s' "$val" > "$p" 2>/dev/null
    done
}

read_mode() {
    cat "$STATE_FILE" 2>/dev/null
}

write_mode() {
    printf "%s" "$1" > "$STATE_FILE"
}

Notip() {
    # escape single quotes for the child shell: an apostrophe in the message
    # used to corrupt the whole `su -c` payload (P3-20)
    local title message
    title=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
    message=$(printf '%s' "$2" | sed "s/'/'\\\\''/g")
    su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal 💦' '$title' '$message'" > /dev/null 2>&1
}

# Serialize thermal transitions: never allow an apply script (MILF/amature) and
# the restore script (anal) to run at the same time. Overlapping runs write
# opposite values to the same sysfs nodes and race bind-mounts against
# unmounts, which freezes or reboots the device on rapid app switching.
kill_transitions() {
    if [ -f "$TRANS_PIDFILE" ]; then
        OPID="$(cat "$TRANS_PIDFILE" 2>/dev/null)"
        if [ -n "$OPID" ] && kill -0 "$OPID" 2>/dev/null; then
            if is_our_process "$OPID" '*LickingT*' '*PornArchive*'; then
                kill -9 "$OPID" 2>/dev/null
            fi
        fi
        rm -f "$TRANS_PIDFILE" 2>/dev/null
    fi
}

start_transition() {
    kill_transitions
    # always pass every positional arg: an empty policy must not silently
    # drop the zone/AggHal values the caller resolved (P1-8)
    sh "$1" "${2:-}" "${3:-}" "${4:-}" &
    echo $! > "$TRANS_PIDFILE" 2>/dev/null
}

wait_for_transitions() {
    # fast-charge changes must never overlap an in-flight apply/restore: both
    # write the same power_supply nodes and racing them is a freeze class.
    # Bounded wait; if the transition is stuck, kill it and force a re-apply
    # on this same poll.
    local i=0
    while [ "$i" -lt 10 ]; do
        [ -f "$TRANS_PIDFILE" ] || return 0
        TPID="$(cat "$TRANS_PIDFILE" 2>/dev/null)"
        if [ -z "$TPID" ] || ! kill -0 "$TPID" 2>/dev/null; then
            return 0
        fi
        sleep 1
        i=$((i+1))
    done
    kill_transitions
    lick_log ERR "fastcharge: stuck transition killed after 10s wait"
    # the killed transition may have left a half-applied state - force re-apply
    THERMAL_DISABLED="false"
    CURRENT_PKG=""
    LAST_KEY=""
    return 0
}

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
    local SWITCH_PATHS="$(ls $BASE/*/*fast_charge* $BASE/*/*fastcharge* $BASE/*/force_fast_charge 2>/dev/null)
[ -f /sys/kernel/fast_charge/force_fast_charge ] && echo /sys/kernel/fast_charge/force_fast_charge"
    # build the new backup aside and swap it in atomically: a crash mid-apply
    # leaves the PREVIOUS backup intact instead of an empty file (P1-7)
    local TMP_BACKUP="$CHARGE_BACKUP.tmp.$$"

    apply_and_backup() {
        local target_val="$1"; shift
        for node in "$@"; do
            [ -f "$node" ] || continue

            local orig_val=$(cat "$node" 2>/dev/null)
            orig_val=${orig_val%"$(printf '\r')"}
            local orig_mode=$(stat -c %a "$node" 2>/dev/null)
            echo "$node|$orig_val|$orig_mode" >> "$TMP_BACKUP"

            # freeze guard: on several devices these nodes hold the battery
            # cell DESIGN limits (e.g. voltage_max = 4400000 = 4.4V). Forcing
            # a value >= 2x the original pushes the charger IC out of spec and
            # hangs the device while charging - skip nodes that far off.
            case "$orig_val" in
                ''|*[!0-9]*) ;;
                *)
                    if [ "$orig_val" -gt 0 ] && [ "$target_val" -gt 0 ] && [ "$((target_val / orig_val))" -ge 2 ]; then
                        lick_log SKIP "fastcharge: $node skipped (orig=$orig_val target=$target_val)"
                        continue
                    fi
                    ;;
            esac

            chmod 0666 "$node" 2>/dev/null
            echo "$target_val" > "$node" 2>/dev/null
            chmod 0644 "$node" 2>/dev/null
        done
    }

    rm -f "$TMP_BACKUP"
    apply_and_backup "$TARGET_CURRENT" $CURRENT_PATHS
    apply_and_backup "$TARGET_VOLTAGE" $VOLTAGE_PATHS
    apply_and_backup "$TARGET_SIOP" $SIOP_PATHS
    apply_and_backup "$TARGET_TEMP_LIMIT" $TEMP_LIMIT_PATHS
    apply_and_backup "1" $SWITCH_PATHS
    # charge_control_limit gets a real backup too (the restore used to guess "1")
    for a in $LIMIT_CHARGE; do
        [ -f "$a" ] || continue
        echo "$a|$(cat "$a" 2>/dev/null)|$(stat -c %a "$a" 2>/dev/null)" >> "$TMP_BACKUP"
        eko "0" "$a"
    done
    mv -f "$TMP_BACKUP" "$CHARGE_BACKUP" 2>/dev/null
    lick_log INFO "fastcharge applied (backup nodes: $(wc -l < "$CHARGE_BACKUP" 2>/dev/null || echo 0))"
}

Siskaeee() {
    if [ -s "$CHARGE_BACKUP" ]; then
        # restore exactly what was backed up (value + permission mode);
        # entries written by older module versions carry no mode field and
        # fall back to the previous 0664 behaviour
        while IFS='|' read -r node val mode; do
            if [ -f "$node" ] && [ -n "$val" ]; then
                chmod 0666 "$node" 2>/dev/null
                echo "$val" > "$node" 2>/dev/null
                chmod "${mode:-0664}" "$node" 2>/dev/null
            fi
        done < "$CHARGE_BACKUP"
        rm -f "$CHARGE_BACKUP"
    else
        # no/empty backup (lost, or written by a very old version):
        # conservative legacy restore
        rm -f "$CHARGE_BACKUP" 2>/dev/null
        for a in $LIMIT_CHARGE; do
            eko "1" "$a"
        done
        for b in $(ls /sys/class/power_supply/*/*fast_charge* /sys/class/power_supply/*/*fastcharge* /sys/class/power_supply/*/force_fast_charge 2>/dev/null); do
            eko "0" "$b"
        done
        [ -f /sys/kernel/fast_charge/force_fast_charge ] && eko "0" /sys/kernel/fast_charge/force_fast_charge
    fi
    lick_log INFO "fastcharge restored"
}

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

get_PornApp() {
    local pkg=""
    # 1) modern & cheap: the focused window (Android ~10+)
    pkg="$(dumpsys window 2>/dev/null | grep 'mCurrentFocus=' | sed -n 's/.* u[0-9][0-9]* \([A-Za-z0-9._]*\)\/.*/\1/p' | head -n1)"
    # 2) fallback: resumed activity (some OEM builds hide mCurrentFocus)
    if [ -z "$pkg" ]; then
        pkg="$(dumpsys activity activities 2>/dev/null | grep -E 'mResumedActivity|topResumedActivity' | sed -n 's/.* u[0-9][0-9]* \([A-Za-z0-9._]*\)\/.*/\1/p' | head -n1)"
    fi
    if [ -n "$pkg" ]; then
        FG_FAIL_NOTED=""
        echo "$pkg"
        return 0
    fi
    # 3) last resort: legacy session list (old devices) - original behaviour
    local legacy=""
    legacy="$(dumpsys window 2>/dev/null | grep "Session Session{" | awk '{print $3}' | awk -F':' '{print $1}' | while read -r pid; do
        [ -r "/proc/$pid/cmdline" ] || continue
        tr '\0' ' ' < /proc/"$pid"/cmdline
        echo ""
    done)"
    if [ -n "$legacy" ]; then
        FG_FAIL_NOTED=""
        echo "$legacy"
        return 0
    fi
    # all three methods empty: log once (not every poll) so a dead detection
    # is diagnosable instead of silent (P0-1)
    if [ -z "$FG_FAIL_NOTED" ]; then
        lick_log ERR "fg detection empty (no focus/resumed/session line)"
        FG_FAIL_NOTED=1
    fi
}

LAST_DESC_STATE=""
description() {
    state="$(read_mode)"
    # rewrite module.prop only when the state actually changed - reading the
    # prop file every poll was pure overhead (P2-14)
    [ "$state" = "$LAST_DESC_STATE" ] && return 0
    case "$state" in
        Horny)
            sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ ✨ Running ] /g" "$PROP" 2>/dev/null
            ;;
        NotHorny)
            sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ 😴 Balance Mode ] /g" "$PROP" 2>/dev/null
            ;;
        *)
            sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ ❌ Not Working ] /g" "$PROP" 2>/dev/null
            ;;
    esac
    LAST_DESC_STATE="$state"
}

rm -f /data/vendor/thermal/config
rm -f /data/vendor/thermal/thermal.dump
rm -f /data/vendor/thermal/thermal_history.dump

# ---------------------------------------------------------------------------
# startup sequence
# ---------------------------------------------------------------------------

# stale daemon from a previous run / module update: verify identity, restore
# whatever it is holding, then kill it (P1-6 + P0-2)
if [ -f "$PIDFILE" ]; then
    OPID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OPID" ] && [ "$OPID" != "$MYPID" ] && kill -0 "$OPID" 2>/dev/null; then
        if is_our_process "$OPID" '*LickingT*'; then
            if [ "$(read_mode)" = "Horny" ] || [ -f "$CHARGE_BACKUP" ]; then
                sh "$MODPATH/PornArchive/anal.sh" >/dev/null 2>&1
            fi
            [ -f "$CHARGE_BACKUP" ] && Siskaeee
            kill -9 "$OPID" 2>/dev/null
            lick_log INFO "stale daemon pid=$OPID killed (held state restored)"
        else
            lick_log SKIP "stale daemon pid=$OPID ignored (cmdline mismatch)"
        fi
    fi
fi

echo "$MYPID" > "$PIDFILE"

trap 'lick_log INFO "daemon stopping - restoring thermal state"; write_mode "NotHorny"; kill_transitions; sh "$MODPATH/PornArchive/anal.sh" >/dev/null 2>&1; [ "$FAST_CHARGE_STATE" = "true" ] && Siskaeee; rm -f "$PIDFILE" "$HEARTBEAT"; exit 0' TERM INT HUP

# boot wait, bounded: a device whose sys.boot_completed is never set must not
# spin this loop forever (P3-18)
BOOT_WAIT=0
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 7
    BOOT_WAIT=$((BOOT_WAIT + 1))
    if [ "$BOOT_WAIT" -ge 120 ]; then
        lick_log ERR "boot_completed never set after ~14min - proceeding anyway"
        break
    fi
done
lick_log INFO "daemon start (pid=$MYPID)"

# boot-time recovery: a previous session that died mid-aggressive (OOM-kill,
# crash, update) leaves thermal disabled and/or fast-charge forced until
# reboot. Heal it before the loop starts (P0-2 layer 1).
rm -f "$CHARGE_BACKUP".tmp.* 2>/dev/null
if [ "$(read_mode)" = "Horny" ] || [ -f "$CHARGE_BACKUP" ]; then
    lick_log INFO "boot recovery: restoring state left by a dead session"
    sh "$MODPATH/PornArchive/anal.sh" >/dev/null 2>&1
    [ -f "$CHARGE_BACKUP" ] && Siskaeee
    write_mode "NotHorny"
    rm -f "$MODPATH/CurrentHalState" "$MODPATH/CurrentAggHalState" "$MODPATH/CurrentZoneState"
fi

# --- crash watchdog (P0-2 layer 3) -----------------------------------------
# If the main loop dies silently or hangs while a session is active, restore
# the thermal state and stop. The module stays inert until the next boot:
# safe beats sorry.
(
    while true; do
        sleep 30
        DPID="$(cat "$PIDFILE" 2>/dev/null)"
        if [ -z "$DPID" ] || ! kill -0 "$DPID" 2>/dev/null; then
            if [ "$(read_mode)" = "Horny" ]; then
                sh "$MODPATH/PornArchive/anal.sh" >/dev/null 2>&1
                lick_log ERR "watchdog: daemon died with an active session - restored"
            fi
            exit 0
        fi
        if [ -f "$HEARTBEAT" ] && [ -n "$(find "$HEARTBEAT" -mmin +3 2>/dev/null)" ] && [ "$(read_mode)" = "Horny" ]; then
            if is_our_process "$DPID" '*LickingT*'; then
                kill -9 "$DPID" 2>/dev/null
                kill_transitions
                sh "$MODPATH/PornArchive/anal.sh" >/dev/null 2>&1
                [ -f "$CHARGE_BACKUP" ] && Siskaeee
                write_mode "NotHorny"
                lick_log ERR "watchdog: daemon hung >3min in Horny - killed and restored"
            fi
            exit 0
        fi
    done
) &

echo "NotHorny" > "$STATE_FILE"

# block-device knobs are a boot-time one-way write; back the originals up on
# the first boot so the uninstall path can restore them exactly (P2-16)
if [ ! -s "$BLOCK_BACKUP" ]; then
    : > "${BLOCK_BACKUP}.tmp.$$"
    for Tits in /sys/block/*/queue; do
        for knob in iostats rotational add_random; do
            [ -f "$Tits/$knob" ] && echo "$Tits/$knob|$(cat "$Tits/$knob" 2>/dev/null)" >> "${BLOCK_BACKUP}.tmp.$$"
        done
        [ -f "$Tits/iosched/slice_idle" ] && echo "$Tits/iosched/slice_idle|$(cat "$Tits/iosched/slice_idle" 2>/dev/null)" >> "${BLOCK_BACKUP}.tmp.$$"
    done
    mv -f "${BLOCK_BACKUP}.tmp.$$" "$BLOCK_BACKUP" 2>/dev/null
fi
for Tits in /sys/block/*/queue; do
    eko "0" "$Tits/iostats"
    eko "0" "$Tits/rotational"
    eko "0" "$Tits/add_random"
    eko "0" "$Tits/iosched/slice_idle"
done

if [ -f "$ZPOLICY" ]; then
    SELECTED_POLICY=$(cat "$ZPOLICY")
    apply_policy "$SELECTED_POLICY"
fi

# kernel panic guard: explicit boolean allowlist + backup of the original
# values (P0-4). use_spi_crc and the blanket "*panic*" glob are gone: they
# hit heterogeneous knobs (panic_timeout is seconds, panic_print a bitmask)
# and the old "restore" wrote invented 1s.
write_val() {
    [ -f "$1" ] && { chmod +w "$1" 2>/dev/null; echo "$2" > "$1" 2>/dev/null; }
}
scan_panic_nodes() {
    PANIC_NODES="$(find /proc/sys /sys -type f \( -name panic_on_oops -o -name panic_on_warn -o -name hung_task_panic -o -name exception-trace -o -name sched_schedstats -o -name tracing_on \) 2>/dev/null)"
}
disable_panic() {
    scan_panic_nodes
    if [ ! -s "$PANIC_BACKUP" ]; then
        : > "${PANIC_BACKUP}.tmp.$$"
        for p in $PANIC_NODES /proc/sys/kernel/printk /proc/sys/kernel/printk_devkmsg; do
            [ -f "$p" ] && echo "$p|$(cat "$p" 2>/dev/null)" >> "${PANIC_BACKUP}.tmp.$$"
        done
        mv -f "${PANIC_BACKUP}.tmp.$$" "$PANIC_BACKUP" 2>/dev/null
    fi
    for p in $PANIC_NODES; do
        write_val "$p" "0"
    done
    write_val "/proc/sys/kernel/printk" "0 0 0 0"
    write_val "/proc/sys/kernel/printk_devkmsg" "off"
    lick_log OK "panic guard applied (allowlist, backup kept)"
}
restore_panic() {
    if [ -s "$PANIC_BACKUP" ]; then
        while IFS='|' read -r p v; do
            [ -f "$p" ] && write_val "$p" "$v"
        done < "$PANIC_BACKUP"
        rm -f "$PANIC_BACKUP"
        lick_log OK "panic settings restored from backup"
    fi
}
if [ -f "$CONF" ]; then
    . "$CONF"
    if [ "$DISABLE_PANIC" = "1" ]; then
        disable_panic
    else
        restore_panic
    fi
fi

# ---------------------------------------------------------------------------
# poll loop
# ---------------------------------------------------------------------------
CURRENT_PKG=""
THERMAL_DISABLED="false"
FAST_CHARGE_STATE="false"
NOTHORNY_SEEN=0
LAST_KEY=""
FG_FAIL_NOTED=""

sleep 2
while true; do
    # reset every sourced key to its default before re-reading the config:
    # sourcing can only add/override, so a key the user deleted would stay
    # alive in this daemon until restart (P1-9)
    Charge=0; MODE=auto; HAL=0; DISABLE_PANIC=0; ZONE=1; AggHal=1
    if [ -f "$CONF" ]; then
        . "$CONF"
    fi

    current_mode="$(read_mode)"
    GLOBAL_POLICY=$(cat "$ZPOLICY" 2>/dev/null)
    GLOBAL_ZONE=$(grep -i '^ZONE=' "$CONF" 2>/dev/null | cut -d'=' -f2)
    TARGET_STATE="NotHorny"
    active_pkg=""
    USE_HAL="$HAL"
    USE_AGGHAL="$(grep -i '^AggHal=' "$CONF" 2>/dev/null | cut -d'=' -f2)"
    [ -z "$USE_AGGHAL" ] && USE_AGGHAL="1"
    USE_POLICY="$GLOBAL_POLICY"
    USE_ZONE="${GLOBAL_ZONE:-1}"
    BAT_STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)

    if [ "$MODE" = "auto" ]; then
        PornApp="$(get_PornApp | tr '\n' ' ')"

        if [ -f "$APP_CONFIGS" ]; then
            while read -r line || [ -n "$line" ]; do
                [ -z "$line" ] && continue
                pkg="$(echo "$line" | cut -d':' -f1)"
                [ -z "$pkg" ] && continue
                case " $PornApp " in
                    *" $pkg "*)
                    TARGET_STATE="Horny"
                    active_pkg="$pkg"
                    custom_agg="$(echo "$line" | cut -d':' -f2)"
                    custom_pol="$(echo "$line" | cut -d':' -f3)"
                    custom_zone="$(echo "$line" | cut -d':' -f4)"

                    [ -n "$custom_agg" ] && USE_HAL="$custom_agg"
                    [ -n "$custom_pol" ] && USE_POLICY="$custom_pol"
                    [ -n "$custom_zone" ] && USE_ZONE="$custom_zone"
                    custom_agghal="$(echo "$line" | cut -d':' -f5)"
                    [ -n "$custom_agghal" ] && USE_AGGHAL="$custom_agghal"
                    break
                    ;;
                esac
            done < "$APP_CONFIGS"
        fi

        if [ "$TARGET_STATE" != "Horny" ] && [ -f "$PORN" ]; then
            while read -r pkg || [ -n "$pkg" ]; do
                [ -z "$pkg" ] && continue
                case " $PornApp " in
                    *" $pkg "*)
                    TARGET_STATE="Horny"
                    active_pkg="$pkg"
                    break
                    ;;
                esac
            done < "$PORN"
        fi
    elif [ "$MODE" = "static" ]; then
        TARGET_STATE="Horny"
        active_pkg="STATIC"
    fi

    # Fast charge executes ONLY in auto mode (user-facing rule). The restore
    # branch fires whenever ANY condition drops - including the user switching
    # to static mode or turning Charge off while charging: leaving the nodes
    # forced while the daemon stops managing them froze devices (freeze fix).
    if [ "$Charge" = "1" ] && [ "$BAT_STATUS" = "Charging" ] && [ "$MODE" = "auto" ]; then
        if [ "$FAST_CHARGE_STATE" != "true" ]; then
            wait_for_transitions
            Msbreewc
            lick_log OK "fast charge enabled"
            Notip FastCharge "⚡ Fast Charge Enabled: turn off temp for better current"
            FAST_CHARGE_STATE="true"
        fi
    else
        if [ "$FAST_CHARGE_STATE" = "true" ]; then
            wait_for_transitions
            Siskaeee
            lick_log OK "fast charge disabled"
            Notip FastCharge "🔋 Fast Charge Disabled: Restoring normal thermal state."
            FAST_CHARGE_STATE="false"
        fi
    fi

    if [ "$TARGET_STATE" = "Horny" ]; then
        # any poll that sees a listed app resets the idle counter, otherwise
        # non-consecutive idle polls (home -> game -> home -> home) could
        # still add up and trigger a bogus restore
        NOTHORNY_SEEN=0
        NEW_KEY="$active_pkg|$USE_HAL|$USE_POLICY|$USE_ZONE|$USE_AGGHAL"
        if [ "$THERMAL_DISABLED" = "false" ] || [ "$CURRENT_PKG" != "$active_pkg" ] || [ "$LAST_KEY" != "$NEW_KEY" ]; then
            [ "$THERMAL_DISABLED" = "true" ] && lick_log INFO "re-apply $active_pkg (config changed)"
            write_mode "Horny"
            CURRENT_PKG="$active_pkg"
            LAST_KEY="$NEW_KEY"
            apply_policy "$USE_POLICY"
            echo "$USE_HAL" > "$MODPATH/CurrentHalState"

            if [ "$USE_HAL" = "1" ]; then
                # record the effective AggHal so anal.sh knows whether the
                # vendor HAL mounts must be undone on restore (the state file
                # is consumed and removed by anal.sh itself)
                echo "$USE_AGGHAL" > "$MODPATH/CurrentAggHalState"
                lick_log OK "agg apply $active_pkg (policy=$USE_POLICY zone=$USE_ZONE agghal=$USE_AGGHAL)"
                start_transition "$MODPATH/PornArchive/MILF.sh" "$USE_POLICY" "$USE_ZONE" "$USE_AGGHAL"
                Notip Tag "🚀 Aggressive mode Apply for $active_pkg"
            else
                lick_log OK "balanced apply $active_pkg (policy=$USE_POLICY zone=$USE_ZONE)"
                start_transition "$MODPATH/PornArchive/amature.sh" "$USE_POLICY" "$USE_ZONE"
                Notip Tag "🤡 Amature mode Apply for $active_pkg"
            fi
            THERMAL_DISABLED="true"
            NOTHORNY_SEEN=0
            sleep 3
        fi
    elif [ "$TARGET_STATE" = "NotHorny" ]; then
        if [ "$THERMAL_DISABLED" = "true" ]; then
            # Hysteresis: restore only after 2 consecutive idle polls, so a
            # quick game -> home -> other-game switch does not thrash the
            # thermal state (restore + re-apply back to back).
            NOTHORNY_SEEN=$((NOTHORNY_SEEN + 1))
            if [ "$NOTHORNY_SEEN" -ge 2 ]; then
                lick_log OK "restore normal mode (app idle)"
                write_mode "NotHorny"
                CURRENT_PKG=""
                LAST_KEY=""
                start_transition "$MODPATH/PornArchive/anal.sh"
                Notip Tag "😴 Normal mode Apply"
                THERMAL_DISABLED="false"
                rm -f "$MODPATH/CurrentHalState"
                sleep 3
            fi
        fi
    fi

    description
    touch "$HEARTBEAT" 2>/dev/null
    # adaptive interval (P2-14): poll fast while a listed app is foreground,
    # slow down while idle - the dumpsys pipeline is not cheap
    if [ "$TARGET_STATE" = "Horny" ]; then
        sleep 7
    else
        sleep 15
    fi
done
