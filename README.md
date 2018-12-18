# Unity (Un)Installer Template
Unity Installer allows 1 zip to work for multiple devices and root solutions. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-audio-modification-library-t3579612).

## Compatibility
* Android Lollipop+
* Selinux enforcing
* All root solutions (requires init.d support for boot scripts if not using magisk or supersu. Try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))

## Change Log
### v2.0 12.18.2019
* Added back backwards compatibility to magisk 15.3 like before
* Fix script install paths
* Made sepolicy more dynamic - supports quoted or unquoted statements now
* Entire installer now runs in bash shell - no more workarounds for shitty shell
* Cleaned up code

### v1.8.2 12.10.2018
* Fixed boot img mounting but on uninstall

### v1.8.1 12.9.2018
* Got rid of sepolicy-inject support (init.d injector uses magiskpolicy now)
* Above means that all sepolicy statements should be crafted like the typical magisk/superu one - see support thread for usage

### v1.8 - 12.8.2018
* Fixed bugs, reorganized some stuff
* Updated ramdisk logic for newer magiskboot
* Added new option: sepolicy. It's now separate from the boot scripts and syntax is different (and easier). See support thread for usage
* Added option to patch sepolicy in ramdisk directly with systems that lack magisk/supersu boot script support
* Updated for magisk v18, removed backwards compatibilities
* Fixed limitation in zipname triggers - you can use spaces in the zipname now and trigger is case insensitive

### v1.7.2 - 10.23.2018
* Fix dynamicoreo for lib64
* Update magisk binaries to 17.3 for pixel 3 support
* Fix bug with ramdisk uninstall

### v1.7.1 - 9.20.2018
* Fix bug with ramdisk file copying

### v1.7 - 9.2.2018
* Updated to new magisk module template - only compatible with magisk 17 and newer now
* Fix old BOOTMODE bug - rework busybox logic
* Fix bug in install_scripts function with bootmode

### v1.6.1 - 8.30.2018
* Fix/improve cp_ch functions. Combine cp_ch, cp_ch_nb, and check_bak into cp_ch function - see OP on xda for how it works
* Improve how unity handles ramdisk stuff
* Modify install_script function so it can be used by devs - see OP on xda for details
* Need busybox for ramdisk stuff - note that since busybox is now bundled into unity, you can use it with any of your mods (it replaces sbin in path like magisk does so you can call it like any binary)
* Compress unity tools to save space (cut size in ~half)
* Fix debug in magisk manager
* Misc bug fixes and improvements

### v1.6 - 8.24.2018
* Added debug flag (set debug to true in config.sh or add debug to zipname)
* Added ramdisk patching capability - limited usage, most people won't need this

### v1.5.5 - 7.17.2018
* Fix propfile removal on system uninstalls
* Update functions with magisk 16.6 stuff
* Use local variables in some unity functions

### v1.5.4 - 5.7.2018
* Added support for init.d injector late_start and post-fs-data method

### v1.5.3 - 4.26.2018
* Fixed/overhauled SYSOVERRIDE
* Fixes/improvements with system installs

### v1.5.2 - 4.16.2018
* Removed ALWAYSRW

### v1.5.1 - 4.12.2018
* Fixes for file copying

### v1.5 - 4.12.2018
* Add DYNAMICAPP option
* Add SYSOVERRIDE option
* Add ALWAYSRW option
* Rework some of the copy logic

### v1.4.1 - 3.29.2018
* Don't use dynamic oreo for system kernel modules
* Fix prop file permissions for system installs

### v1.4 - 3.18.2018
* Remove redundant code
* Don't use install binary anymore since it's weird on some devices
* Install apps to priv-app if /vendor/app folder doesn't exist
* Misc improvements

### v1.3 - 2.25.2018
* Fix seg faults on system installs

### v1.2 - 2.16.2018
* Fine tune prop logic
* Update util_functions with magisk 15.4 stuff

### v1.1 - 2.7.2018
* Bootmode fixes

### v1.0 - 2.5.2018
* Initial release

## Source Code
* Module [GitHub](https://github.com/Zackptg5/Unity)
