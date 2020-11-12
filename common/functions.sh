##########################################################################################
#
# MMT Extended Utility Functions
#
##########################################################################################
# shellcheck shell=dash
# Its broken okay?!?!
# shellcheck disable=SC2155
# shellcheck disable=SC2034
# shellcheck disable=SC1090
# shellcheck disable=SC2086
# shellcheck disable=SC2169
# shellcheck disable=SC2046
# shellcheck disable=SC2044
# shellcheck disable=SC2166
# shellcheck disable=SC2061

abort() {
  ui_print "$1"
  rm -rf $MODPATH 2>/dev/null
  $BOOTMODE || recovery_cleanup
  rm -rf $TMPDIR 2>/dev/null
  exit 1
}

mount_apex() {
  $BOOTMODE || [ ! -d /system/apex ] && return
  local APEX DEST
  setup_mntpoint /apex
  for APEX in /system/apex/*; do
    DEST=/apex/$(basename $APEX .apex)
    [ "$DEST" == /apex/com.android.runtime.release ] && DEST=/apex/com.android.runtime
    mkdir -p $DEST 2>/dev/null
    if [ -f $APEX ]; then
      # APEX APKs, extract and loop mount
      unzip -qo $APEX apex_payload.img -d /apex
      loop_setup apex_payload.img
      if [ -n "$LOOPDEV" ]; then
        ui_print "- Mounting $DEST"
        mount -t ext4 -o ro,noatime $LOOPDEV $DEST
      fi
      rm -f apex_payload.img
    elif [ -d $APEX ]; then
      # APEX folders, bind mount directory
      ui_print "- Mounting $DEST"
      mount -o bind $APEX $DEST
    fi
  done
  export ANDROID_RUNTIME_ROOT=/apex/com.android.runtime
  export ANDROID_TZDATA_ROOT=/apex/com.android.tzdata
  local APEXRJPATH=/apex/com.android.runtime/javalib
  local SYSFRAME=/system/framework
  export BOOTCLASSPATH=\
$APEXRJPATH/core-oj.jar:$APEXRJPATH/core-libart.jar:$APEXRJPATH/okhttp.jar:\
$APEXRJPATH/bouncycastle.jar:$APEXRJPATH/apache-xml.jar:$SYSFRAME/framework.jar:\
$SYSFRAME/ext.jar:$SYSFRAME/telephony-common.jar:$SYSFRAME/voip-common.jar:\
$SYSFRAME/ims-common.jar:$SYSFRAME/android.test.base.jar:$SYSFRAME/telephony-ext.jar:\
/apex/com.android.conscrypt/javalib/conscrypt.jar:\
/apex/com.android.media/javalib/updatable-media.jar
}

umount_apex() {
  [ -d /apex ] || return
  local DEST SRC
  for DEST in /apex/*; do
    [ "$DEST" = '/apex/*' ] && break
    SRC=$(grep $DEST /proc/mounts | awk '{ print $1 }')
    umount -l $DEST
    # Detach loop device just in case
    losetup -d $SRC 2>/dev/null
  done
  rm -rf /apex
  unset ANDROID_RUNTIME_ROOT
  unset ANDROID_TZDATA_ROOT
  unset BOOTCLASSPATH
}


cleanup() {
  rm -rf $MODPATH/common 2>/dev/null
  ui_print " "
  ui_print "    **************************************"
  ui_print "    *   MMT Extended by Zackptg5 @ XDA   *"
  ui_print "    *      Modified by Alexandria        *"
  ui_print "    **************************************"
  ui_print " "
}

device_check() {
  local opt=$(getopt -o dm -- "$@") type=device
  eval set -- "$opt"
  while true; do
    case "$1" in
      -d) local type=device; shift;;
      -m) local type=manufacturer; shift;;
      --) shift; break;;
      *) abort "Invalid device_check argument $1! Aborting!";;
    esac
  done
  local prop=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  for i in /system /vendor /odm /product; do
    if [ -f $i/build.prop ]; then
      for j in "ro.product.$type" "ro.build.$type" "ro.product.vendor.$type" "ro.vendor.product.$type"; do
        [ "$(sed -n "s/^$j=//p" $i/build.prop 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$prop" ] && return 0
      done
    fi
  done
  return 1
}

cp_ch() {
  local opt=$(getopt -o nr -- "$@") BAK=true UBAK=true FOL=false
  eval set -- "$opt"
  while true; do
    case "$1" in
      -n) UBAK=false; shift;;
      -r) FOL=true; shift;;
      --) shift; break;;
      *) abort "Invalid cp_ch argument $1! Aborting!";;
    esac
  done
  local SRC="$1" DEST="$2" OFILES="$1"
  $FOL && local OFILES=$(find $SRC -type f 2>/dev/null)
  [ -z $3 ] && PERM=0644 || PERM=$3
  case "$DEST" in
    $TMPDIR/*|$MODULEROOT/*|$NVBASE/modules/$MODID/*) BAK=false;;
  esac
  for OFILE in ${OFILES}; do
    if $FOL; then
      if [ "$(basename $SRC)" == "$(basename $DEST)" ]; then
        local FILE=$(echo $OFILE | sed "s|$SRC|$DEST|")
      else
        local FILE=$(echo $OFILE | sed "s|$SRC|$DEST/$(basename $SRC)|")
      fi
    else
      if [[ -d "$DEST" ]]
      then
        local FILE="$DEST/$(basename $SRC)"
      else
        local FILE="$DEST"
      fi
    fi
    if $BAK && $UBAK; then
    # shellcheck disable=SC2143
      [ ! "$(grep "$FILE$" $INFO 2>/dev/null)" ] && echo "$FILE" >> $INFO
      [ -f "$FILE" -a ! -f "$FILE~" ] && { mv -f $FILE $FILE~; echo "$FILE~" >> $INFO; }
    elif $BAK; then
      # shellcheck disable=SC2143
      [ ! "$(grep "$FILE$" $INFO 2>/dev/null)" ] && echo "$FILE" >> $INFO
    fi
    install -D -m $PERM "$OFILE" "$FILE"
  done
}

install_script() {
  case "$1" in
    -l) shift; local INPATH=$NVBASE/service.d;;
    -p) shift; local INPATH=$NVBASE/post-fs-data.d;;
    *) local INPATH=$NVBASE/service.d;;
  esac
  # shellcheck disable=SC2143
  [ "$(grep "#!/system/bin/sh" $1)" ] || sed -i "1i #!/system/bin/sh" $1
  local i; for i in "MODPATH" "LIBDIR" "MODID" "INFO" "MODDIR"; do
    case $i in
      "MODPATH") sed -i "1a $i=$NVBASE/modules/$MODID" $1;;
      "MODDIR") sed -i "1a $i=\${0%/*}" $1;;
      *) sed -i "1a $i=$(eval echo \$$i)" $1;;
    esac
  done
  [ "$1" == "$MODPATH/uninstall.sh" ] && return 0
  case $(basename $1) in
    post-fs-data.sh|service.sh) ;;
    *) cp_ch -n $1 $INPATH/$(basename $1) 0755;;
  esac
}

prop_process() {
  sed -i -e "/^#/d" -e "/^ *$/d" $1
  [ -f $MODPATH/system.prop ] || mktouch $MODPATH/system.prop
  while read -r LINE; do
    echo "$LINE" >> $MODPATH/system.prop
  done < $1
}

# Check for min/max api version
[ -z $MINAPI ] || { [ $API -lt $MINAPI ] && abort "! Your system API of $API is less than the minimum api of $MINAPI! Aborting!"; }
[ -z $MAXAPI ] || { [ $API -gt $MAXAPI ] && abort "! Your system API of $API is greater than the maximum api of $MAXAPI! Aborting!"; }

# Set variables
[ $API -lt 26 ] && DYNLIB=false
[ -z $DYNLIB ] && DYNLIB=false
[ -z $DEBUG ] && DEBUG=false
[ -e "$PERSISTDIR" ] && PERSISTMOD=$PERSISTDIR/magisk/$MODID
INFO=$NVBASE/modules/.$MODID-files
ORIGDIR="$MAGISKTMP/mirror"
if $DYNLIB; then
  LIBPATCH="\/vendor"
  LIBDIR=/system/vendor
else
  LIBPATCH="\/system"
  LIBDIR=/system
fi

# Debug
if $DEBUG; then
  ui_print "- Debug mode"
  ui_print "  Module install log will include debug info"
  ui_print "  It's in /sdcard/WebviewSwitcher/logs"
  mkdir -p /data/media/0/WebviewSwitcher/logs/
  exec 2>/data/media/0/WebviewSwitcher/logs/install.log 
  set -x
fi

# Extract files
ui_print "- Extracting module files"
unzip -o "$ZIPFILE" -x 'META-INF/*' 'common/functions.sh' -d $MODPATH >&2
[ -f "$MODPATH/common/addon.tar.xz" ] && tar -xf $MODPATH/common/addon.tar.xz -C $MODPATH/common 2>/dev/null

# Run addons
if [ "$(ls -A $MODPATH/common/addon/*/install.sh 2>/dev/null)" ]; then
  ui_print " "; ui_print "- Running Addons -"
  for i in "$MODPATH"/common/addon/*/install.sh; do
    ui_print "  Running $(echo $i | sed -r "s|$MODPATH/common/addon/(.*)/install.sh|\1|")..."
    . $i
  done
fi

# Remove files outside of module directory
ui_print "- Removing old files"

if [ -f $INFO ]; then
  while read -r LINE; do
    if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f $LINE~ $LINE
    else
      rm -f $LINE
      while true; do
        LINE=$(dirname $LINE)
        if [[ "$(ls -A $LINE 2>/dev/null)" ]]
        then
          break 1
        else
          rm -rf $LINE
        fi
      done
    fi
  done < $INFO
  rm -f $INFO
fi

### Install
ui_print "- Installing"

if test -d /data/adb/modules/"$MODID";
then
  VERSIONMOD=$(grep versionCode /data/adb/modules/"$MODID"/module.prop | tail -c +13)
  TMPMOD=$(grep versionCode  "$TMPDIR"/module.prop | tail -c +13)
  if test "$VERSIONMOD" -le "$TMPMOD"
  then
    touch "$MODPATH"/remove
    ui_print " Same or older version detected, removing!"
    exit 0
  fi
fi
[ -f "$MODPATH/common/install.sh" ] && . $MODPATH/common/install.sh

# Remove comments from files and place them, add blank line to end if not already present
for i in $(find $MODPATH -type f -name "*.sh" -o -name "*.prop" -o -name "*.rule"); do
  if [[ -f $i ]]
  then
    { sed -i -e "/^#/d" -e "/^ *$/d" $i; [ "$(tail -1 $i)" ] && echo "" >> $i; }
  else
    continue
  fi
  case $i in
    "$MODPATH/service.sh") install_script -l $i;;
    "$MODPATH/post-fs-data.sh") install_script -p $i;;
    "$MODPATH/uninstall.sh") if [ -s $INFO ] || [ "$(head -n1 $MODPATH/uninstall.sh)" != "# Don't modify anything after this" ]; then
                               install_script $MODPATH/uninstall.sh
                             else
                               rm -f $INFO $MODPATH/uninstall.sh
                             fi;;
  esac
done

$IS64BIT || for i in $(find $MODPATH/system -type d -name "lib64"); do rm -rf $i 2>/dev/null; done  
[ -d "/system/priv-app" ] || mv -f $MODPATH/system/priv-app $MODPATH/system/app 2>/dev/null
[ -d "/system/xbin" ] || mv -f $MODPATH/system/xbin $MODPATH/system/bin 2>/dev/null
if $DYNLIB; then
  for FILE in $(find $MODPATH/system/lib* -type f 2>/dev/null | sed "s|$MODPATH/system/||"); do
    [ -s $MODPATH/system/$FILE ] || continue
    case $FILE in
      lib*/modules/*) continue;;
    esac
    mkdir -p "$(dirname $MODPATH/system/vendor/$FILE)"
    mv -f $MODPATH/system/$FILE $MODPATH/system/vendor/$FILE
    [ "$(ls -A $(dirname $MODPATH/system/$FILE))" ] || rm -rf $(dirname $MODPATH/system/$FILE)
  done
  # Delete empty lib folders (busybox find doesn't have this capability)
  toybox find $MODPATH/system/* -type d -empty -delete >/dev/null 2>&1
fi

# Set permissions
ui_print " "
ui_print "- Setting Permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d $MODPATH/system/vendor ]; then
  set_perm_recursive $MODPATH/system/vendor 0 0 0755 0644 u:object_r:vendor_file:s0
  [ -d $MODPATH/system/vendor/app ] && set_perm_recursive $MODPATH/system/vendor/app 0 0 0755 0644 u:object_r:vendor_app_file:s0
  [ -d $MODPATH/system/vendor/etc ] && set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
  [ -d $MODPATH/system/vendor/overlay ] && set_perm_recursive $MODPATH/system/vendor/overlay 0 0 0755 0644 u:object_r:vendor_overlay_file:s0
  for FILE in $(find $MODPATH/system/vendor -type f -name -- *".apk"); do
    [ -f $FILE ] && chcon u:object_r:vendor_app_file:s0 $FILE
  done
fi
set_permissions

# Complete install
cleanup
