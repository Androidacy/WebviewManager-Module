# Aroma Installer

# Backup selections to temp directory
for FILE in $UNITY$SYS/etc/$MODID/*.prop; do
  [ -f "$FILE" ] && cp_ch -i $FILE $TMPDIR/aroma/$(basename $FILE)
done
