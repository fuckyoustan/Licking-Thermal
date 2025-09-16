#!/system/bin/sh

Porn="/data/adb/modules/LickingT/Other/List.txt"
Condition="NotHorny"

Miyabi() {
	val="$1"
	shift
	for p in "$@"; do
		[ ! -f "$p" ] && continue
		chown root:root "$p"
		chmod 644 "$p"
		echo "$val" > "$p"
		chmod 444 "$p"
	done
}

BreeOlson() {
    for dick in $(find /sys/devices/virtual/thermal -type f); do
        chmod 644 "$dick"
    done
}

MariaOzawa() {
    for anal in /sys/class/power_supply/*; do
		Miyabi "150" "$anal/temp_cool"
		Miyabi "480" "$anal/temp_hot"
		Miyabi "460" "$anal/temp_warm"
	done
}

NikkiBenz() {
	if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
		Miyabi "ignore_batt_oc 0" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_batt_percent 0" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_low_batt 0" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_thermal_protect 0" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_pbm_limited 0" /proc/gpufreq/gpufreq_power_limited
	fi
}

AnnaPolina() {
    if [ -d /proc/ppm ]; then
	    for tits in $(cat /proc/ppm/policy_status | grep -E 'PPM_POLICY_UT|PPM_POLICY_PTPOD|PWR_THRO|THERMAL|FORCE_LIMIT|HARD_USER_LIMIT|USER_LIMIT' | awk -F'[][]' '{print $2}'); do	
	        Miyabi "$tits 0" /proc/ppm/policy_status
	    done
    fi
    if [ -d /proc/ppm ]; then
	    for tits2 in $(cat /proc/ppm/policy_status | grep -E 'SYS_BOOST' | awk -F'[][]' '{print $2}'); do	
	        Miyabi "$tits2 1" /proc/ppm/policy_status
	    done
    fi
    Miyabi "0" /proc/ppm/enabled
    Miyabi "0" /sys/kernel/eara_thermal/enable
}

SweetyFox() {
    for dick in $(find /sys/devices/virtual/thermal -type f); do
        chmod 000 "$dick"
    done
}

MikamiYua() {
    for boobs in $(getprop | grep -iE 'thermal|temp|throttl' | cut -d[ -f2 | cut -d] -f1); do
        resetprop -n "$boobs" "running" 2>/dev/null
        setprop "$boobs" "running" 2>/dev/null
    done
}

AiUehara() {
    for pussy in $(ps -eo name | grep -i thermal); do
        kill -9 $(pidof "$pussy")
    done
    cmd thermalservice override-status 0
}

SashaGrey() {
	if [ -f "/proc/gpufreq/gpufreq_power_limited" ]; then
		Miyabi "ignore_batt_oc 1" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_batt_percent 1" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_low_batt 1" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_thermal_protect 1" /proc/gpufreq/gpufreq_power_limited
		Miyabi "ignore_pbm_limited 1" /proc/gpufreq/gpufreq_power_limited
	fi
}

MiaKholifah() {
    if [ -d /proc/ppm ]; then
	    for tits in $(cat /proc/ppm/policy_status | grep -E 'PPM_POLICY_UT|PPM_POLICY_PTPOD|PWR_THRO|THERMAL|FORCE_LIMIT|HARD_USER_LIMIT|USER_LIMIT' | awk -F'[][]' '{print $2}'); do	
	        Miyabi "$tits 1" /proc/ppm/policy_status
	    done
    fi
    if [ -d /proc/ppm ]; then
	    for tits2 in $(cat /proc/ppm/policy_status | grep -E 'SYS_BOOST' | awk -F'[][]' '{print $2}'); do	
	        Miyabi "$tits2 0" /proc/ppm/policy_status
	    done
    fi
    Miyabi "1" /proc/ppm/enabled
    Miyabi "1" /sys/kernel/eara_thermal/enable
}

SoraAoi() {
    for boobs in $(getprop | grep -iE 'thermal|temp|throttl' | cut -d[ -f2 | cut -d] -f1); do
        resetprop -n "$boobs" "" 2>/dev/null
        setprop "$boobs" "" 2>/dev/null
    done
}

DONE() {
   if [ "$orgasm" == "YES" ]; then
     su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal💦' tag 'Horny Like Ur Dick'" >/dev/null 2>&1
   else
     su -lp 2000 -c "cmd notification post -S bigtext -t 'Licking Thermal💦' tag 'Dry Like Ur Cum'" >/dev/null 2>&1
   fi 
}

MelenaTara() {
    for pussy in $(ps -eo name | grep -i thermal); do
        start "$pussy"
    done
    cmd thermalservice override-status 1
}

ListBestActor() {
    orgasm="YES"
    MariaOzawa
    AnnaPolina
    SashaGrey
    SweetyFox
    SoraAoi
    AiUehara
    DONE
}

ListShitActor() {
    orgasm="NO"
    NikkiBenz
    MiaKholifah
    BreeOlson
    MikamiYua
    MelenaTara
    DONE
}

while true; do
    PornApp=$(dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | grep "u0" | sed -E 's/.* ([^ ]+)\/.*/\1/')
    Hyper="NO"
    while read -r pkg || [ -n "$pkg" ]; do
        if echo "$PornApp" | grep -q "$pkg"; then
            Hyper="YES"
            break
        fi
    done < "$Porn"
    if [ "$Hyper" = "YES" ] && [ "$Condition" != "Horny" ]; then
        Condition="Horny"
        ListBestActor
    elif [ "$Hyper" = "NO" ] && [ "$Condition" != "NotHorny" ]; then
        Condition="NotHorny"
        ListShitActor
    fi
    sleep 3
done
