#!/system/bin/sh

Miyabi() {
local val="$1"; shift
for p; do
[ -f "$p" ] || continue
chmod 644 "$p"
printf '%s\n' "$val" > "$p" 2>/dev/null
chmod 444 "$p"
done
}
MariaOzawa() {
for anal in /sys/class/power_supply/*; do
Miyabi "150" "$anal/temp_cool"
Miyabi "570" "$anal/temp_hot"
Miyabi "500" "$anal/temp_warm"
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
Miyabi "1" /proc/sys/kernel/sched_boost
Miyabi "0" /sys/kernel/eara_thermal/enable
cmd thermalservice override-status 0
}
EvaElfie() {
for puki in /sys/devices/*.mali; do
[ -e "$puki/tmu" ] && chmod 000 "$puki/tmu"
[ -e "$puki/throttling*" ] && chmod 000 "$puki/throttling*"
[ -e "$puki/tripping" ] && chmod 000 "$puki/tripping"
done
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
find /system/lib* /vendor -type f \( -iname "*thermal*" -o -iname "*throttl*" \) 2>/dev/null | while read -r FUCK; do
case "$FUCK" in
*.rc) ;;
*) mount --bind "$SHIT" "$FUCK" ;;
esac
done
}
SweetyFox(){ 
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
ps -e | awk '/[Tt]hermal/ {print $2}' | while read -r pedo; do
[ -n "$pedo" ] && kill -9 "$pedo"
done
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
MsBreewc() {
for cum in $(pgrep -f thermal); do
kill -SIGSTOP "$cum"
done
}
MariaOzawa
AsamiSugiura
ValentinaNappi
AngelaWhite
Siskaeee
Vicca
sleep 0.5
EmmaStone
MiaKholifah
Barbamiska
SashaGrey
EvaElfie
sleep 0.5
SweetyFox
LolaTaylor
AvaAddams
AiUehara
MsBreewc
SoraAoi
sleep 0.5