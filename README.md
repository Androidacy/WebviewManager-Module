# Unity (Un)Installer Template
Unity Installer allows 1 zip to work for multiple devices and root solutions. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-audio-modification-library-t3579612).

## Compatibility
* Android Jellybean+
* Selinux enforcing
* All root solutions (requires init.d support if not using magisk or supersu. Try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))

## Change Log
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
