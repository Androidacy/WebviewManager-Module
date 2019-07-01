# Bromite Systemless Webview
	
	FOR ANY PROBLEMS WITH INSTALLATION SHOULD BE REPORTED WITH LOGS AT OUR TELEGRAM GROUP BELOW
	
This module allows you to install [Bromite SystemWebView](https://www.bromite.org/system_web_view) systemless-ly.
Most useful features of Bromite are that you can block ads, trackers and resist fingerprinting; see the full features list at https://github.com/bromite/bromite/blob/master/README.md#features

The numbers after the dash in the version are the Bromite version used.

## What is a WebView?

A WebView is like a minimal browser, but for non-browsers that display web content in any other way than sending you to a browser or custom tab, like Outlook or GoDaddy apps or even some banking apps.

**PLEASE NOTE SOME APPS WON'T WORK WITHOUT GOOGLE WEBVIEW**. I can't fix that and any issues on it will be closed and ignored.

## Credits

Bromite itself is created by and copyright of the developers of the [Bromite project](https://github.com/bromite/bromite) (of which I'm currently unassociated with).

Thanks to @alexiacortez (me) for the module

Thanks to @neekless for parts of the installer script

And double thanks to Innonetlife for funding us and providing server usage

## ETAs

This module probably will not be updated with each Bromite release but I will try to keep it updated at least with major versions.

## Donations

Donations for Bromite: https://www.bromite.org/#donate 

Donations for me: [here](https://paypal.me/innonetlife)

## Support

Any issues with Bromite itself should be filed in the [Bromite issue tracker](https://github.com/bromite/bromite/issues).

Issues with the module should be filed [here](https://github.com/alexa-v2/magisk-module-installer/issues).

**NEW:** Our XDA thread is [here](https://forum.xda-developers.com/android/software/bromite-magisk-module-t3936964)

**NEW:** Our telegram support group is at https://t.me/inlmagisk

Credit to @topjohnwu for magisk and the magisk installer template.

## Compatibility

- Android 5 or higher
- Magisk v18.2+
- **ONLY FLASH THROUGH MAGISK MANAGER AS IT REQUIRES AN INTERNET CONNECTION**

**Please note** your ROM must support using `com.android.webview` as the WebView and not have a pinned signature for the app.

To see if it does:

From termux, under a non root ($) shell:

- cp /system/framework/framework-res.apk ~

- aapt d xmltree framework-res.apk res/xml/config_webview_packages.xml

The output should contain. `com.android.webview` and not contain a "E:" with a bunch of characters under that.

## Other resources

* [Bromite SystemWebView wiki page](https://github.com/bromite/bromite/wiki/Installing-SystemWebView)

# Changelog

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
