# Restore thermal state BEFORE the module files are removed. Without this,
# the daemon kept running from the (still-present) module dir, the thermal
# disable stayed active, and the bind-mounts over temp nodes / thermal libs
# survived until the next reboot - leaving the device without thermal
# protection after an "uninstall".
XNXX="/data/adb/modules/LickingT"
if [ -d "$XNXX" ]; then
    if [ -f "$XNXX/daemon.pid" ]; then
        kill -9 "$(cat "$XNXX/daemon.pid" 2>/dev/null)" 2>/dev/null
    fi
    pkill -9 -f "$XNXX/service.sh" 2>/dev/null
    pkill -9 -f "$XNXX/PornArchive/MILF.sh" 2>/dev/null
    pkill -9 -f "$XNXX/PornArchive/amature.sh" 2>/dev/null
    pkill -9 -f "$XNXX/PornArchive/anal.sh" 2>/dev/null
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
    # restore charge-control nodes if fast-charge was active when we died
    if [ -f "$XNXX/chargebackup.txt" ]; then
        while IFS='|' read -r node val; do
            if [ -f "$node" ] && [ -n "$val" ]; then
                echo "$val" > "$node" 2>/dev/null
            fi
        done < "$XNXX/chargebackup.txt"
        rm -f "$XNXX/chargebackup.txt"
    fi
    rm -f "$XNXX/daemon.pid" "$XNXX/transition.pid" "$XNXX/CurrentHalState" "$XNXX/CurrentAggHalState" "$XNXX/CurrentZoneState"
fi

if [ -f $INFO ]; then
  while read LINE; do
    if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f $LINE~ $LINE
    else
      rm -f $LINE
      while true; do
        LINE=$(dirname $LINE)
        [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
      done
    fi
  done < $INFO
  rm -f $INFO  
fi
pm uninstall --user 0 bellavita.toast 2>/dev/null
rm -f /data/local/tmp/ToastProvider