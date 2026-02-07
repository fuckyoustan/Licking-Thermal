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
NikkiBenz() {
for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
Miyabi "$setting 0" > /proc/gpufreq/gpufreq_power_limited
done
}
MelenaTara() {
find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null | xargs grep -h "^service" | awk '{print $2}' | grep -i thermal | while read -r pussy; do
start "$pussy"
done
}
LanaRhoades() {
Miyabi "0" /proc/sys/kernel/sched_boost
Miyabi "1" /sys/kernel/eara_thermal/enable
cmd thermalservice reset
}
TeraPatrick() {
vagina=/proc/cpufreq
Miyabi "1" "$vagina/cpufreq_imax_thermal_protect"
Miyabi "0" "$vagina/cpufreq_sched_disable"
Miyabi "0" "$vagina/cpufreq_imax_enable"
Miyabi "1" "$vagina/cpufreq_power_mode"
}
AbellaDanger() {
find /sys -name enabled | grep 'msm_thermal' 2>/dev/null | while read -r mesum; do
val=$(cat "$mesum")
[ "$val" = "N" ] && Miyabi "Y" "$mesum"
[ "$val" = "0" ] && Miyabi "1" "$mesum"
done
}
Honoka() {
kontol=/sys/class/kgsl/kgsl-3d0
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
find /sys/devices/soc/*/kgsl/kgsl-3d0/ -name *temp* | while read -r memek; do
chmod 644 $memek
done
}
SaoriHara() {
for anal in /sys/class/power_supply/*; do
Miyabi "150" "$anal/temp_cool"
Miyabi "400" "$anal/temp_hot"
Miyabi "380" "$anal/temp_warm"
done
}
AngelaWhite() {
for puki in /sys/devices/*.mali; do
[ -e "$puki/tmu" ] && chmod 644 "$puki/tmu"
[ -e "$puki/tripping" ] && chmod 644 "$puki/throttling*"
[ -e "$puki/tripping" ] && chmod 644 "$puki/tripping"
done
}
HitomiTanaka() { 
find /sys/devices/virtual/thermal/thermal_zone*/ /sys/firmware/devicetree/base/soc/*/ /sys/devices/virtual/hwmon/hwmon*/ -type f \( -iname '*temp*' -o -iname '*trip_point_*' -o -iname '*type*' -o -iname '*limit_info*' \) -exec chmod 644 {} +
}
AliceaFox() {
for armpit in /sys/devices/virtual/thermal/thermal_zone*; do
Miyabi "enabled" "$armpit/mode"
Miyabi "1" "$armpit/thm_enable"
done
}
mysaaat() {
Miyabi "1" /proc/ppm/enabled
for idx in 2 3 4 6 7; do
Miyabi "$idx 1" /proc/ppm/policy_status
done
}
Vicca() {
ps -e | awk '/[Tt]hermal/ {print $2}' | while read -r pedo; do
[ -n "$pedo" ] && kill -SIGCONT "$pedo"
done
}
MikamiYua() {
getprop | grep -iE 'thermal|temp|throttl' | awk -F'[][]' '{print $2}' | while read -r prop; do
[ -z "$prop" ] && continue
resetprop -n "$prop" "running" 2>/dev/null
setprop "$prop" "running" 2>/dev/null
done
}
EvaAngelina() {
find /system/lib /system/lib64 /vendor -type f \( -iname '*thermal*' -o -iname '*throttl*' \) ! -iname '*.rc' 2>/dev/null | while IFS= read -r FUCK; do
umount "$FUCK"
done
}
SaoriHara
NikkiBenz
TeraPatrick
LanaRhoades
Honoka
Vicca
sleep 0.5
EmmaStone
MiaKholifah
AbellaDanger
HitomiTanaka
AliceaFox
mysaaat
sleep 0.5
AngelaWhite
MikamiYua
EvaAngelina
MelenaTara
sleep 0.5
