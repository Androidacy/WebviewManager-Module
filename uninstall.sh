<<<<<<< HEAD
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
=======
FILE=${0%/*}/<MODID>-files
if [ -f $FILE ]; then
  while read LINE; do
    if [ "$(echo -n $LINE | tail -c 1)" == "~" ] || [ "$(echo -n $LINE | tail -c 9)" == "NORESTORE" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f $LINE~ $LINE
    else
      rm -f $LINE
      while true; do
        LINE=$(dirname $LINE)
        [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
      done
    fi
  done < $FILE
fi
>>>>>>> 5bc76bf8094a5d1ee1da22ea560406f786012e9e
