# shellcheck shell=ash
# shellcheck disable=SC1091,SC1090,SC2139,SC2086,SC3010
TRY_COUNT=1
VF=0
VERIFY=true
config_file="$EXT_DATA/config.conf"
A=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
ui_print "ⓘ $(echo "$DEVICE" | sed 's#%20#\ #g') with android $A, sdk$API, with an $ARCH cpu"
ui_print "Checking for module updates..."