 # If you are reading this you owe me $10 => https://paypal.me/innonetlife
if [ "$(ls -d /system/product/overlay 2>/dev/null)" ]
then if ! grep -q "me.phh.treble.overlay.webview" /data/system/overlays.xml; then
      sed -i 's|</overlays>|    <item packageName="me.phh.treble.overlay.webview" userId="0" targetPackageName="android" baseCodePath="/system/product/overlay/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|' /data/system/overlays.xml
      fi
elif  [ "$(ls -d /vendor/overlay 2>/dev/null)" ]
then if ! grep -q "me.phh.treble.overlay.webview" /data/system/overlays.xml; then
      sed -i 's|</overlays>|    <item packageName="me.phh.treble.overlay.webview" userId="0" targetPackageName="android" baseCodePath="/vendor/overlay/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|' /data/system/overlays.xml
      fi
fi
