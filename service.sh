#!/system/bin/sh

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 5
done

MODPATH="/data/adb/modules/LickingT"
CONF="$MODPATH/thermal.conf"
PORN="$MODPATH/PornArchive/PornCategories.txt"
STATE_FILE="$MODPATH/CurrentState"
[ -f "$STATE_FILE" ] || echo "NotHorny" > "$STATE_FILE"
read_mode() {
    cat "$STATE_FILE" 2>/dev/null
}
write_mode() {
    printf "%s" "$1" > "$STATE_FILE"
}
HAL=0
MODE=auto
while true; do
    if [ -f "$CONF" ]; then
        . "$CONF"
    fi
    current_mode=$(read_mode)
    if [ "$MODE" = "auto" ]; then
        PornApp=$(cmd activity stack list | grep true | awk -F'[/{]' '{print $3}')
        Hyper="NO"
        while read -r pkg || [ -n "$pkg" ]; do
            if echo "$PornApp" | grep -q "$pkg"; then
                Hyper="YES"
                break
            fi
        done < "$PORN"
        if [ "$Hyper" = "YES" ] && [ "$current_mode" != "Horny" ]; then
            write_mode "Horny"
            if [ "$HAL" = "1" ]; then
                sh "$MODPATH/PornArchive/MILF.sh"
            else
                sh "$MODPATH/PornArchive/amature.sh"
            fi
        elif [ "$Hyper" = "NO" ] && [ "$current_mode" != "NotHorny" ]; then
            write_mode "NotHorny"
            sh "$MODPATH/PornArchive/anal.sh"
        fi
    elif [ "$MODE" = "static" ]; then
        if [ "$current_mode" != "Horny" ]; then
            write_mode "Horny"
            if [ "$HAL" = "1" ]; then
                sh "$MODPATH/PornArchive/MILF.sh"
            else
                sh "$MODPATH/PornArchive/amature.sh"
            fi
        fi
    fi
    sleep 10
done
