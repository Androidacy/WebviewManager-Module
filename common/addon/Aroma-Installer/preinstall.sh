# Aroma Installer

[ ! -d /cache -o -L /cache ] && CACHEDIR=/data/cache || CACHEDIR=/cache

if [ -d "$CACHEDIR/$MODID" ]; then
  ui_print "   Continuing install with aroma options"
  # Save selections to Mod
  for i in $CACHEDIR/$MODID/*.prop; do
    cp_ch -n $i $UNITY/system/etc/$MODID/$(basename $i)
  done
  rm -f $CACHEDIR/$MODID.zip $CACHEDIR/$MODID-Aroma.zip $CACHEDIR/recovery/openrecoveryscript
  rm -rf $CACHEDIR/$MODID
else
  # Delete space hogging boot_log folder
  rm -rf $CACHEDIR/boot_log
  if [ -d "$TMPDIR/aroma" ]; then
    # Move previous selections to temp directory for reuse if chosen
    ui_print "   Backup up previous selections..."
    for FILE in $TMPDIR/aroma/*.prop; do
      cp_ch -i $FILE $CACHEDIR/$MODID/$(basename $FILE)
    done
  fi
  ui_print "   Creating Aroma installer and open recovery script..."
  cp -f $ZIPFILE $CACHEDIR/$MODID.zip
  cd $MODPATH/common/addon/Aroma-Installer
  sed -i -e "2i MODID=$MODID" -e "2i CACHEDIR=$CACHEDIR" META-INF/com/google/android/update-binary-installer
  chmod -R 0755 tools
  cp -R tools $UF 2>/dev/null
  zip -qr0 $CACHEDIR/$MODID-Aroma META-INF
  cd /
  echo -e "install $CACHEDIR/$MODID-Aroma.zip\ninstall $CACHEDIR/$MODID.zip\nreboot recovery" > $CACHEDIR/recovery/openrecoveryscript
  ui_print "   Will reboot and launch aroma installer"
  cleanup
fi
