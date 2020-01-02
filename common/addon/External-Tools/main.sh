# External Tools

chmod -R 0755 $MODPATH/common/addon/External-Tools
if $IS64BIT; then
  [ -d $MODPATH/common/addon/External-Tools/tools/arm64 ] && mv -f $MODPATH/common/addon/External-Tools/tools/arm64/* $MODPATH/common/addon/External-Tools/tools/arm
  [ -d $MODPATH/common/addon/External-Tools/tools/x64 ] && mv -f $MODPATH/common/addon/External-Tools/tools/x64/* $MODPATH/common/addon/External-Tools/tools/x86
fi
cp -R $MODPATH/common/addon/External-Tools/tools $UF 2>/dev/null
[ -d "$UF/tools/other" ] && PATH=$UF/tools/other:$PATH
