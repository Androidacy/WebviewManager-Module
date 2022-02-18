
# Changelog

### 10.0...10.4.1

- Support new bromite package name
- Serious refactoring
- Remove all offline-only install logic
- Improve security
- Switch to cURL and fix issues
- Support AndroidacyAPI v5
### 9.1

- Remove recovery install completely. It's been broken for awhile now anyway.
- Properly respect FORCE_CONFIG
- API updates

### 9.0

- Add volume key selection for options
- Improve security
- Switch to new backend
- Misc fixes

### 8.1.4

- Fix debloats
- Implement browser signature verification

### 8.1.3

- Address situation where, especially on android 10+, internal storage isn't accessible
- Bugfixes and performance improvements
- Code formatting

### 8.1.0

- Address download error
- Cleanup sepolicy; implement proper install solution
- Properly support MIUI and Android 11
- Move away from github and move some download logic server side.
- Fix vanilla chromium download

### 8.0.2

- Fix files not getting downloaded to the right location for some users
- Fix ungoogled chromium extensions download

### 8.0.1

- Huge refactor
- Support android 11
- Change default back to only installing bromite webview.
  - Make sure to edit config.txt appropriately, and place in /sdcard/WebviewManager
- Code optimization
- Add support for extensions version of ungoogled-chromium
- Seperate browser and webview choice
- Remove most checks in offline mode
- Add better error handling
- Fix some events don't properly trigger an install abort

### 7.3.0

- Misc code refactoring

### 7.1.1

- Fix several critical bugs in the 7.x release

- Try to fix offline install

- Misc refactoring

### 7.0.1

- Rebrand the module to reflect new abilities

- Add support for bundling browser

- Add ungoogled chromium and vanilla chromium

- Massive code refactoring

- Switch to Magisk's internal BusyBox

- Use aria2 for faster downloads

- Fix broken version check

- Add verification for WebView apk

- Other optimizations

### 6.1.0

- Support recovery and system installs - system installs are experimental and I will NOT provide support for them

- Update used tools

- Hopefully fix "no connection" issues for some users

### 6.0.0

- Rework overlay to prevent some boot loop

- Separate overlays for Android 10 and < 10

- Fix overlay flag on Android < 9

- Verify downloads for security

- Prepare for bromite upstream changes

- Extract libraries from all, meaning even if install fails no crashing should occur

### 5.0.1

- Switch to MMT-ex template

- Major code refactoring

- Better support Android 10

- Update bundled overlay

- Add backup for overlays.xml just in case

- Misc bugfixes & improvements

### 4.4.3

- Hopefully last release 4.x series

- Misc bugfixes

  - Fixes for API < 28

  - Boot script updates
  
- Reworked logging (thanks @JohnFawkes)

- Updated sepolicy

### 4.4.1

- Introduce better logging

- Start using sepolicy.rule instead of going permissive

- Move sepolicy dependent commands to boot scripts

- Fix said boot scripts - for real this time

- Full android 10 support

- Prevent overlay install on custom ROMs

- This will be the last release using Unity. 5.0 will use MMT-ex, meaning ONLY magisk will be supported

### 4.3.0

- Misc fixes

### 4.2.2

- Fixed overlay not copying to the right place

- Update unity

- Remove some debugging code

### 4.2.0

- Fixes for overlay on custom ROMs

- Uninstall script fixes

- Code cleaned up and refactored

- Update to latest unity

- Support offline installs

- Whenever upstream bromite adds support Android 10 will work

- Support new module format

- Misc. bugfixes

### 4.1.0

- Fixes for app installation on boot

- More dynamic in boot script should no longer mess with manual app updates

### 4.0.0

- Fixed compatibility with stock ROMs

- Migration to unity template

- Updated boot scripts

### 3.7.3

- Always download latest Bromite WebView apk

### 3.7.2

- Download APK from official sources

- Update replace logic

- Update install logic

### 3.6.2

- Updated bromite to 75.0.3770.132

- Fixed boot script (I say that a lot...)

### 3.6.1

- Improve install logic

- Improve replace logic

- Fix boot script (hopefully)

- First steps towards Pixel/stock compatibility

- Re-add 64 bit curl binary

### 3.5.1

- Hotfix for multiple modules. All because of a comment in the code BTW

- Hotfix for Chrome removal, wasn't received well

### 3.5

- Attempt to fix support on Pixels and Pixel ROMs

- `reverted`

- Script cleanup

### 3.4

- `reverted`

### 3.3

- Further fix webview recognition on reboot

### 3.2

- Add uninstall script to fixed issues with no webview on uninstall

### v3.1

- Bugfixes, probably added more bugs

### v3.0

- Now fetches needed files from internet to reduce filesize

- Fix installer script

- Fix boot script

### v2.1.1

- Fix boot script

### v2.0

- Unbreak the module

### v1.5

- Fix script

### v1.4

- Add support for more CPU arch besides arm64

- Update bromite to v75

### v1.3

- Misc bugfixes

### v1.2

- Updated libs

### v1.1

- Fix WebView crash

### v1.0

- Initial release
