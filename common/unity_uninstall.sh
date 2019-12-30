 # If you are reading this you owe me $10 => https://paypal.me/innonetlife
# Forces Android to rebuild package cache and re-registered old webview
rm -rf /data/resource-cache/*
rm -rf /data/dalvik-cache/*
rm -rf /cache/dalvik-cache/*
rm -rf /data/*/com.android.webview*
rm -rf /data/system/package_cache/*
# Reinstall old webview
for i in /system/product/app /system/app; do
		pm install - r $i/.eb.iew*/.eb.ie*.apk
	done