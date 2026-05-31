#!/system/bin/sh

Miyabi() {
local val="$1"; shift
local current_perms
for p in "$@"; do
[ -f "$p" ] || continue
current_perms=$(stat -c "%a" "$p" 2>/dev/null)
if [ "$current_perms" != "644" ]; then
chmod 644 "$p" 2>/dev/null
fi
printf '%s' "$val" > "$p" 2>/dev/null
done
}
Siskaeee() {
Miyabi "0" /proc/sys/kernel/sched_boost
Miyabi "0" /sys/kernel/eara_thermal/enable
cmd thermalservice override-status 0 2>/dev/null
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
ZONE_ARG=$(grep -i '^ZONE=' /data/adb/modules/LickingT/thermal.conf 2>/dev/null | cut -d'=' -f2)
SweetyFox1() { 
find /sys/devices/virtual/thermal/thermal_zone*/ /sys/firmware/devicetree/base/soc/*/ /sys/devices/virtual/hwmon/hwmon*/ -type f \( -iname '*temp*' -o -iname '*trip_point_*' -o -iname '*type*' -o -iname '*limit_info*' -o -iname '*thermal*' -o -name '*name*' \) -exec chmod 000 {} + 2>/dev/null || true
}
SweetyFox2() {
PUSSY="/data/adb/modules/LickingT/FuckTemp"
if [ ! -f "$PUSSY" ]; then
echo "30000" > "$PUSSY"
fi
for FuckTemp in /sys/devices/virtual/thermal/thermal_zone*/temp; do
if [ -f "$FuckTemp" ]; then
mount --bind "$PUSSY" "$FuckTemp"
fi
done
}
LolaTaylor() {
for armpit in /sys/devices/virtual/thermal/thermal_zone*; do
Miyabi "disabled" "$armpit/mode"
Miyabi "0" "$armpit/thm_enable"
done
}
EvaElfie() {
for puki in /sys/devices/*.mali; do
[ -e "$puki/tmu" ] && chmod 000 "$puki/tmu" 2>/dev/null
[ -e "$puki/throttling*" ] && chmod 000 "$puki/throttling*" 2>/dev/null
[ -e "$puki/tripping" ] && chmod 000 "$puki/tripping" 2>/dev/null
done
}
EmmaStone() {
if [ -f /proc/driver/thermal/tzcpu ]; then
t_limit="120"
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
Barbamiska() {
find /sys -name enabled | grep 'msm_thermal' 2>/dev/null | while read -r mesum; do
val=$(cat "$mesum")
[ "$val" = "Y" ] && Miyabi "N" "$mesum"
[ "$val" = "1" ] && Miyabi "0" "$mesum"
done
}
AngelaWhite() {
vagina=/proc/cpufreq
Miyabi "0" "$vagina/cpufreq_imax_thermal_protect"
Miyabi "1" "$vagina/cpufreq_sched_disable"
Miyabi "1" "$vagina/cpufreq_imax_enable"
Miyabi "0" "$vagina/cpufreq_power_mode"
}
Honoka() {
goth=/sys/module/workqueue/parameters
Miyabi "N" "$goth/power_efficient"
Miyabi "N" "$goth/disable_numa"
}
MariaOzawa() {
for anal in /sys/class/power_supply/*; do
Miyabi "150" "$anal/temp_cool"
Miyabi "480" "$anal/temp_hot"
Miyabi "460" "$anal/temp_warm"
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
if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
kontol="/sys/class/kgsl/kgsl-3d0"
elif [ -d "/sys/devices/platform/soc" ]; then
kontol="$(find /sys/devices/platform/soc/ -type d -path "*/kgsl/kgsl-3d0" 2>/dev/null | head -n 1)"
fi
[ -d "$kontol" ] || return 0
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
AnnaPolina() {
find /sys/devices/soc/*/kgsl/kgsl-3d0/ -name '*temp*' 2>/dev/null | while read -r memek; do
chmod 000 $memek 2>/dev/null
done
}
Siskaeee
Honoka
AngelaWhite
SashaGrey
sleep 1
AsamiSugiura
ValentinaNappi
MariaOzawa
EmmaStone
Barbamiska
LolaTaylor
sleep 1
AnnaPolina
EvaElfie
if [ "$ZONE_ARG" = "0" ]; then
SweetyFox2
else
SweetyFox1
fi
SoraAoi
