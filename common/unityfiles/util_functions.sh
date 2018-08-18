##########################################################################################
#
# Unity (Un)Install Utility Functions
# Adapted from topjohnwu's Magisk General Utility Functions
#
# Magisk util_functions is still used and will override any listed here
# They're present for system installs
#
##########################################################################################

toupper() {
  echo "$@" | tr '[:lower:]' '[:upper:]'
}

find_block() {
  for BLOCK in "$@"; do
    DEVICE=`find /dev/block -type l -iname $BLOCK | head -n 1` 2>/dev/null
    if [ ! -z $DEVICE ]; then
      readlink -f $DEVICE
      return 0
    fi
  done
  # Fallback by parsing sysfs uevents
  for uevent in /sys/dev/block/*/uevent; do
    local DEVNAME=`grep_prop DEVNAME $uevent`
    local PARTNAME=`grep_prop PARTNAME $uevent`
    for p in "$@"; do
      if [ "`toupper $p`" = "`toupper $PARTNAME`" ]; then
        echo /dev/block/$DEVNAME
        return 0
      fi
    done
  done
  return 1
}

mount_partitions() {
  # Check A/B slot
  SLOT=`grep_cmdline androidboot.slot_suffix`
  if [ -z $SLOT ]; then
    SLOT=_`grep_cmdline androidboot.slot`
    [ $SLOT = "_" ] && SLOT=
  fi
  [ -z $SLOT ] || ui_print "- Current boot slot: $SLOT"
  ui_print "- Mounting /system, /vendor"
  REALSYS=/system
  [ -f /system/build.prop ] || is_mounted /system || mount -o rw /system 2>/dev/null
  if ! is_mounted /system && ! [ -f /system/build.prop ]; then
    SYSTEMBLOCK=`find_block system$SLOT`
    mount -t ext4 -o rw $SYSTEMBLOCK /system
  fi
  [ -f /system/build.prop ] || is_mounted /system || abort "! Cannot mount /system"
  cat /proc/mounts | grep -E '/dev/root|/system_root' >/dev/null && SYSTEM_ROOT=true || SYSTEM_ROOT=false
  if [ -f /system/init ]; then
    ROOT=/system_root
    REALSYS=/system_root/system
    SYSTEM_ROOT=true
    mkdir /system_root 2>/dev/null
    mount --move /system /system_root
    mount -o bind /system_root/system /system
  fi
  $SYSTEM_ROOT && ui_print "- Device using system_root_image"
  if [ -L /system/vendor ]; then
    # Seperate /vendor partition
    VEN=/vendor
    REALVEN=/vendor
    is_mounted /vendor || mount -o rw /vendor 2>/dev/null
    if ! is_mounted /vendor; then
      VENDORBLOCK=`find_block vendor$SLOT`
      mount -t ext4 -o rw $VENDORBLOCK /vendor
    fi
    is_mounted /vendor || abort "! Cannot mount /vendor"
  else
    VEN=/system/vendor
    REALVEN=$REALSYS/vendor
  fi
}

grep_cmdline() {
  local REGEX="s/^$1=//p"
  sed -E 's/ +/\n/g' /proc/cmdline | sed -n "$REGEX" 2>/dev/null
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

find_boot_image() {
  BOOTIMAGE=
  if [ ! -z $SLOT ]; then
    BOOTIMAGE=`find_block boot$SLOT ramdisk$SLOT`
  else
    BOOTIMAGE=`find_block boot ramdisk boot_a kern-a android_boot kernel lnx bootimg`
  fi
  if [ -z $BOOTIMAGE ]; then
    # Lets see what fstabs tells me
    BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
  fi
}

flash_boot_image() {
  # Make sure all blocks are writable
  $BINDIR/magisk --unlock-blocks 2>/dev/null
  case "$1" in
    *.gz) COMMAND="gzip -d < '$1'";;
    *)    COMMAND="cat '$1'";;
  esac
  if $BOOTSIGNED; then
    SIGNCOM="$BOOTSIGNER /boot $1 $AVB/verity.pk8 $AVB/verity.x509.pem"
    # SIGNCOM="$BOOTSIGNER -sign"
    ui_print "- Sign boot image with test keys"
  else
    SIGNCOM="cat -"
  fi
  case "$2" in
    /dev/block/*)
      ui_print "- Flashing new boot image"
      eval $COMMAND | eval $SIGNCOM | cat - /dev/zero 2>/dev/null | dd of="$2" bs=4096 2>/dev/null
      ;;
    *)
      ui_print "- Storing new boot image"
      eval $COMMAND | eval $SIGNCOM | dd of="$2" bs=4096 2>/dev/null
      ;;
  esac
}

sign_chromeos() {
  ui_print "- Signing ChromeOS boot image"

  echo > empty
  ./chromeos/futility vbutil_kernel --pack new-boot.img.signed \
  --keyblock ./chromeos/kernel.keyblock --signprivate ./chromeos/kernel_data_key.vbprivk \
  --version 1 --vmlinuz new-boot.img --config empty --arch arm --bootloader empty --flags 0x1

  rm -f empty new-boot.img
  mv new-boot.img.signed new-boot.img
}

is_mounted() {
  cat /proc/mounts | grep -q " `readlink -f $1` " 2>/dev/null
  return $?
}

api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

setup_bb() {
  if [ -x /sbin/.core/busybox/busybox ]; then
    # Make sure this path is in the front
    echo $PATH | grep -q '^/sbin/.core/busybox' || export PATH=/sbin/.core/busybox:$PATH
  elif [ -x $TMPDIR/bin/busybox ]; then
    # Make sure this path is in the front
    echo $PATH | grep -q "^$TMPDIR/bin" || export PATH=$TMPDIR/bin:$PATH
  else
    # Construct the PATH
    mkdir -p $TMPDIR/bin
    ln -s $MAGISKBIN/busybox $TMPDIR/bin/busybox
    $MAGISKBIN/busybox --install -s $TMPDIR/bin
    export PATH=$TMPDIR/bin:$PATH
  fi
}

boot_actions() {
  if [ ! -d /sbin/.core/mirror/bin ]; then
    mkdir -p /sbin/.core/mirror/bin
    mount -o bind $MAGISKBIN /sbin/.core/mirror/bin
  fi
  MAGISKBIN=/sbin/.core/mirror/bin
  setup_bb
}

recovery_actions() {
  # TWRP bug fix
  mount -o bind /dev/urandom /dev/random
  # Preserve environment varibles
  OLD_PATH=$PATH
  setup_bb
  # Temporarily block out all custom recovery binaries/libs
  mv /sbin /sbin_tmp
  # Unset library paths
  OLD_LD_LIB=$LD_LIBRARY_PATH
  OLD_LD_PRE=$LD_PRELOAD
  unset LD_LIBRARY_PATH
  unset LD_PRELOAD
}

recovery_cleanup() {
  mv /sbin_tmp /sbin 2>/dev/null
  [ -z $OLD_PATH ] || export PATH=$OLD_PATH
  [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB
  [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE
  ui_print "- Unmounting partitions"
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
  umount -l /dev/random 2>/dev/null
}

unmount_partitions() {
  [ "$supersuimg" -o -d /su ] && umount /su 2>/dev/null
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
}

abort() {
  ui_print "$1"
  unmount_partitions
  exit 1
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

mktouch() {
  mkdir -p ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 > $1
  chmod 644 $1
}

sysover_partitions() {
  if [ -f /system/init.rc ]; then
    ROOT=/system_root
    REALSYS=/system_root/system
  else
    REALSYS=/system
  fi
  if [ -L /system/vendor ]; then
    VEN=/vendor
    REALVEN=/vendor
  else
    VEN=/system/vendor
    REALVEN=$REALSYS/vendor
  fi
}

supersuimg_mount() {
  supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null)
  if [ "$supersuimg" ]; then
    if ! is_mounted /su; then
      ui_print "    Mounting /su..."
      [ -d /su ] || mkdir /su
      mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
      for i in 0 1 2 3 4 5 6 7; do
        is_mounted /su && break
        local loop=/dev/block/loop$i
        mknod $loop b 7 $i
        losetup $loop $supersuimg
        mount -t ext4 -o loop $loop /su 2>/dev/null
      done
    fi
  fi
}

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk $(echo $MINMAGISK | sed -r "s/(.{2})(.{1}).*/v\1.\2+\!/") "
  ui_print "*******************************"
  exit 1
}

