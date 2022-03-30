#!/bin/bash
chmod -R 0755 "$MODPATH/common/addon/Volume-Key-Selector/tools"

chooseport_legacy() {
  # Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
  # Calling it first time detects previous input. Calling it second time will do what we want
  if test -n "$1"; then
    local delay=$1
  else
    local delay=3
  fi
  local error=false
  while true; do
    timeout 0 "$MODPATH/common/addon/Volume-Key-Selector/tools/$ARCH32/keycheck"
    timeout $delay "$MODPATH/common/addon/Volume-Key-Selector/tools/$ARCH32/keycheck"
    local sel=$?
    if [ $sel -eq 42 ]; then
      return 0
    elif [ $sel -eq 41 ]; then
      return 1
    elif $error; then
      echo "Volume key not detected! Falling back to config handler..."
      export KEYCHECK_FAIL='true'
    else
      error=true
      echo "Volume key not detected. Try again"
    fi
  done
}

chooseport() {
  # Original idea by chainfire and ianmacd @xda-developers
  if test -n "$1"; then
    local delay=$1
  else
    local delay=3
  fi
  local error=false 
  while true; do
    local count=0
    while true; do
      # shellcheck disable=SC2069
      timeout $delay /system/bin/getevent -lqc 1 2>&1 > "$TMPDIR/events" &
      sleep 1; count=$((count + 1))
      if (eval "$(grep -q 'KEY_VOLUMEUP *DOWN' "$TMPDIR"/events)"); then
        return 0
      elif (eval "$(grep -q 'KEY_VOLUMEDOWN *DOWN' "$TMPDIR"/events)"); then
        return 1
      fi
      [ $count -gt 3 ] && break
    done
    if $error; then
      # abort "Volume key not detected!"
      echo "Volume key not detected. Trying legacy method"
      export chooseport=chooseport_legacy VKSEL=chooseport_legacy
      chooseport_legacy $delay
      return $?
    else
      error=true
      echo "Volume key not detected. Try again"
    fi
  done
}

# Keep old variable from previous versions of this
VKSEL=chooseport
