# shellcheck shell=ash
# shellcheck disable=SC1091,SC1090,SC2139,SC2086,SC3010
TRY_COUNT=1
VF=0
VERIFY=true
config_file="$EXT_DATA/config.conf"
A=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
ui_print "ⓘ $(echo "$DEVICE" | sed 's#%20#\ #g') with android $A, sdk$API, with an $ARCH cpu"
ui_print "Checking for module updates..."
isUpdated
verifyModule
if [ -n "$MMM_EXT_SUPPORT" ]; then
    ui_print "Installing in FoxMMM mode..."
    can_use_fmmm_apis=true
else
    ui_print "Installing in normal mode..."
    can_use_fmmm_apis=false
fi

# Source the config if it exists
if [ -f $config_file ]; then
    . $config_file
    ignore_config=false
else
    cp_ch "$MODPATH/common/config.conf" $config_file
    ignore_config=true
    . $config_file
fi
if [ "$ignore_config" = true ]; then
    ui_print "ⓘ Config file not found, starting setup..."
else
    ui_print "ⓘ Config file found! If you don't want to use it, delete it and restart the installation."
    ui_print "ⓘ Verifying config file..."
fi
# Make sure BROWSER, WEBVIEW, WEBVIEW_CUSTOM, and BROWSER_CUSTOM are set to either true or false
if [ ! $ignore_config ]; then
    if [ "$BROWSER" != true ] && [ "$BROWSER" != false ]; then
        abort "ⓘ BROWSER must be set to true or false"
    elif [ "$WEBVIEW" != true ] && [ "$WEBVIEW" != false ]; then
        abort "ⓘ WEBVIEW must be set to true or false"
    elif [ "$WEBVIEW_CUSTOM" != true ] && [ "$WEBVIEW_CUSTOM" != false ]; then
        abort "ⓘ WEBVIEW_CUSTOM must be set to true or false"
    elif [ "$BROWSER_CUSTOM" != true ] && [ "$BROWSER_CUSTOM" != false ]; then
        abort "ⓘ BROWSER_CUSTOM must be set to true or false"
    fi
fi