require_new_api() {
  ui_print "***********************************"
  ui_print "!   Your system API of $API isn't"
  if [ "$1" == "minimum" ]; then
    ui_print "! higher than the $1 API of $MINAPI"
    ui_print "! Please upgrade to a newer version"
    ui_print "!  of android with at least API $MINAPI"
  else
    ui_print "!   lower than the $1 API of $MAXAPI"
    ui_print "! Please downgrade to an older version"
    ui_print "!    of android with at most API $MAXAPI"
  fi
  ui_print "***********************************"
  exit 1
}

cleanup() {
  if $MAGISK; then
    # UNMOUNT MAGISK IMAGE AND SHRINK IF POSSIBLE
    unmount_magisk_img
    $BOOTMODE || recovery_cleanup
    rm -rf $TMPDIR
    # PLEASE LEAVE THIS MESSAGE IN YOUR FLASHABLE ZIP FOR CREDITS :)
    ui_print " "
    ui_print "    *******************************************"
    ui_print "    *      Powered by Magisk (@topjohnwu)     *"
    ui_print "    *******************************************"
  else
    ui_print "   Unmounting partitions..."
    unmount_partitions
    rm -rf $TMPDIR
  fi
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *    Unity by ahrion & zackptg5 @ XDA     *"
  ui_print "    *******************************************"
  ui_print " "
  exit 0
}

