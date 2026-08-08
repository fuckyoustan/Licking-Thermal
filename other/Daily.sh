#!/system/bin/sh

XNXX="/data/adb/modules/LickingT"
EPORNER="$XNXX/thermal.conf"
PORNHUB="$XNXX/CurrentZoneState"
XHAMSTER=$(grep -i '^ZONE=' "$EPORNER" 2>/dev/null | cut -d'=' -f2)
JAVHD=$(grep -i '^HAL=' "$EPORNER" 2>/dev/null | cut -d'=' -f2)
if [ -f "$PORNHUB" ]; then
JAVTIFUL="$(cat "$PORNHUB")"
if [ -n "$JAVTIFUL" ]; then
XHAMSTER="$JAVTIFUL"
fi
fi
Miyabi() {
local val="$1"; shift
for p in "$@"; do
[ -f "$p" ] || continue
printf '%s' "$val" > "$p" 2>/dev/null
chmod 444 "$p" 2>/dev/null
done
}
NikkiBenz() {
for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
Miyabi "$setting 0" /proc/gpufreq/gpufreq_power_limited
done
}
LanaRhoades() {
Miyabi "1" /proc/eem/eem_status
Miyabi "1" /proc/sys/kernel/sched_boost
Miyabi "1" /sys/kernel/eara_thermal/enable
Miyabi "1" /sys/module/thermal/parameters/enabled
Miyabi "1" /sys/module/qpnp_bsi/parameters/bcl_enabled
Miyabi "0" /proc/mtk_batoc_throttling/battery_oc_protect_stop
cmd thermalservice reset 2>/dev/null
}
TeraPatrick() {
vagina=/proc/cpufreq
Miyabi "1" "$vagina/cpufreq_imax_thermal_protect"
Miyabi "0" "$vagina/cpufreq_sched_disable"
Miyabi "0" "$vagina/cpufreq_imax_enable"
Miyabi "1" "$vagina/cpufreq_power_mode"
}
AbellaDanger() {
local mesum=$(find /sys -path '*msm_thermal*' -name 'enabled' -type f 2>/dev/null)
if [ -n "$mesum" ]; then
local sange1=$(grep -l '^N$' $mesum 2>/dev/null)
[ -n "$sange1" ] && Miyabi "Y" $sange1
local sange2=$(grep -l '^0$' $mesum 2>/dev/null)
[ -n "$sange2" ] && Miyabi "1" $sange2
fi
}
Honoka() {
if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
kontol="/sys/class/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/soc" ]; then
kontol="$(find /sys/devices/platform/soc/ -type d -path "*/kgsl/kgsl-3d0" 2>/dev/null | head -n 1)"
fi
[ -d "$kontol" ] || return 0
Miyabi "1" "$kontol/throttling"
Miyabi "1" "$kontol/bus_split"
Miyabi "1" "$kontol/max_gpuclk"
Miyabi "1" "$kontol/adreno_idler_active"
Miyabi "1" "$kontol/thermal_pwrlevel"
Miyabi "0" "$kontol/force_no_nap"
Miyabi "0" "$kontol/force_rail_on"
Miyabi "0" "$kontol/force_bus_on"
Miyabi "0" "$kontol/force_clk_on"
}
EmmaStone() {
if [ -f /proc/driver/thermal/tzcpu ]; then
t_limit="117"
no_cooler="0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy"
Miyabi "1 ${t_limit}000 0 mtktscpu-sysrst $no_cooler 200" /proc/driver/thermal/tzcpu
Miyabi "1 ${t_limit}000 0 mtktspmic-sysrst $no_cooler 1000" /proc/driver/thermal/tzpmic
Miyabi "1 ${t_limit}000 0 mtktsbattery-sysrst $no_cooler 1000" /proc/driver/thermal/tzbattery
Miyabi "1 ${t_limit}000 0 mtk-cl-kshutdown00 $no_cooler 2000" /proc/driver/thermal/tzpa
Miyabi "1 ${t_limit}000 0 mtktscharger-sysrst $no_cooler 2000" /proc/driver/thermal/tzcharger
Miyabi "1 ${t_limit}000 0 mtktswmt-sysrst $no_cooler 1000" /proc/driver/thermal/tzwmt
Miyabi "1 ${t_limit}000 0 mtktsAP-sysrst $no_cooler 1000" /proc/driver/thermal/tzbts
Miyabi "1 ${t_limit}000 0 mtk-cl-kshutdown01 $no_cooler 1000" /proc/driver/thermal/tzbtsnrpa
Miyabi "1 ${t_limit}000 0 mtk-cl-kshutdown02 $no_cooler 1000" /proc/driver/thermal/tzbtspa
fi
}
MiaKholifah() {
for memek in /sys/devices/soc/*/kgsl/kgsl-3d0; do
if [ -d "$memek" ]; then
find /sys/devices/soc/*/kgsl/kgsl-3d0/ -name '*temp*' -exec chmod 644 {} + 2>/dev/null
fi
done
}
SaoriHara() {
for anal in /sys/class/power_supply/*; do
Miyabi "150" "$anal/temp_cool"
Miyabi "400" "$anal/temp_hot"
Miyabi "380" "$anal/temp_warm"
Miyabi "1" "$anal/thermal_limit"
Miyabi "1" "$anal/device/bcl_enabled"
done
}
HitomiTanaka1() {
find /sys/devices/virtual/thermal -type f -exec chmod 644 {} + 2>/dev/null
}
HitomiTanaka2() {
(find /sys/devices/virtual/thermal -name 'temp' -type f 2>/dev/null | xargs -n 1 umount 2>/dev/null) &
}
AliceaFox() {
find /sys/devices/virtual/thermal -type f \( -name "mode" -o -name "thm_enable" \) 2>/dev/null | awk '{ val = ($0 ~ /mode/) ? "enabled" : "1"; print "echo " val " > \"" $0 "\"; chmod 444 \"" $0 "\"" }' | sh 2>/dev/null &
}
mysaaat() {
Miyabi "1" /proc/ppm/enabled
for idx in 2 3 4 6 7; do
Miyabi "$idx 1" /proc/ppm/policy_status
done
}
MikamiYua() {
getprop | awk -F'[][]' 'tolower($0) ~ /thermal|temp|throttl/ {print $2}' | while read -r penis; do
resetprop -n "$penis" "running" 2>/dev/null
setprop "$penis" "running" 2>/dev/null
done
}
AngelaWhite() {
for puki in /sys/devices/*.mali; do
if [ -d "$puki" ]; then
chmod 644 /sys/devices/*.mali/tmu /sys/devices/*.mali/throttling* /sys/devices/*.mali/tripping 2>/dev/null
fi
done
}
AngelaWhite() {
for puki in /sys/devices/*.mali; do
if [ -d "$puki" ]; then
chmod 644 /sys/devices/*.mali/tmu /sys/devices/*.mali/throttling* /sys/devices/*.mali/tripping 2>/dev/null
break
fi
done
}
AsamiSugiura() {
goth=/sys/module/workqueue/parameters
Miyabi "Y" "$goth/power_efficient"
Miyabi "Y" "$goth/disable_numa"
}
EvaAngelina() {
find /system /vendor -type f \( -iname '*thermal*' -o -iname '*throttl*' \) ! -iname '*.rc' 2>/dev/null | xargs -n 1 umount 2>/dev/null
}
MelenaTara() {
find /*/etc/init -type f 2>/dev/null | xargs grep -h "^service.*thermal" 2>/dev/null | awk '{print "start "$2"; setprop ctl.start "$2";"}' | sh 2>/dev/null
}
Msbreewc() {
find /sys/class/power_supply/battery/ -name '*temp*' -exec chmod 444 {} + 2>/dev/null
}
FunkyTown() {
if ! service check miui.mqsas.IMQSNative | grep -q "not found"; then
for a in $(find /*/etc/init -type f 2>/dev/null | xargs grep -Eh "^service (miui|.*thermal)" 2>/dev/null | awk '{print$2}'); do 
service call miui.mqsas.IMQSNative 21 i32 1 s16 "start" i32 1 s16 "$a" s16 "/dev/null" i32 1 >/dev/null 2>&1
done
fi
}
GinaGerson() {
PKG="com.xiaomi.joyose"
if ! pm list packages | grep -q "$PKG"; then
cmd package install-existing "$PKG" >/dev/null 2>&1
fi
}
main1() {
if [ "$XHAMSTER" = "0" ]; then
AliceaFox
HitomiTanaka2
else
HitomiTanaka1
fi
MikamiYua
AngelaWhite
sleep 1
GinaGerson
AsamiSugiura
SaoriHara
NikkiBenz
TeraPatrick
sleep 2
Honoka
EmmaStone
AbellaDanger
mysaaat
LanaRhoades
}
main2() {
MiaKholifah
Msbreewc
EvaAngelina
FunkyTown
MelenaTara
}
run_main() {
if [ "$JAVHD" = "1" ]; then
main2
sleep 2
main1
return
fi
main1
}
run_main
