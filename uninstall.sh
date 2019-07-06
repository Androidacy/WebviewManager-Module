# Forces Android to rebuild package cache and re-registered old webview
rm -rf /data/resource-cache/*
rm -rf /data/dalvik-cache/*
rm -rf /cache/dalvik-cache/*
rm -rf /data/*/com.android.webview*
rm -rf /data/system/package_cache/*
# Reinstall old webview
pm install -r /system/*/*webview*/*.apk
# Only needed on Pixel ROMs
pm install -r /system/product/*/*webview*/*.apk