device_check() {
  if [ "$(grep_prop ro.product.device)" == "$1" ] || [ "$(grep_prop ro.build.product)" == "$1" ]; then
    return 0
  else
    return 1
  fi
}

check_bak() {
  case $1 in
    /system/*|/vendor/*) BAK=true;;
    $MOUNTPATH/*|/sbin/.core/img/*|$RAMDISK*) BAK=false;;
    *) BAK=true;;
  esac
  if ! $MAGISK || $SYSOVERRIDE; then BAK=true; fi
  $BAK && return 0
  return 1
}

cp_ch_nb() {
  if [ -z $4 ]; then check_bak $2; else BAK=$4; fi
  if $BAK && [ ! "$(grep "$2$" $INFO)" ]; then echo "$2" >> $INFO; fi
  mkdir -p "$(dirname $2)"
  cp -af "$1" "$2"
  if [ -z $3 ]; then
    chmod 0644 "$2"
  else
    chmod $3 "$2"
  fi
  case $2 in
    */vendor/etc/*) chcon u:object_r:vendor_configs_file:s0 $2;;
    */vendor/*.apk) chcon u:object_r:vendor_app_file:s0 $2;;
    */vendor/*) chcon u:object_r:vendor_file:s0 $2;;
    */system/*) chcon u:object_r:system_file:s0 $2;;
  esac
}

cp_ch() {
  check_bak $2
  if [ -f "$2" ] && [ ! -f "$2.bak" ] && $BAK; then
    cp -af $2 $2.bak
    echo "$2.bak" >> $INFO
  fi
  if [ -z $3 ]; then cp_ch_nb $1 $2 0644 $BAK; else cp_ch_nb $1 $2 $3 $BAK; fi
}

install_script() {
  if $MAGISK; then
    cp_ch_nb $1 $MODPATH/$(basename $1)
    patch_script $MODPATH/$(basename $1)
  else
    cp_ch_nb $1 $MODPATH/$MODID-$(basename $1 | sed 's/.sh$//')$2 0700
    patch_script $MODPATH/$MODID-$(basename $1 | sed 's/.sh$//')$2
  fi
}

patch_script() {
  sed -i "s|<MAGISK>|$MAGISK|" $1
  sed -i "s|<LIBDIR>|$LIBDIR|" $1
  sed -i "s|<SYSOVERRIDE>|$SYSOVERRIDE|" $1
  sed -i "s|<MODID>|$MODID|" $1
  if $MAGISK; then
    if $SYSOVERRIDE; then
      sed -i "s|<INFO>|$INFO|" $1
      sed -i "s|<VEN>|$REALVEN|" $1
    else
      sed -i "s|<VEN>|$VEN|" $1
    fi
    sed -i "s|<ROOT>|\"\"|" $1
    sed -i "s|<SYS>|/system|" $1
    sed -i "s|<SHEBANG>|#!/system/bin/sh|" $1
    sed -i "s|<SEINJECT>|magiskpolicy|" $1
    sed -i "s|\$MOUNTPATH|/sbin/.core/img|g" $1
  else
    if [ ! -z $ROOT ]; then sed -i "s|<ROOT>|$ROOT|" $1; else sed -i "s|<ROOT>|\"\"|" $1; fi
    sed -i "s|<SYS>|$REALSYS|" $1
    sed -i "s|<VEN>|$REALVEN|" $1
    sed -i "s|<SHEBANG>|$SHEBANG|" $1
    sed -i "s|<SEINJECT>|$SEINJECT|" $1
    sed -i "s|\$MOUNTPATH||g" $1
  fi
}

prop_process() {
  sed -i "/^#/d" $1
  if $MAGISK; then
    [ -f $PROP ] || mktouch $PROP
  else
    [ -f $PROP ] || mktouch $PROP "$SHEBANG"
    sed -ri "s|^(.*)=(.*)|setprop \1 \2|g" $1
  fi
  while read LINE; do
    echo "$LINE" >> $PROP
  done < $1
  $MAGISK || chmod 0700 $PROP
}

remove_old_aml() {
  ui_print " "
  ui_print "   ! Old AML Detected! Removing..."
  if $MAGISK; then
    local MODS=$(grep "^fi #.*" $(dirname $OLD_AML_VER)/post-fs-data.sh | sed "s/fi #//g")
    if $BOOTMODE; then local DIR=/sbin/.core/img; else local DIR=$MOUNTPATH; fi
  else
    local MODS=$(sed -n "/^# MOD PATCHES/,/^$/p" $MODPATH/audmodlib-post-fs-data | sed -e "/^# MOD PATCHES/d" -e "/^$/d" -e "s/^#//g")
    if [ -d /system/addon.d ]; then local DIR=/system/addon.d; else local DIR=/system/etc; fi
  fi
  for MOD in ${MODS} audmodlib; do
    if $MAGISK; then local FILE=$DIR/$MOD/$MOD-files; else local FILE=$DIR/$MOD-files; fi
    if [ -f $FILE ]; then
      while read LINE; do
        if [ -f "$LINE.bak" ]; then
          mv -f "$LINE.bak" "$LINE"
        elif [ -f "$LINE.tar" ]; then
          tar -xf "$LINE.tar" -C "${LINE%/*}"
        else
          rm -f "$LINE"
        fi
        if [ ! "$(ls -A "${LINE%/*}")" ]; then
          rm -rf ${LINE%/*}
        fi
      done < $FILE
      rm -f $FILE
    fi
    if $MAGISK; then rm -rf $MOUNTPATH/$MOD /sbin/.core/img/$MOD; else rm -f /system/addon.d/$MODID.sh; fi
  done
}

ramdisk_mod() {
  # BOOTSIGNER="/system/bin/dalvikvm -Xnodex2oat -Xnoimage-dex2oat -cp \$INSTALLER/common/unityfiles/magisk.apk com.topjohnwu.magisk.utils.BootSigner"
  BINDIR=$INSTALLER/common/unityfiles/$ARCH32
  AVB=$INSTALLER/common/unityfiles/avb
  RAMDISK=$INSTALLER/common/unityfiles/tmp/ramdisk
  BOOTSIGNER="/system/bin/dalvikvm -Xbootclasspath:/system/framework/core-oj.jar:/system/framework/core-libart.jar:/system/framework/conscrypt.jar:/system/framework/bouncycastle.jar -Xnodex2oat -Xnoimage-dex2oat -cp $AVB/BootSignature_Android.jar com.android.verity.BootSignature"
  local DIR
  BOOTSIGNED=false; KEEPVERITY=false; KEEPFORCEENCRYPT=false; HIGHCOMP=false; CHROMEOS=false; DIR=$(pwd)

  mkdir $INSTALLER/common/unityfiles/tmp
  cp -af $BINDIR/. $CHROMEDIR $TMPDIR/bin/busybox $INSTALLER/common/unityfiles/tmp
  chmod -R 755 $INSTALLER/common/unityfiles/tmp
  cd $INSTALLER/common/unityfiles/tmp

  find_boot_image
  [ -z $BOOTIMAGE ] && abort "! Unable to detect target image"
  ui_print "- Target image: $BOOTIMAGE"

  # eval $BOOTSIGNER -verify < $BOOTIMAGE && BOOTSIGNED=true
  eval $BOOTSIGNER -verify $BOOTIMAGE 2>&1 | grep "VALID" && BOOTSIGNED=true
  $BOOTSIGNED && ui_print "- Boot image is signed with AVB 1.0"

  cd $BINDIR
  ./magiskinit -x magisk magisk
  ui_print "- Unpacking boot image"
  ./magiskboot --unpack "$BOOTIMAGE"
  case $? in
    1 ) abort "! Unable to unpack boot image";;
    2 ) HIGHCOMP=true;;
    3 ) ui_print "- ChromeOS boot image detected"; CHROMEOS=true;;
    4 ) ui_print "! Sony ELF32 format detected"; abort "! Please use BootBridge from @AdrianDC to flash this mod";;
    5 ) ui_print "! Sony ELF64 format detected" abort "! Stock kernel cannot be patched, please use a custom kernel";;
  esac
  ui_print "- Checking ramdisk status"
  ./magiskboot --cpio ramdisk.cpio test
  if [ $? -eq 2 ]; then
    HIGHCOMP=true
    ui_print "! Insufficient boot partition size detected"
    ui_print "- Enable high compression mode"
  fi
  ui_print "- Patching ramdisk"
  mkdir ramdisk
  cd ramdisk
  cp -af ../magiskboot magiskboot
  ./magiskboot --cpio ../ramdisk.cpio "extract"
  rm -f magiskboot
  # User ramdisk patches
  case $1 in
    1) . $INSTALLER/common/ramdiskinstall.sh
       [ "$(ls $INSTALLER/ramdisk)" ] && cp_ch_nb $INSTALLER/ramdisk/* $RAMDISK false;;
    2) . $INSTALLER/common/ramdiskuninstall.sh;;
  esac
  ui_print "- Repacking ramdisk"
  find . | cpio -H newc -o > ../ramdisk.cpio
  cd ..
  ui_print "- Repacking boot image"
  ./magiskboot --repack "$BOOTIMAGE" || abort "! Unable to repack boot image!"
  # Sign chromeos boot
  $CHROMEOS && sign_chromeos
  ./magiskboot --cleanup

  flash_boot_image new-boot.img "$BOOTIMAGE"
  rm -f new-boot.img

  cd $DIR
}
