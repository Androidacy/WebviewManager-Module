<h2>Bromite Systemless Webview</h2>


This module allows you to install Bromite systemlessly. With Bromite, you can block ads and trackers and resist fingerprinting

I didn't develop the app itself; all credit goes to the devs at bromite.org

This module probably won't be updated with each Bromite update but I will try to keep it updated at least with major versions

Donation to the app creators is found at bromite.org. Donation to me is [here](https://paypal.me/innonetlife)

Any issues with Bromite itself should be filed with the Bromite team [here](https://github.com/bromite/bromite/issues)

Issues with the module are filed [here](https://github.com/alexa-v2/magisk-module-installer/issues)

**NEW:** Our telegram support group is at https://t.me/inlmagisk

Credit to @topjohnwu for magisk and the magisk installer template.

**Please note** your ROM must support using "com.android.webview" as the webview and not have a pinned signature for the app.

To see if it does:

From a terminal such as termux:

- cp /system/framework/framework-res.apk ~

- aapt d xmltree framework-res.apk res/xml/config_webview_packages.xml

The output should contain. "com.android.webview" and not contain a "E:" with a bunch of characters under that.

<h3>Changelog:</h3>

**v2.1**

- Fix boot script

**v2.0**

- Unbreak the module

**v1.5**

- Fix script

**v1.4**

- Add support for more CPU arch

- Update bromite to v75

**v1.3**

- Misc bugfixes

**v1.2**

- Updated libs

**v1.1**

- Fix WebView crash

**v1.0**

- Initial release
