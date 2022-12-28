# shellcheck shell=ash
# shellcheck disable=SC1091,SC1090,SC2139,SC2086,SC3010,SC2034
TRY_COUNT=1
VF=0
VERIFY=true
USE_CONFIG=false
config_file="$EXT_DATA/config.json"
A=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
ui_print "ⓘ $(echo "$DEVICE" | sed 's#%20#\ #g') with android $A, sdk$API, with an $ARCH cpu"
ui_print "Checking for module updates..."
isUpdated
verifyModule
# if $ARCH is not arm or arm64 we abort
if [ "$ARCH" != arm ] && [ "$ARCH" != arm64 ]; then
  abort "✖ Your device isn't supported. ARCH found: [$ARCH], supported: [arm, arm64]."
fi
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
    cp_ch "$MODPATH/common/config.json" $config_file
    ignore_config=true
    . $config_file
  fi
  if [ "$webview" != true ] && [ "$webview" != false ]; then
    ui_print "ⓘ WEBVIEW value invalid, discarding config..."
    cp_ch "$MODPATH/common/config.json" $config_file
    ignore_config=true
    . $config_file
  fi
  if [ "$webview_custom" != true ] && [ "$webview_custom" != false ]; then
    ui_print "ⓘ WEBVIEW_CUSTOM value invalid, discarding config..."
    cp_ch "$MODPATH/common/config.json" $config_file
    ignore_config=true
    . $config_file
  fi
  if [ "$browser_custom" != true ] && [ "$browser_custom" != false ]; then
    ui_print "ⓘ BROWSER_CUSTOM value invalid, discarding config..."
    cp_ch "$MODPATH/common/config.json" $config_file
    ignore_config=true
    . $config_file
  fi
  # Make sure WEBVIEW_TYPE is either "chromium", "bromite", or "browser"
  if [ "$webview_type" != "chromium" ] && [ "$webview_type" != "bromite" ] && [ "$webview_type" != "browser" ]; then
    ui_print "ⓘ WEBVIEW_TYPE value invalid, discarding config..."
    cp_ch "$MODPATH/common/config.json" $config_file
    ignore_config=true
    . $config_file
  fi
  # Make sure BROWSER_TYPE is either "chromium", "bromite", "brave", or "kiwi"
  if [ "$browser_type" != "chromium" ] && [ "$browser_type" != "bromite" ] && [ "$browser_type" != "brave" ] && [ "$browser_type" != "kiwi" ]; then
    ui_print "ⓘ BROWSER_TYPE value invalid, discarding config..."
    cp_ch "$MODPATH/common/config.json" $config_file
    ignore_config=true
    . $config_file
  fi
  # If ignore_config is still false, set USE_CONFIG to true so we skip volume key config
  if [ "$ignore_config" != true ]; then
    USE_CONFIG=true
  fi
  ui_print "Verified config."
  $can_use_fmmm_apis && hideLoading || echo ""
}
# Volume key selection logic
volume_key_setup() {
  # TODO: get a list of webviews and browsers from the API and present them to the user. Unfortunately, that could prevent us from sanely checking the config.
  # First batch: WEBVIEW
  $can_use_fmmm_apis && clearTerminal || echo ""
  webview_chosen=false
  need_browser_choice=false
  # First test the volume keys. Make user press up, then down, and make sure KEYCHECK_FAIL is not true.
  ui_print "📈 Press volume up."
  if chooseport; then
    if $KEYCHECK_FAIL; then
      ui_print "- Vol keys Timed Out -"
      abort "⚠ Timed out waiting for volume key events"
    fi
    ui_print "📉 Press volume down."
    if ! chooseport; then
      if $KEYCHECK_FAIL; then
        ui_print "- Vol keys Timed Out -"
        abort "⚠ Timed out waiting for volume key events"
      fi
      ui_print "  👍 Setup volume keys successful!"
    else
      ui_print "  👎 Setup volume keys failed!"
      abort "⚠ Unable to configure volume keys."
    fi
  else
    ui_print "  👎 Setup volume keys failed!"
    abort "⚠ Unable to configure volume keys."
  fi
  ui_print "Please select the webview you want to use. Custom and none can be selected after other options are shown."
  ui_print "Option 1: Chromium"
  # chooseport is how we detect volume key presses, we use it to detect which option is selected. Up is true, down is false
  if chooseport; then
    ui_print "Chose Chromium"
    webview_type="chromium"
    webview=true
    webview_custom=false
    webview_package="org.bromite.chrome"
    webview_chosen=true
  fi
  if [ "$webview_chosen" = false ]; then
    ui_print "Option 2: Bromite"
    if chooseport; then
      ui_print "Chose Bromite"
      webview_type="bromite"
      webview=true
      webview_custom=false
      webview_package="org.bromite.bromite"
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
# Downloads a webview using makeDownloadRequest and then extracts it using unzip.
download_webview() {
  # Make sure which was passed as first argument and type as second arg
  if [ -z "$1" ] || [ -z "$2" ]; then
    ui_print "No webview type passed to download_webview"
    abort "No webview type passed to download_webview"
  fi
  local type=$2
  local which=$1
  $can_use_fmmm_apis && showLoading || echo ""
  ui_print "Downloading webview..."
  # Make a temporary directory to download the webview to
  webview_tmp_dir="/data/local/tmp/$which-tmp"
  if [ -d "$webview_tmp_dir" ]; then
    rm -rf $webview_tmp_dir
    mkdir -p $webview_tmp_dir
  else
    mkdir -p $webview_tmp_dir
  fi
  makeDownloadRequest "/modules/webviemanager/$which/download/$type" 'GET' "arch=$ARCH" $webview_tmp_dir/$type.apk
  # Next, verify and install the webview
  if [ ! -f "$webview_tmp_dir/$type.apk" ]; then
    ui_print "Download failed"
    abort "Download failed"
  fi
  $can_use_fmmm_apis && hideLoading || echo ""
  ui_print "Download successful"
  verify_and_install_webview $webview_tmp_dir/$type.apk $which $type
}
# Verifies and installs a webview
verify_and_install_webview() {
  # Make sure which was passed as second argument and type as third arg
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    ui_print "No webview type passed to verify_and_install_webview"
    abort "No webview type passed to verify_and_install_webview"
  fi
  local type=$3
  local which=$2
  local apk=$1
  ui_print "Verifying download..."
  $can_use_fmmm_apis && showLoading || echo ""
  # Get the SHA256 hash of the webview
  local sha256
  sha256=$(/data/adb/magisk/busybox sha256sum $apk | /data/adb/magisk/busybox awk "{print $1}")
  # POST the hash to the server to get the hash of the webview to compare with
  local status
  status=$(makeJSONRequest "/modules/webviemanager/verify/$which/$type" 'POST' "arch=$ARCH&client_hash=$sha256" 'verified')
  # Make sure status is true
  if [ "$status" = "true" ]; then
    ui_print "Verification successful"
    $can_use_fmmm_apis && hideLoading || echo ""
    ui_print "Installing webview..."
    $can_use_fmmm_apis && showLoading || echo ""
    # Install the webview
    mkdir -p $MODPATH/system/app/$which-$type/lib
    mkdir -p $webview_tmp_dir/$type/lib
    unzip -qo $apk -d $webview_tmp_dir/$type -x "META-INF/*"
    cp -rf $webview_tmp_dir/$type/lib/arm64-v8a $MODPATH/system/app/$type/lib/arm64/
    cp -rf $webview_tmp_dir/$type/lib/armeabi-v7a $MODPATH/system/app/$type/lib/arm/
    cp -rf $webview_tmp_dir/$type/lib/x86 $MODPATH/system/app/$type/lib/x86/
    cp_ch $apk $MODPATH/system/app/$$which-type/$type.apk
    touch $MODPATH/system/app/$which-$type/.replace
    $can_use_fmmm_apis && hideLoading || echo ""
    ui_print "Installation complete"
  else
    ui_print "Verification failed"
    abort "Verification failed"
  fi
}
# Detect and debloat any existing webview
detect_and_debloat() {
  for item in "com.android.webvview" "com.google.android.webview" "org.mozilla.webview_shell" "com.android.chrome"; do
    local is_installed path
    is_installed=$(cmd package dump "$i" | grep codePath)
    if [ -n "$is_installed" ]; then
      path_name=$(echo $i | awk -F\. '{print $1}')
      ui_print "Webview $item detected"
      ui_print "Debloating $item"
      path=${is_installed##*=}
      mktouch $MODPATH/$path_name/.replace
    fi
  done
}
# This is actually really cool because all overlay generation is server side - we just need to tell the server what to make an overlay for by including sdk version, arch, which webview we used, and send over our framework-res.apk
# This may take a minute or two, because it's 50mb+ uploads+downloads, but for now we don't throttle this part of the processs which depending on resulting server load may change. Nonethelss, moving generation server side leads to more consistent results and opens up a lot more scalable possibilities for the future.
generate_overlay() {
  # Dynamically determine overlay path. Order of preference is /product/overlay -> /system_ext/overlay -> /system/overlay
  if [ -d /product/overlay ]; then
    device_overlay_path="$MODPTH/product/overlay"
  elif [ -d /system_ext/overlay ]; then 
    device_overlay_path="$MODPATH/system_ext/overlay"
  elif [ -d /system/overlay ]; then 
    device_overlay_path="$MODPATH/system/overlay"
  else
    ui_print "Unable to find a correct overlay path. Weird."
    abort "Device has no valid overlay path?"
  fi
  $can_use_fmmm_apis && showLoading || echo ""
  ui_print "Installing system overlay..."
  if [  ! -d $device_overlay_path ]; then
    mkdir -p $device_overlay_path
  fi
  makeDownloadRequest "/modules/webviemanager/$which/generateOverlay" 'POST' "sdk=$SDK&framework-res=@/system/framework/framework-res.apk&arch=$ARCH" $device_overlay_path/AndroidacyWebViewOverlay.apk
  if [ -f $device_overlay_path/AndroidacyWebViewOverlay.apk ]; then
    $can_use_fmmm_apis && hideLoading || echo ""
    ui_print "Overlay installed!"
    ui_print ""
    ui_print "Enjoy using a modern, updated webview! This should greatly improve browser"
    ui_print "and app performance and stability."
  else
    ui_print "Overlay installation failed - this may be due to your device not supporting this feature"
    ui_print "Continuing, but compatibility is not guaranteed"
  fi
}
# Sets a single config value in the config file
set_config_value() {
  # Make sure which was passed as first argument and value as second arg
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "No config value passed to set_config_value"
  else
    local key=$1
    local value=$2
    echo "Setting $key to $value"
    # Edit the conig.json
    # Hacky way of ensuring we have valid JSON, but if $1 is BROWSER_TYPE, don't add a comma at the end
    if [ "$key" = "BROWSER_TYPE" ]; then
      sed -i "s/\"$key\":.*/\"$key\": \"$value\"/g" $config_file
    else
      sed -i "s/\"$key\":.*/\"$key\": \"$value\",/g" $config_file
    fi
  fi
}
# Set the values in config.json to what the user selected
set_config_values() {
  # Make sure config.json exists
  if [ ! -f "$config_file" ]; then
    ui_print "No config.json found"
    abort "No config.json found"
  fi
  # Set the values in the config.json
  $can_use_fmmm_apis && showLoading || echo ""
  # Use sed to set the values in the config.json
  # Loop through WEBVIEW, BROWSER, WEBVIEW_TYPE, and BROWSER_TYPE
  for i in WEBVIEW BROWSER WEBVIEW_TYPE BROWSER_TYPE; do
    # Set the value in the config.json by replacing the line containing the key with the new value
    # Get value of the variable $i is set to
    value=$(eval echo \$$i)
    set_config_value $i $value
  done
  # Remove comma from second to last line in config.json
  $can_use_fmmm_apis && hideLoading || echo ""
  ui_print "Config values set"
}
## Install logic
# Master switch for allowing FoxMMM APIs to be used
export can_use_fmmm_apis
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
  cp_ch "$MODPATH/common/config.json" $config_file
  ignore_config=true
  . $config_file
fi
if [ "$ignore_config" = true ]; then
  ui_print "ⓘ Config file not found, starting setup..."
else
  ui_print "ⓘ Config file found! If you don't want to use it, delete it and restart the installation."
  ui_print "ⓘ Verifying config file..."
  verify_config
  if $USE_CONFIG; then
    ui_print "ⓘ Using config file..."
    # Set the values in the config.json to the values in the config file
    set_config_values
  else
    ui_print "ⓘ Starting setup..."
    volume_key_setup
  fi
  if $webview; then
    ui_print "ⓘ Setting up webviews..."
    verify_and_install_webview 'webview' $webview_type
    detect_and_debloat
  fi
  if $browser; then
    ui_print "ⓘ Setting up browser..."
    verify_and_install_webview 'browser' $browser_type
  fi
fi
