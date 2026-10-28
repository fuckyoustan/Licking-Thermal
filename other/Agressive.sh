#!/system/bin/sh

XNXX="/data/adb/modules/LickingT"
PORNHUB="$XNXX/CurrentZoneState"
JAVTIFUL="$1"
XHAMSTER="$2"
[ -z "$XHAMSTER" ] && XHAMSTER="0"
echo "$XHAMSTER" > "$PORNHUB"
if [ -n "$JAVTIFUL" ]; then
for z in /sys/class/thermal/thermal_zone*; do
[ -f "$z/policy" ] || continue
chmod 644 "$z/policy" 2>/dev/null
echo "$JAVTIFUL" > "$z/policy" 2>/dev/null
done
fi
Miyabi() {
local val="$1"; shift
local current_perms
for p in "$@"; do
[ -f "$p" ] || continue
chmod 644 "$p" 2>/dev/null
printf '%s' "$val" > "$p" 2>/dev/null
done
}
MariaOzawa() {
for anal in /sys/class/power_supply/*; do
Miyabi "150" "$anal/temp_cool"
Miyabi "570" "$anal/temp_hot"
Miyabi "500" "$anal/temp_warm"
Miyabi "0" "$anal/thermal_limit"
Miyabi "0" "$anal/device/bcl_enabled"
done
}
AngelaWhite() {
vagina=/proc/cpufreq
Miyabi "0" "$vagina/cpufreq_imax_thermal_protect"
Miyabi "1" "$vagina/cpufreq_sched_disable"
Miyabi "2" "$vagina/cpufreq_imax_enable"
Miyabi "3" "$vagina/cpufreq_power_mode"
}
AvaAddams() {
SHIT="/data/adb/modules/LickingT/FuckingThermal"
[ ! -f "$SHIT" ] && echo > "$SHIT"
find /system/lib* /vendor -type f \( -iname '*thermal*' -o -iname '*throttl*' \) ! -iname '*.rc' 2>/dev/null | while read -r Pussy; do
grep -qF " $Pussy " /proc/mounts 2>/dev/null && continue
mount --bind "$SHIT" "$Pussy" 2>/dev/null
done
}
Siskaeee() {
Miyabi "0" /proc/eem/eem_status
Miyabi "0" /proc/sys/kernel/sched_boost
Miyabi "0" /sys/kernel/eara_thermal/enable
Miyabi "0" /sys/module/thermal/parameters/enabled
Miyabi "0" /sys/module/qpnp_bsi/parameters/bcl_enabled
Miyabi "1" /proc/mtk_batoc_throttling/battery_oc_protect_stop
cmd thermalservice override-status 0 2>/dev/null
}
EvaElfie() {
for puki in /sys/devices/*.mali; do
if [ -d "$puki" ]; then
chmod 000 "$puki/tmu" "$puki"/throttling* "$puki/tripping" 2>/dev/null
fi
done
}
Honoka() {
goth=/sys/module/workqueue/parameters
Miyabi "N" "$goth/power_efficient"
Miyabi "N" "$goth/disable_numa"
}
Barbamiska() {
local mesum=$(find /sys -path '*msm_thermal*' -name 'enabled' -type f 2>/dev/null)
if [ -n "$mesum" ]; then
local sange1=$(grep -l '^Y$' $mesum 2>/dev/null)
[ -n "$sange1" ] && Miyabi "N" $sange1
local sange2=$(grep -l '^1$' $mesum 2>/dev/null)
[ -n "$sange2" ] && Miyabi "0" $sange2
fi
}
SweetyFox1() { 
find /sys/devices/virtual/thermal -type f -exec chmod 000 {} + 2>/dev/null
}
SweetyFox2() {
PUSSY="/data/adb/modules/LickingT/FuckTemp"
[ ! -f "$PUSSY" ] && echo "30000" > "$PUSSY"
find /sys/devices/virtual/thermal -name 'temp' -type f 2>/dev/null | while read -r Boobs; do
grep -qF " $Boobs " /proc/mounts 2>/dev/null && continue
mount --bind "$PUSSY" "$Boobs" 2>/dev/null
done
}
LolaTaylor() {
find /sys/devices/virtual/thermal -type f \( -name "mode" -o -name "thm_enable" \) 2>/dev/null | awk '{ val = ($0 ~ /mode/) ? "disabled" : "0"; print "chmod 644 \"" $0 "\"; echo " val " > \"" $0 "\"" }' | sh 2>/dev/null &
}
AiUehara() {
find /*/etc/init -type f 2>/dev/null | xargs grep -h "^service.*thermal" 2>/dev/null | awk '{print "stop "$2"; setprop ctl.stop "$2";"}' | sh 2>/dev/null
}
SashaGrey() {
for fuk in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
Miyabi "$fuk 1" /proc/gpufreq/gpufreq_power_limited
done
}
KitanoMina() { 
(for core in /sys/devices/system/cpu/cpu[0-9]*/online; do read -r state < "$core" 2>/dev/null; [ "$state" = "0" ] && { chmod 644 "$core" 2>/dev/null; echo 1 > "$core" 2>/dev/null; }; done) & 
}
ValentinaNappi() {
Miyabi "0" /proc/ppm/enabled
for idx in 2 3 4 6 7; do
Miyabi "$idx 0" /proc/ppm/policy_status
done
}
GinaGerson() {
PKG="com.xiaomi.joyose"
if pm list packages | grep -q "$PKG"; then
cmd package uninstall -k --user 0 "$PKG" >/dev/null 2>&1
fi
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
SoraAoi() {
BK="$XNXX/PropBackup.txt"
[ -s "$BK" ] || getprop | awk -F'[][]' 'tolower($2) ~ /thermal|temp|throttl/ && $2 !~ /^init[.]svc[.]/ {print $2"="$4}' > "$BK" 2>/dev/null
getprop | awk -F'[][]' 'BEGIN { words[0]="YESDADDY"; words[1]="FUCK"; words[2]="AHHH"; words[3]="LICKIT"; srand(); }
tolower($2) ~ /thermal/ { val = words[int(rand() * 4)]; printf "resetprop -n \"%s\" \"%s\" 2>/dev/null\n", $2, val; }' | sh
}
NicoleMurkovski() {
if ! service check miui.mqsas.IMQSNative | grep -q "not found"; then
for a in $(find /*/etc/init -type f 2>/dev/null | xargs grep -Eh "^service (miui|.*thermal)" 2>/dev/null | awk '{print$2}'); do 
service call miui.mqsas.IMQSNative 21 i32 1 s16 "stop" i32 1 s16 "$a" s16 "/dev/null" i32 1 >/dev/null 2>&1
done
fi
}
Siskaeee
Honoka
GinaGerson
AngelaWhite
SashaGrey
sleep 1
AsamiSugiura
ValentinaNappi
MariaOzawa
EmmaStone
Barbamiska
sleep 2
EvaElfie
NicoleMurkovski
AvaAddams
AiUehara
sleep 2
#SoraAoi
if [ "$XHAMSTER" = "0" ]; then
LolaTaylor
sleep 1
SweetyFox2
else
SweetyFox1
fi
KitanoMina
wait
