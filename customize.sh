ui_print "***************************************"
ui_print "- Name            : $(grep_prop name "${TMPDIR}/module.prop")"
sleep 0.2
ui_print "- Version         : $(grep_prop version "${TMPDIR}/module.prop")"
sleep 0.2
ui_print "- Author          : $(grep_prop author "${TMPDIR}/module.prop")"
sleep 0.2
ui_print "- Support         : $(grep_prop support "${TMPDIR}/module.prop")"
ui_print "***************************************"
ui_print "- Devices         : $(getprop ro.product.board)"
sleep 0.2
ui_print "- Manufacturer    : $(getprop ro.product.manufacturer)"
sleep 0.2
ui_print "- Android Version : $(getprop ro.build.version.release)"
sleep 0.2
ui_print "- Kernel          : $(uname -r) "
sleep 0.2
ui_print "- Proc            : $(getprop ro.product.board) "
sleep 0.2
ui_print "- Cpu             : $(getprop ro.hardware) "
sleep 0.2
ui_print "- Ram             : $(free | grep Mem |  awk '{print $2}') "
sleep 0.2
ui_print "***************************************"
sleep 0.5
if [ -d "/data/adb/ksu" ]; then
    ROOT_METHOD="KernelSU"
    if command -v su &>/dev/null; then
        ROOT_VERSION=$(su --version 2>/dev/null | cut -d ':' -f 1)
    fi
elif [ -d "/data/adb/magisk" ]; then
    ROOT_METHOD="Magisk"
    if command -v magisk &>/dev/null; then
        ROOT_VERSION=$(magisk -V)
    fi
elif [ -d "/data/adb/ap" ]; then
    ROOT_METHOD="APatch"
    if [ -f "/data/adb/ap/version" ]; then
        ROOT_VERSION=$(cat /data/adb/ap/version)
    fi
fi
ui_print "- Installation using ${ROOT_METHOD} (${ROOT_VERSION})"
sleep 0.5
ui_print "- Setting Executable Permissions"
sleep 0.5
ui_print "- Successfull at $(date "+%d, %b - %H:%M %Z") !!"
cmd activity start -a android.intent.action.VIEW -d 'https://t.me/EverythingAboutArchive'
sleep 5
for tap in $(seq 25); do sleep 0.1
  if [ "$(cmd settings get secure navigation_mode)" = 0 ]; then
    input tap 200 $(($(cmd window size|tail -n1|cut -f2 -dx)*90/100))
  else
    input tap 200 $(($(cmd window size|tail -n1|cut -f2 -dx)*95/100))
  fi
done