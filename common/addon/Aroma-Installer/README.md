# Aroma Installer - Addon where you can make an aroma installer

## Compatibility:
Any device with TWRP that Aroma is compatible with

## Instructions
* Modify the aroma-config and contents of the aroma folder in META-INF/com/google/android for your installer (Don't touch the update-binary/script files) [See Aroma documentation](https://forum.xda-developers.com/showthread.php?t=1461712)
* Replace update-binary with aroma binary of choice (2.70RC2 is included) (don't modify anything else in aroma folder other than theme stuff)
* Add whatever install logic you want to the main unity installer (i.e. common/install.sh)
* If you only want aroma to run in a certain condition, you can add that to the top of the install.sh script in the aroma addon directory (do not modify anything already there)

## Notes for Aroma-config (applicable during aroma zip flashing only):
* All aroma selections will be saved in /tmp/aroma directory during the aroma zip install
* After aroma finishes, those props are moved to /cache/$MODID for main unity installer to use

## Notes for Main Unity installer:
* After the above, unity then creates needed zips and an openrecoveryscript in /cache and reboots into twrp where the script is run
* All aroma selections from /cache/$MODID will be moved to $UNITY/system/etc/$MODID (this is where you want all install logic in your common/install.sh to target)
* To check selections for a prop for example: grep_prop "selected.0" $UNITY/system/etc/$MODID/saved.prop
* During upgrade, prop selections are backed up to /cache/$MODID directory so user can reuse old selections in aroma zip install if you choose to set it up that way

## Credits:
* Aroma Installer [by Amarullz @Github](https://github.com/amarullz/AROMA-Installer)
