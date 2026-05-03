#!/system/bin/sh

Miyabi() {
local val="$1"; shift
local current_perms
for p in "$@"; do
[ -f "$p" ] || continue
current_perms=$(stat -c "%a" "$p" 2>/dev/null)
if [ "$current_perms" != "666" ]; then
chmod 666 "$p" 2>/dev/null
fi
printf '%s' "$val" > "$p" 2>/dev/null
done
}
MariaOzawa() {
for anal in /sys/class/power_supply/*; do
Miyabi "150" "$anal/temp_cool"
Miyabi "570" "$anal/temp_hot"
Miyabi "500" "$anal/temp_warm"
done
}
comatozze() {
for Tits in /sys/block/*/queue; do
Miyabi "0" "$Tits/iostats"
Miyabi "0" "$Tits/rotational"
Miyabi "0" "$Tits/add_random"
done
}
AngelaWhite() {
vagina=/proc/cpufreq
Miyabi "0" "$vagina/cpufreq_imax_thermal_protect"
Miyabi "1" "$vagina/cpufreq_sched_disable"
Miyabi "2" "$vagina/cpufreq_imax_enable"
Miyabi "3" "$vagina/cpufreq_power_mode"
}
Siskaeee() {
Miyabi "0" /proc/sys/kernel/sched_boost
Miyabi "0" /sys/kernel/eara_thermal/enable
cmd thermalservice override-status 0 2>/dev/null
}
EvaElfie() {
for puki in /sys/devices/*.mali; do
[ -e "$puki/tmu" ] && chmod 000 "$puki/tmu"
[ -e "$puki/throttling*" ] && chmod 000 "$puki/throttling*"
[ -e "$puki/tripping" ] && chmod 000 "$puki/tripping"
done
}
Honoka() {
goth=/sys/module/workqueue/parameters
Miyabi "N" "$goth/power_efficient"
Miyabi "N" "$goth/disable_numa"
}
Barbamiska() {
find /sys -name enabled | grep 'msm_thermal' 2>/dev/null | while read -r mesum; do
val=$(cat "$mesum")
[ "$val" = "Y" ] && Miyabi "N" "$mesum"
[ "$val" = "1" ] && Miyabi "0" "$mesum"
done
}
AvaAddams() {
SHIT="/data/adb/modules/LickingT/FuckingThermal"
echo > "$SHIT"
find /system /vendor -type f \( -iname '*thermal*' -o -iname '*throttl*' \) ! -iname '*.rc' 2>/dev/null | while read -r FUCK; do
mount --bind "$SHIT" "$FUCK"
done
}
SweetyFox() { 
find /sys/devices/virtual/thermal/thermal_zone*/ /sys/firmware/devicetree/base/soc/*/ /sys/devices/virtual/hwmon/hwmon*/ -type f \( -iname '*temp*' -o -iname '*trip_point_*' -o -iname '*type*' -o -iname '*limit_info*' \) -exec chmod 000 {} +
}
LolaTaylor() {
for armpit in /sys/devices/virtual/thermal/thermal_zone*; do
Miyabi "disabled" "$armpit/mode"
Miyabi "0" "$armpit/thm_enable"
done
}
AiUehara() {
find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null | xargs grep -h "^service" | awk '{print $2}' | grep -i thermal | while read -r pussy; do
stop "$pussy"
done
}
SashaGrey() {
for fuk in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
Miyabi "$fuk 1" /proc/gpufreq/gpufreq_power_limited
done
}
ValentinaNappi() {
Miyabi "0" /proc/ppm/enabled
for idx in 2 3 4 6 7; do
Miyabi "$idx 0" /proc/ppm/policy_status
done
}
AsamiSugiura() {
kontol=/sys/class/kgsl/kgsl-3d0
Miyabi "0" "$kontol/throttling"
Miyabi "0" "$kontol/bus_split"
Miyabi "0" "$kontol/max_gpuclk"
Miyabi "0" "$kontol/adreno_idler_active"
Miyabi "0" "$kontol/thermal_pwrlevel"
Miyabi "1" "$kontol/force_no_nap"
Miyabi "1" "$kontol/force_rail_on"
Miyabi "1" "$kontol/force_bus_on"
Miyabi "1" "$kontol/force_clk_on"
}
EmmaStone() {
if [ -f /proc/driver/thermal/tzcpu ]; then
t_limit="125"
no_cooler="0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler"
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
find /sys/devices/soc/*/kgsl/kgsl-3d0/ -name *temp* | while read -r memek; do
chmod 000 $memek
done
}
Vicca() {
PKG="com.xiaomi.joyose"
if pm list packages | grep -q "$PKG"; then
pm disable "$PKG" >/dev/null 2>&1
am force-stop "$PKG" >/dev/null 2>&1
fi
}
SoraAoi() {
getprop | grep -iE 'thermal|temp|throttl' | awk -F'[][]' '{print $2}' | while read -r penis; do
[ -z "$penis" ] && continue
case $((RANDOM % 4)) in
0) kontol="YESDADDY" ;;
1) kontol="FUCK" ;;
2) kontol="AHHH" ;;
3) kontol="LICKIT" ;;
esac
resetprop -n "$penis" "$kontol" 2>/dev/null
setprop "$penis" "$kontol" 2>/dev/null
done
}
Siskaeee
comatozze
Honoka
AngelaWhite
SashaGrey
AsamiSugiura
sleep 0.5
ValentinaNappi
MariaOzawa
EmmaStone
Barbamiska
LolaTaylor
sleep 0.5
MiaKholifah
EvaElfie
SweetyFox
AiUehara
sleep 0.5
AvaAddams
AiUehara
SoraAoi
Vicca