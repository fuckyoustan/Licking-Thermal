# Restore thermal state BEFORE the module files are removed. Without this,
# the daemon kept running from the (still-present) module dir, the thermal
# disable stayed active, and the bind-mounts over temp nodes / thermal libs
# survived until the next reboot - leaving the device without thermal
# protection after an "uninstall".
XNXX="/data/adb/modules/LickingT"
# --- concise debug log (LickT.log) — must never block the uninstall --------
LICKT_LOG="$XNXX/LickT.log"
if [ -f "$LICKT_LOG" ] && [ "$(wc -c < "$LICKT_LOG" 2>/dev/null || echo 0)" -gt 262144 ]; then
    tail -n 1000 "$LICKT_LOG" > "${LICKT_LOG}.t.$$" 2>/dev/null && mv -f "${LICKT_LOG}.t.$$" "$LICKT_LOG" 2>/dev/null
fi
lick_log() {
    # $1 = OK | ERR | SKIP | INFO ; $2 = message
    echo "$(date '+%m-%d %H:%M:%S') $1 ${0##*/}: $2" 2>/dev/null >> "$LICKT_LOG" || :
}
write_val() {
    [ -f "$1" ] && { chmod +w "$1" 2>/dev/null; echo "$2" > "$1" 2>/dev/null; }
}
if [ -d "$XNXX" ]; then
    # kill the daemon only when the pid really belongs to this module: PIDs
    # are recycled and a stale pidfile must never kill an unrelated root
    # process (P1-6)
    if [ -f "$XNXX/daemon.pid" ]; then
        OPID=$(cat "$XNXX/daemon.pid" 2>/dev/null)
        if [ -n "$OPID" ] && kill -0 "$OPID" 2>/dev/null; then
            case "$(tr '\0' ' ' < "/proc/$OPID/cmdline" 2>/dev/null)" in
                *LickingT*) kill -9 "$OPID" 2>/dev/null ;;
            esac
        fi
        rm -f "$XNXX/daemon.pid"
    fi
    pkill -9 -f "$XNXX/service.sh" 2>/dev/null
    pkill -9 -f "$XNXX/PornArchive/MILF.sh" 2>/dev/null
    pkill -9 -f "$XNXX/PornArchive/amature.sh" 2>/dev/null
    pkill -9 -f "$XNXX/PornArchive/anal.sh" 2>/dev/null
    lick_log INFO "uninstall: daemon stopped, running restore pass"
    # one clean restore pass while the scripts still exist
    sh "$XNXX/PornArchive/anal.sh" >/dev/null 2>&1
    # drop leftover bind-mounts (FuckTemp over temp nodes, FuckingThermal
    # over thermal libs) that would otherwise persist until reboot
    grep 'LickingT' /proc/mounts 2>/dev/null | awk '{print $2}' | while read -r m; do
        n=0
        while grep -q " $m " /proc/mounts 2>/dev/null && [ "$n" -lt 5 ]; do
            umount "$m" 2>/dev/null || break
            n=$((n+1))
        done
    done
    # fast-charge nodes: restore value + permission mode; entries written by
    # older module versions carry no mode field and fall back to 0664
    if [ -f "$XNXX/chargebackup.txt" ]; then
        while IFS='|' read -r node val mode; do
            if [ -f "$node" ] && [ -n "$val" ]; then
                chmod 0666 "$node" 2>/dev/null
                echo "$val" > "$node" 2>/dev/null
                chmod "${mode:-0664}" "$node" 2>/dev/null
            fi
        done < "$XNXX/chargebackup.txt"
        rm -f "$XNXX/chargebackup.txt"
    fi
    # panic-guard nodes (P2-16): restore the backed-up originals
    if [ -s "$XNXX/panicbackup.txt" ]; then
        while IFS='|' read -r p v; do
            write_val "$p" "$v"
        done < "$XNXX/panicbackup.txt"
        rm -f "$XNXX/panicbackup.txt"
    fi
    # block-device knobs (P2-16): restore the boot-time originals
    if [ -s "$XNXX/blockbackup.txt" ]; then
        while IFS='|' read -r p v; do
            [ -n "$v" ] && write_val "$p" "$v"
        done < "$XNXX/blockbackup.txt"
        rm -f "$XNXX/blockbackup.txt"
    fi
    # node snapshot (P1-10): restore anything a crashed apply left behind
    if [ -s "$XNXX/nodesnapshot.txt" ]; then
        while IFS='|' read -r p v m; do
            [ -f "$p" ] || continue
            [ -n "$v" ] && printf '%s' "$v" > "$p" 2>/dev/null
            [ -n "$m" ] && chmod "$m" "$p" 2>/dev/null
        done < "$XNXX/nodesnapshot.txt"
        rm -f "$XNXX/nodesnapshot.txt"
    fi
    # joyose (P1-11): put the vendor package back if we removed it
    if [ -f "$XNXX/.joyose_off" ]; then
        if ! pm list packages | grep -q "com.xiaomi.joyose"; then
            cmd package install-existing com.xiaomi.joyose >/dev/null 2>&1
        fi
        rm -f "$XNXX/.joyose_off"
    fi
    rm -f "$XNXX/transition.pid" "$XNXX/CurrentHalState" "$XNXX/CurrentAggHalState" "$XNXX/CurrentZoneState" "$XNXX/heartbeat"
    rm -rf "$XNXX/cache" 2>/dev/null
    lick_log OK "uninstall: thermal restored, mounts cleared"
fi

if [ -f "$INFO" ]; then
  while read -r LINE; do
    if [ "$(echo -n "$LINE" | tail -c 1)" = "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f "$LINE~" "$LINE"
    else
      rm -f "$LINE"
      while true; do
        LINE=$(dirname "$LINE")
        [ "$(ls -A "$LINE" 2>/dev/null)" ] && break 1 || rm -rf "$LINE"
      done
    fi
  done < "$INFO"
  rm -f "$INFO"
fi
pm uninstall --user 0 bellavita.toast 2>/dev/null
rm -f /data/local/tmp/ToastProvider
