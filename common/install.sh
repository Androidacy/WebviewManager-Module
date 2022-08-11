# shellcheck shell=ash
# shellcheck disable=SC1091,SC1090,SC2139,SC2086,SC3010,SC2034
TRY_COUNT=1
VF=0
VERIFY=true
config_file="$EXT_DATA/config.conf"
A=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
ui_print "ⓘ $(echo "$DEVICE" | sed 's#%20#\ #g') with android $A, sdk$API, with an $ARCH cpu"
ui_print "Checking for module updates..."
isUpdated
verifyModule
## Functions
# Make sure all config values are what we expect them to be
verify_config() {
    local browser, webview, webview_custom, browser_custom, webview_type, browser_type
    $can_use_fmmm_apis && clearTerminal || echo ""
    ui_print "Verifying config..."
    $can_use_fmmm_apis && showLoading || echo ""
    # Use jq to parse each value
    browser=$(jq -r '.BROWSER' $config_file)
    webview=$(jq -r '.WEBVIEW' $config_file)
    webview_custom=$(jq -r '.WEBVIEW_CUSTOM' $config_file)
    browser_custom=$(jq -r '.BROWSER_CUSTOM' $config_file)
    webview_type=$(jq -r '.WEBVIEW_TYPE' $config_file)
    browser_type=$(jq -r '.BROWSER_TYPE' $config_file)
    # If any value is invalid, we discard the config and start over
    # Make sure browser, webview, webview_custom, and browser_custom are set to either true or false
    if [ "$browser" != true ] && [ "$browser" != false ]; then
        ui_print "ⓘ BROWSER value invalid, discarding config..."
        cp_ch "$MODPATH/common/config.conf" $config_file
        ignore_config=true
        . $config_file
    fi
    if [ "$webview" != true ] && [ "$webview" != false ]; then
        ui_print "ⓘ WEBVIEW value invalid, discarding config..."
        cp_ch "$MODPATH/common/config.conf" $config_file
        ignore_config=true
        . $config_file
    fi
    if [ "$webview_custom" != true ] && [ "$webview_custom" != false ]; then
        ui_print "ⓘ WEBVIEW_CUSTOM value invalid, discarding config..."
        cp_ch "$MODPATH/common/config.conf" $config_file
        ignore_config=true
        . $config_file
    fi
    if [ "$browser_custom" != true ] && [ "$browser_custom" != false ]; then
        ui_print "ⓘ BROWSER_CUSTOM value invalid, discarding config..."
        cp_ch "$MODPATH/common/config.conf" $config_file
        ignore_config=true
        . $config_file
    fi
    # Make sure WEBVIEW_TYPE is either "chromium", "bromite", or "browser"
    if [ "$webview_type" != "chromium" ] && [ "$webview_type" != "bromite" ] && [ "$webview_type" != "browser" ]; then
        ui_print "ⓘ WEBVIEW_TYPE value invalid, discarding config..."
        cp_ch "$MODPATH/common/config.conf" $config_file
        ignore_config=true
        . $config_file
    fi
    # Make sure BROWSER_TYPE is either "chromium", "bromite", "brave", or "kiwi"
    if [ "$browser_type" != "chromium" ] && [ "$browser_type" != "bromite" ] && [ "$browser_type" != "brave" ] && [ "$browser_type" != "kiwi" ]; then
        ui_print "ⓘ BROWSER_TYPE value invalid, discarding config..."
        cp_ch "$MODPATH/common/config.conf" $config_file
        ignore_config=true
        . $config_file
    fi
    ui_prinrt "Verified config."
    $can_use_fmmm_apis && hideLoading || echo ""
}
# Volume key selection logic
volume_key_setup() {
    # TODO: get a list of webviews and browsers from the API and present them to the user. Unfortuanately, that cmuld prevent us from sanely checking the config.
    # First batch: WEBVIEW
    $can_use_fmmm_apis && clearTerminal || echo ""
    webview_chosen=false
    need_browser_choice=false
    ui_print "Please select the webview you want to use. Custom and none can be selected after other options are shown."
    ui_print "Option 1: Chromium"
    # chooseport is how we detect volume key presses, we use it to detect which option is selected. Up is true, down is false
    if chooseport; then
        ui_print "Chose Chromium"
        webview_type="chromium"
        webview=true
        webview_custom=false
        webview_chosen=true
    fi
    if [ "$webview_chosen" = false ]; then
        ui_print "Option 2: Bromite"
        if chooseport; then
            ui_print "Chose Bromite"
            webview_type="bromite"
            webview=true
            webview_custom=false
            webview_chosen=true
        fi
    fi
    # Option 3 is to try to use browser as webview
    if [ "$webview_chosen" = false ]; then
        ui_print "Option 3: Browser as webview"
        if chooseport; then
            ui_print "Chose Browser as webview"
            webview_type="browser"
            webview=true
            webview_custom=false
            webview_chosen=true
            need_browser_choice=true
        fi
    fi
    if [ "$webview_chosen" = false ]; then
        ui_print "Option 4: Custom"
        if chooseport; then
            ui_print "Chose Custom"
            webview_type="custom"
            webview=true
            webview_custom=true
            webview_chosen=true
        fi
    fi
    if [ "$webview_chosen" = false ]; then
        ui_print "Option 5: None"
        if chooseport; then
            ui_print "Chose None"
            webview=false
            webview_custom=false
            webview_chosen=true
        fi
    fi
    # Second batch: BROWSER
    # Choices are (in order): Chromium, Bromite, Brave, Kiwi, Custom, and None
    # None cannot be selected if need_browser_choice is true
    browser_chosen=false
    ui_print "Please select the browser you want to use. Custom and none can be selected after other options are shown."
    ui_print "Option 1: Chromium"
    if chooseport; then
        ui_print "Chose Chromium"
        browser_type="chromium"
        browser=true
        browser_custom=false
        browser_chosen=true
    fi
    if [ "$browser_chosen" = false ]; then
        ui_print "Option 2: Bromite"
        if chooseport; then
            ui_print "Chose Bromite"
            browser_type="bromite"
            browser=true
            browser_custom=false
            browser_chosen=true
        fi
    fi
    if [ "$browser_chosen" = false ]; then
        ui_print "Option 3: Browser as browser"
        if chooseport; then
            ui_print "Chose Browser as browser"
            browser_type="browser"
            browser=true
            browser_custom=false
            browser_chosen=true
        fi
    fi
    if [ "$browser_chosen" = false ]; then
        ui_print "Option 4: Custom"
        if chooseport; then
            ui_print "Chose Custom"
            browser_type="custom"
            browser=true
            browser_custom=true
            browser_chosen=true
        fi
    fi
    if [ "$need_browser_choice" = false ]; then
        if [ "$browser_chosen" = false ]; then
            ui_print "Option 5: None"
            if chooseport; then
                ui_print "Chose None"
                browser=false
                browser_custom=false
                browser_chosen=true
            fi
        fi
    else
        ui_print "You chose to use browser as webview, but did not select a browser. Bailing."
        abort "Browser as webview selected, but no browser selected"
    fi
}
## Install logic
if [ -n "$MMM_EXT_SUPPORT" ]; then
    #!useExt
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
    verify_config
fi
