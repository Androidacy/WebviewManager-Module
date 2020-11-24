
# Changelog

<h4>7.0.0</h4>

**CURRENTLY IN BETA**

- Rebrand the module to reflect new abilities

- Add support for bundling browser

- Add ungoogled chromium and vanilla chromium

- Massive code refactoring

- Switch to Magisk's internal BusyBox

- Use aria2 for faster downloads

- Fix broken version check

- Add verification for WebView apk

<h4>6.1.0</h4>

- Support recovery and system installs - system installs are experimental and I will NOT provide support for them

- Update used tools

- Hopefully fix "no connection" issues for some users

<h4>6.0.0</h4>

- Rework overlay to prevent some boot loop

- Separate overlays for Android 10 and < 10

- Fix overlay flag on Android < 9

- Verify downloads for security

- Prepare for bromite upstream changes

- Extract libraries from all, meaning even if install fails no crashing should occur

<h4>5.0.1</h4>

- Switch to MMT-ex template

- Major code refactoring

- Better support Android 10

- Update bundled overlay

- Add backup for overlays.xml just in case

- Misc bugfixes & improvements

<h4>4.4.3</h4>

- Hopefully last release 4.x series

- Misc bugfixes

  - Fixes for API < 28

  - Boot script updates
  
- Reworked logging (thanks @JohnFawkes)

- Updated sepolicy

<h4>4.4.1</h4>

- Introduce better logging

- Start using sepolicy.rule instead of going permissive

- Move sepolicy dependent commands to boot scripts

- Fix said boot scripts - for real this time

- Full android 10 support

- Prevent overlay install on custom ROMs

- This will be the last release using Unity. 5.0 will use MMT-ex, meaning ONLY magisk will be supported

<h4>4.3.0</h4>

- Misc fixes

<h4>4.2.2</h4>

- Fixed overlay not copying to the right place

- Update unity

- Remove some debugging code

<h4>4.2.0</h4>

- Fixes for overlay on custom ROMs

- Uninstall script fixes

- Code cleaned up and refactored

- Update to latest unity

- Support offline installs

- Whenever upstream bromite adds support Android 10 will work

- Support new module format

- Misc. bugfixes

<h4>4.1.0</h4>

- Fixes for app installation on boot

- More dynamic in boot script should no longer mess with manual app updates

<h4>4.0.0</h4>

- Fixed compatibility with stock ROMs

- Migration to unity template

- Updated boot scripts

<h4>3.7.3</h4>

- Always download latest Bromite WebView apk

<h4>3.7.2</h4>

- Download APK from official sources

- Update replace logic

- Update install logic

<h4>3.6.2</h4>

- Updated bromite to 75.0.3770.132

- Fixed boot script (I say that a lot...)

<h4>3.6.1</h4>

- Improve install logic

- Improve replace logic

- Fix boot script (hopefully)

- First steps towards Pixel/stock compatibility

- Re-add 64 bit curl binary

<h4>3.5.1</h4>

- Hotfix for multiple modules. All because of a comment in the code BTW

- Hotfix for Chrome removal, wasn't received well

<h4>3.5</h4>

- Attempt to fix support on Pixels and Pixel ROMs

- `reverted`

- Script cleanup

<h4>3.4</h4>

- `reverted`

<h4>3.3</h4>

- Further fix webview recognition on reboot

<h4>3.2</h4>

- Add uninstall script to fixed issues with no webview on uninstall

<h4>v3.1</h4>

- Bugfixes, probably added more bugs

<h4>v3.0 - big changes</h4>

- Now fetches needed files from internet to reduce filesize

- Fix installer script

- Fix boot script

<h4>v2.1.1</h4>

- Fix boot script

<h4>v2.0</h4>

- Unbreak the module

<h4>v1.5</h4>

- Fix script

<h4>v1.4</h4>

- Add support for more CPU arch besides arm64

- Update bromite to v75

<h4>v1.3</h4>

- Misc bugfixes

<h4>v1.2</h4>

- Updated libs

<h4>v1.1</h4>

- Fix WebView crash

<h4>v1.0</h4>

- Initial release
