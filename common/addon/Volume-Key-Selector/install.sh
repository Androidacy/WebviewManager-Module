# shellcheck shell=dash
# External Tools
chmod -R 0755 "$MODPATH"/common/addon/Volume-Key-Selector/tools
alias keycheck="$MODPATH"/common/addon/Volume-Key-Selector/tools/"$ARCH"/keycheck

chooseport_legacy() {
  # Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
  # Calling it first time detects previous input. Calling it second time will do what we want
  if [ -n "$1" ]; then
    local delay=$1
  else
    local delay=5
  fi
  local error=false
  while true; do
    timeout 0 keycheck
    timeout "$delay" keycheck
    local sel=$?
    if [ $sel -eq 42 ]; then
      return 0
    elif [ $sel -eq 41 ]; then
      return 1
    elif $error; then
      abort "Volume key not detected!"
    else
      error=true
      echo "Volume key not detected. Try again"
    fi
  done
}

chooseport() {
  if [ -n "$1" ]; then
    local delay=$1
  else
    local delay=5
  fi
  local error=false 
  while true; do
    local count=0
    while true; do
      if [ ! -d "$TMPDIR" ]; then
        mkdir -p "$TMPDIR"
      fi
      if [ -f "$TMPDIR"/events ]; then
        rm -f "$TMPDIR"/events
      fi
      timeout "$delay" /system/bin/getevent -lqc 1 > "$TMPDIR"/events 2>&1
      count=$((count + 1))
      if grep -q "KEY_VOLUMEUP *DOWN" "$TMPDIR"/events; then
        return 0
      elif grep -q "KEY_VOLUMEDOWN *DOWN" "$TMPDIR"/events; then
        return 1
      fi
      [ $count -gt 3 ] && break
    done
    if $error; then
      # abort "Volume key not detected!"
      echo "Volume key not detected. Trying keycheck method"
      export chooseport=chooseport_legacy VKSEL=chooseport_legacy
      chooseport_legacy "$delay"
      return $?
    else
      error=true
      echo "Volume key not detected. Try again"
    fi
  done
}
if [ ! -d "$TMPDIR" ]; then
  mkdir -p "$TMPDIR"
fi
echo "" > "$TMPDIR"/events
# Keep old variable from previous versions of this
VKSEL=chooseport