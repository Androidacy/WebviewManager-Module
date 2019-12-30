 # If you are reading this you owe me $10 => https://paypal.me/innonetlife

  $BOOTMODE || abort "! This is for magisk manager only because it needs an internet connection!"
  # Download corresponding libs/apk
  chmod +x $TMPDIR/common/unityfiles/tools/$ARCH32/curl-$ARCH32
  alias curl=$TMPDIR/common/unityfiles/tools/$ARCH32/curl-$ARCH32
  ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
  ui_print "- Downloading extra files please be patient..."
  V=$(curl -k --silent "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
  URL=https://github.com/bromite/bromite/releases/download/$V/${ARCH}_SystemWebView.apk
#  ui_print "$V $URL"
  curl -k -L -o $TMPDIR/webview.apk $URL
  #  ui_print "- Extracting downloaded files..."
  cp_ch -i $TMPDIR/webview.apk $MODPATH/system/app/webview/webview.apk
	ui_print "- Removing old webview traces and clearing cache..."
	ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
	ui_print "Reboot immediately after flashing or you may experience some issues! "
	ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
	ui_print "Also, if you had any other webview such as Google webview, it'll need reinstalled"
	ui_print "Chrome will be a preferred webview if installed, so you should disable it"
	ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"
    rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
# For now, this next line is going to be removed until I can figure out how to make it less aggressive
#  rm -rf /data/*/*chrome*
	for i in /system/product/app /system/app; do
		[ -d $ORIGDIR$i/Chrome ] && mktouch $MODPATH$i/Chrome/.replace
		[ -d $ORIGDIR$i/chrome ] && mktouch $MODPATH$i/chrome/.replace
	done
	for i in /system/product/overlay /system/vendor/overlay; do
		[ -d $ORIGDIR$i ] && cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH$i/treble-overlay-webview.apk
	done
    for i in /system/product/app /system/app; do
        WEBVIEW=$(ls $i|grep .eb.iew*)
	done
    for i in /system/product/app /system/app; do
		mktouch $MODPATH$i/$WEBVIEW/.replace
	done
	pm uninstall com.google.android.webview