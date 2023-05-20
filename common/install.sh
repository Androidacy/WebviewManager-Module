# shellcheck shell=ksh
# shellcheck disable=SC1091,SC1090,SC2139,SC2086,SC3010,SC2034

TRY_COUNT=1
VF=0
VERIFY=true
config_file="$EXT_DATA/config.sh"
export webview=false
export browser=false
A=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
# ui_print "Checking for module updates..."
if ! dumpsys wifi | grep -q "Wi-Fi is enabled"; then
  ui_print "You may not be connected to WiFi and may incur data charges!"
fi
## Functions
# Make sure all config values are what we expect them to be
verify_config() {
  local browser webview webview_custom browser_custom webview_type browser_type
  $can_use_fmmm_apis && clearTerminal || echo ""
  ui_print "Verifying config..."
  $can_use_fmmm_apis && showLoading || echo ""
  # So far everything is valid
  . "$config_file"
  # If USE_CUSTOM_CONFIG=false, then the user's config will not be used.
  if $USE_CUSTOM_CONFIG; then
    # Browser must be false, or set to chromium, brave, kiwi, or bromite
    if [ "$BROWSER_CONFIG" = false ] || [ $BROWSER_CONFIG = chromium ] || [ $BROWSER_CONFIG = brave ] || [ $BROWSER_CONFIG = kiwi ] || [ $BROWSER_CONFIG = bromite ]; then
      $can_use_fmmm_apis && hideLoading || echo ""
      ui_print "Verified browser."
      $can_use_fmmm_apis && showLoading || echo ""
      browser=true
    else
      $can_use_fmmm_apis && hideLoading || echo ""
      abort "⚠ BROWSER value was not valid."
    fi
    # Next, webview must be false, or set to chromium, mulch, or bromite
    if [ "$WEBVIEW_CONFIG" = false ] || [ $WEBVIEW_CONFIG = chromium ] || [ $WEBVIEW_CONFIG = bromite ] || [ $WEBVIEW_CONFIG = mulch ]; then
      $can_use_fmmm_apis && hideLoading || echo ""
      ui_print "Verified webview choice."
      $can_use_fmmm_apis && showLoading || echo ""
      webview=true
    else
      $can_use_fmmm_apis && hideLoading || echo ""
      abort "⚠ WEBVIEW value was not valid."
    fi
    # If both are false it's an invalid config
    if [ "$browser" = false ] && [ "$webview" = false ]; then
      $can_use_fmmm_apis && hideLoading || echo ""
      abort "⚠ BROWSER and WEBVIEW were both set to false or invalid values."
    fi
    set_info "$BROWSER_CONFIG" "$WEBVIEW_CONFIG"
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
  KEYCHECK_FAIL=false
  export webview_type webview browser_type browser
  # First test the volume keys. Make user press up, then down, and make sure KEYCHECK_FAIL is not true.
  ui_print "📈 Press volume UP."
  if chooseport; then
    if $KEYCHECK_FAIL; then
      ui_print "- Vol keys Timed Out -"
      abort "⚠ Timed out waiting for volume key events"
    fi
    ui_print "📉 Press volume DOWN."
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
    webview_package="com.android.webview"
    webview_chosen=true
  fi
  if [ "$webview_chosen" = false ]; then
    ui_print "Option 2: Bromite"
    if chooseport; then
      ui_print "Chose Bromite"
      webview_type="bromite"
      webview=true
      webview_custom=false
      webview_package="org.bromite.webview"
      webview_chosen=true
    fi
  fi
  # Option 3 is mulch
  if [ "$webview_chosen" = false ]; then
    ui_print "Option 3: Mulch"
    if chooseport; then
      ui_print "Chose Mulch"
      webview_type="mulch"
      webview=true
      webview_custom=false
      webview_package="com.android.webview"
      webview_chosen=true
    fi
  fi
  # Option 4 is to try to use browser as webview
  if [ "$webview_chosen" = false ]; then
    ui_print "Option 4: Browser as webview"
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
    ui_print "Option 3: Custom"
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
      ui_print "Option 4: None"
      if chooseport; then
        ui_print "Chose None"
        browser=false
        browser_custom=false
        browser_chosen=true
      fi
    fi
    # ui_print "ⓘ Saving config"
    # set_config_values
    if [ $webview ]; then
      ui_print "ⓘ Setting up webviews..."
      download_webview 'webview' $webview_type
      detect_and_debloat
    fi
    if [ $browser ]; then
      ui_print "ⓘ Setting up browser..."
      download_webview 'browser' $browser_type
    fi
  else
    ui_print "You chose to use browser as webview, but did not select a browser. Bailing."
    abort "Browser as webview selected, but no browser selected"
  fi
}
set_info() {
  # Similar to above, set some variables based on the passed in WEBVIEW_CONFIG and BROWSER_CONFIG strings
  if [ "$2" = "chromium" ]; then
    webview_type="chromium"
    webview=true
    webview_custom=false
    webview_package="org.bromite.chrome"
    webview_chosen=true
  elif [ "$2" = "bromite" ]; then
    webview_type="bromite"
    webview=true
    webview_custom=false
    webview_package="org.bromite.bromite"
    webview_chosen=true
  elif [ "$2" = "browser" ]; then
    webview_type="browser"
    webview=true
    webview_custom=false
    webview_chosen=true
  elif [ "$2" = "mulch" ]; then
    webview_type="mulch"
    webview=true
    webview_custom=false
    webview_package="com.android.webview"
    webview_chosen=true
  elif [ "$2" = "none" ]; then
    webview=false
    webview_custom=false
    webview_chosen=true
  else
    ui_print "Unknown WEBVIEW_CONFIG value passed in... bailing"
    abort "Unknown value for WEBVIEW_CONFIG passed in."
  fi
  # Same for browser
  if [ "$1" = "chromium" ]; then
    browser_type="chromium"
    browser=true
    browser_custom=false
    browser_package="org.bromite.chrome"
    browser_chosen=true
  elif [ "$1" = "bromite" ]; then
    browser_type="bromite"
    browser=true
    browser_custom=false
    browser_package="org.bromite.bromite"
    browser_chosen=true
  elif [ "$1" = "browser" ]; then
    browser_type="browser"
    browser=true
    browser_custom=false
    browser_chosen=true
  elif [ "$1" = "custom" ]; then
    browser_type="custom"
    browser=true
    browser_custom=true
    browser_chosen=true
  elif [ "$1" = "none" ]; then
    if $need_browser_choice; then
      ui_print "You chose to use browser as webview but no browser was selected. Bailing."
      abort "Browser as webview selected, but no browser selected."
    else
      browser=false
      browser_custom=false
      browser_chosen=true
    fi
    # return 0;
  else
    ui_print "Unknown BROWSER_CONFIG value passed in... bailing"
    abort "Unknown value for BROWSER_CONFIG passed in."
  fi
}
use_cached_webview() {
  export use_cached
  use_cached=false
  # check if "$EXT_DATA/apks/$which-$type.apk" and "$EXT_DATA/apks/$which-$type.apk.sha256sum" exist and are less than a day old
  # if so, verify the sha256sum and set use_cached to true
  local which type
  type=$2
  which=$1
  if [ -f "$EXT_DATA/apks/$which-$type.apk" ] && [ -f "$EXT_DATA/apks/$which-$type.sha256sum" ]; then
    local apk_sha256sum apk_sha256sum_new
    apk_sha256sum=$(cat "$EXT_DATA/apks/$which-$type.sha256sum")
    apk_sha256sum_new=$(sha256sum "$EXT_DATA/apks/$which-$type.apk" | cut -d ' ' -f 1)
    if [ "$apk_sha256sum" = "$apk_sha256sum_new" ]; then
      local apk_age=$(($(date +%s) - $(date +%s -r "$EXT_DATA/apks/$which-$type.apk")))
      if [ $apk_age -lt 86400 ]; then
        use_cached=true
      fi
    fi
  fi
}
# Downloads a webview using makeFileRequest and then extracts it using unzip.
download_webview() {
  # Make sure which was passed as first argument and type as second arg
  if [ -z "$1" ] || [ -z "$2" ]; then
    abort "No webview type passed to download_webview"
  fi
  local type=$2
  local which=$1
  $can_use_fmmm_apis && showLoading || echo ""
  use_cached_webview $which $type
  # Make a temporary directory to download the webview to
    webview_tmp_dir="/data/local/tmp/$which-tmp"
    if [ -d "$webview_tmp_dir" ]; then
      rm -rf $webview_tmp_dir
      mkdir -p $webview_tmp_dir
    else
      mkdir -p $webview_tmp_dir
    fi
  if ! $use_cached; then
    ui_print "Downloading $which..."
    makeFileRequest "/modules/webviewmanager/$which/download/$type" 'GET' "arch=$ARCH" "$webview_tmp_dir/$type.apk"
    # Next, verify and install the webview
    if [ ! -f "$webview_tmp_dir/$type.apk" ]; then
      ui_print "Download failed"
      abort "Download failed"
    fi
  else
    ui_print "Using cached $which..."
    cp_ch $EXT_DATA/apks/$which-$type.apk $webview_tmp_dir/$type.apk
  fi
  $can_use_fmmm_apis && hideLoading || echo ""
  ui_print "Download successful"
  verify_and_install_webview $webview_tmp_dir/$type.apk $which $type
}
# Verifies and installs a webview
verify_and_install_webview() {
  # Make sure which was passed as second argument and type as third arg
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    abort "No webview type passed to verify_and_install_webview"
  fi
  local type=$3
  local which=$2
  local apk=$1
  ui_print "Verifying $which..."
  $can_use_fmmm_apis && showLoading || echo ""
  # Get the SHA256 hash of the webview
  local sha256
  # use busybox from magisk to get sha256sum
  if [ -f "/sbin/sha256sum" ]; then
    sha256=$(/sbin/sha256sum $apk | cut -d' ' -f1)
  else
    sha256=$(sha256sum $apk | cut -d' ' -f1)
  fi
  # POST the hash to the server to get the hash of the webview to compare with
  local status
  status=$(makeJSONRequest "/modules/webviewmanager/verify/$which/$type" "arch=$ARCH&client_hash=$sha256" 'GET' 'verified')
  # Make sure status is true
  if [ "$status" = "true" ]; then
    ui_print "Verification successful"
    $can_use_fmmm_apis && hideLoading || echo ""
    ui_print "Installing $which..."
    $can_use_fmmm_apis && showLoading || echo ""
    # Install the webview
    mkdir -p $MODPATH/system/app/$which-$type/lib
    mkdir -p $MODPATH/system/app/$which-$type/lib/arm
    mkdir -p $MODPATH/system/app/$which-$type/lib/arm64
    unzip -q $apk 'lib/*' -d $webview_tmp_dir/$type
    cp_ch -r $webview_tmp_dir/$type/lib/arm64-v8a/* $MODPATH/system/app/$which-$type/lib/arm64/
    cp_ch -r $webview_tmp_dir/$type/lib/armeabi-v7a/* $MODPATH/system/app/$which-$type/lib/arm/
    cp_ch $apk "$MODPATH/system/app/$which-$type/$type.apk"
    cp_ch $MODPATH/system/app/$which-$type/$type.apk "$EXT_DATA/apks/$which-$type.apk"
    # echo the expected sha256 hash to a file
    echo $sha256 >"$EXT_DATA/apks/$which-$type.sha256sum"
    mktouch $MODPATH/system/app/$which-$type/.replace
    if [ "$which" == 'webview' ]; then
      detect_and_debloat
      generate_overlay
    fi
    $can_use_fmmm_apis && hideLoading || echo ""
    ui_print "Installation complete"
  else
    ui_print "Verification failed: $status"
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
# This may take a minute or two, because it's 50mb+ uploads+downloads, but for now we don't throttle this part of the process which depending on resulting server load may change. Nonetheless, moving generation server side leads to more consistent results and opens up a lot more scalable possibilities for the future.
generate_overlay() {
  # Dynamically determine overlay path. Order of preference is /product/overlay -> /system_ext/overlay -> /system/overlay
  if [ -d /product/overlay ]; then
    device_overlay_path="$MODPATH/product/overlay"
  elif [ -d /system_ext/overlay ]; then
    device_overlay_path="$MODPATH/system_ext/overlay"
  elif [ -d /system/overlay ]; then
    device_overlay_path="$MODPATH/system/overlay"
  else
    ui_print "Unable to find a correct overlay path. Weird."
    abort "Device has no valid overlay path?"
  fi
  $can_use_fmmm_apis && showLoading || echo ""
  ui_print "Installing system overlay. Please be patient, this may take awhile..."
  if [ ! -d $device_overlay_path ]; then
    mkdir -p $device_overlay_path
  fi
  tar -caf fw.tar.bz2 framework-res.apk -C /system/framework 2>/dev/null
  makeFileRequest "/modules/webviewmanager/$webview_type/generateOverlay?sdk=$SDK&arch=$ARCH" 'POST' "framework-res=@fw.tar.bz2" $device_overlay_path/AndroidacyWebViewOverlay.apk
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
# Set the values in config.sh to what the user selected
set_config_values() {
  # Make sure config.sh exists
  if [ ! -f "$config_file" ]; then
    ui_print "No config.sh found"
    abort "No config.sh found"
  fi
  # Set the values in the config.sh
  $can_use_fmmm_apis && showLoading || echo ""
  # Use sed to set the values in the config.sh
  # Loop through WEBVIEW, BROWSER, WEBVIEW_TYPE, and BROWSER_TYPE
  for i in WEBVIEW BROWSER WEBVIEW_TYPE BROWSER_TYPE; do
    # Set the value in the config.sh by replacing the line containing the key with the new value
    # Get value of the variable $i is set to
    value=$(eval echo $i)
    set_config_value $i $value
  done
  # Remove comma from second to last line in config.sh
  $can_use_fmmm_apis && hideLoading || echo ""
  ui_print "Config values set"
}

# Checks for updates
isUpdated() {
  local ourVersion
  # Get our current version defined in module.prop
  ourVersion=$(grep_prop versionCode $TMPDIR/module.prop)
  # Request the api for the version number of bromitewebview (our codename)
  local status
  status=$(makeJSONRequest "/modules/webviewmanager/versionCheck" "version=$ourVersion&device=$DEVICE&sdk=$SDK" "GET" ".status")
  # If status is "error", then our version is out of date
  if [ "$status" = "error" ]; then
    ui_print "You are running an outdated version of this module"
    ui_print "Update to get the latest and greatest features!"
    # Launch browser with update url
    am start -a android.intent.action.VIEW -d "https://www.androidacy.com/magisk-modules-repository/#bromiewebview" >/dev/null
    abort
  fi
}
isUpdated
## Install logic
# Master switch for allowing FoxMMM APIs to be used
export can_use_fmmm_apis
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
  # cp_ch "$MODPATH/common/config.sh" $config_file
  ignore_config=true
fi
if [ "$ignore_config" = true ]; then
  ui_print "ⓘ Config file not found, starting setup..."
  volume_key_setup
else
  ui_print "ⓘ Config file found! If you don't want to use it, delete it and restart the installation."
  ui_print "ⓘ Verifying config file..."
  verify_config
  if $USE_CONFIG; then
    ui_print "ⓘ Using config file..."
    # Set the values in the config.sh to the values in the config file
    if [ $webview ]; then
      ui_print "ⓘ Setting up webviews..."
      download_webview 'webview' $webview_type
      detect_and_debloat
    fi
    if [ $browser ]; then
      ui_print "ⓘ Setting up browser..."
      download_webview 'browser' $browser_type
    fi
  else
    ui_print "ⓘ Starting setup..."
    volume_key_setup
    ui_print "ⓘ Completed setup"
  fi
  if [ ! $webview ] && [ ! $browser ]; then
    abort "Nothing chosen!"
  fi
fi
