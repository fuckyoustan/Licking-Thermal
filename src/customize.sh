#!/system/bin/sh

ui_print "======================================"
ui_print "           MODULE INFORMATION          "
ui_print "======================================"
ui_print " Name       : $(grep_prop name "${TMPDIR}/module.prop")"
sleep 0.1
ui_print " Version    : $(grep_prop version "${TMPDIR}/module.prop")"
sleep 0.1
ui_print " Author     : $(grep_prop author "${TMPDIR}/module.prop")"
sleep 0.2
ui_print ""
ui_print "======================================"
ui_print "           DEVICE INFORMATION          "
ui_print "======================================"
ui_print " Model      : $(getprop ro.product.model)"
sleep 0.1
ui_print " Brand      : $(getprop ro.product.manufacturer)"
sleep 0.1
ui_print " Board      : $(getprop ro.product.board)"
sleep 0.1
ui_print " Android    : $(getprop ro.build.version.release)"
sleep 0.1
ui_print " Kernel     : $(uname -r)"
sleep 0.1
ui_print " CPU        : $(getprop ro.hardware)"
sleep 0.1
ui_print " RAM        : $(free | awk '/Mem:/ {print $2}') kB"
sleep 0.2
ui_print ""
ui_print "======================================"
ui_print "           ROOT ENVIRONMENT            "
ui_print "======================================"
if [ "$APATCH" ]; then
    ROOT_METHOD="APatch"
    ROOT_VERSION="$APATCH_VER ($APATCH_VER_CODE)"
    ACTION=false
elif [ "$KSU" ]; then
    if [ "$KSU_NEXT" ]; then
        ROOT_METHOD="KernelSU Next"
        ROOT_VERSION="$KSU_KERNEL_VER_CODE ($KSU_VER_CODE)"
    else
        ROOT_METHOD="KernelSU"
        ROOT_VERSION="$KSU_KERNEL_VER_CODE ($KSU_VER_CODE)"
    fi
    ACTION=false
elif [ "$MAGISK_VER_CODE" ]; then
    ROOT_METHOD="Magisk"
    ROOT_VERSION="$MAGISK_VER ($MAGISK_VER_CODE)"
else
    ROOT_METHOD="Unknown"
    ROOT_VERSION="N/A"
fi
ui_print " Method     : ${ROOT_METHOD}"
ui_print " Version    : ${ROOT_VERSION}"
sleep 0.3
ui_print ""
ui_print "======================================"
ui_print "           PACKAGE FILTER              "
ui_print "======================================"
ui_print " Scanning game installed..."
sleep 0.3
FILTER_FILE="$MODPATH/PornArchive/PornCategories.txt"
FILTERED_PKGS="$(cmd package list packages --user 0 | grep -Eo "$(cat "$FILTER_FILE" 2>/dev/null)")"
if [ -n "$FILTERED_PKGS" ]; then
    ui_print " game installed:"
    echo "$FILTERED_PKGS" | while read -r line; do
        pkg="${line#package:}"
        ui_print "  - $pkg"
    done
else
    ui_print " No game detected"
    ui_print " Add game list manually in webui!"
fi
echo "$FILTERED_PKGS" | sed 's/package://g' > "$FILTER_FILE"
sleep 0.3
ui_print ""
ui_print "======================================"
ui_print "          NOTIFICATION SETUP           "
ui_print "======================================"
TOAST_PKG="$(pm list packages | grep -oE 'package:[^ ]+\.toast$' | head -n 1 | cut -d: -f2)"
unzip -o "$ZIPFILE" 'toast.apk' -d "$MODPATH" >/dev/null 2>&1
if [ -n "$TOAST_PKG" ]; then
    ui_print " Toast app detected"
    ui_print " Package    : $TOAST_PKG"
    rm -f "$MODPATH/toast.apk"
else
    ui_print " No toast app detected"
    ui_print " Installing toast app..."
    if [ -f "$MODPATH/toast.apk" ]; then
        if pm install "$MODPATH/toast.apk" >/dev/null 2>&1; then
            TOAST_PKG="bellavita.toast"
            ui_print " Toast app installed"
            rm -f "$MODPATH/toast.apk"
        else
            ui_print " Toast app installation failed"
        fi
    else
        ui_print " Error! toast app not found"
    fi
fi
echo "$TOAST_PKG" > /data/local/tmp/ToastProvider
sleep 0.3
ui_print ""
ui_print "======================================"
ui_print "             FINALIZATION              "
ui_print "======================================"
sleep 2
ui_print " Installation completed successfully"
ui_print " Completed at : $(date '+%d %b %Y - %H:%M %Z')"
ui_print " Dont forget to join my telegram channel"
ui_print "======================================"