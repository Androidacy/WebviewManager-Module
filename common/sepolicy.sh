# Do not concatenate classes 
# Only concatenate permissions (the last argument in the statement)
# NOT valid example: audioserver { audioserver_tmpfs mediaserver_tmpfs } file read
#
# Valid entry example: audioserver audioserver_tmpfs file read
# Another valid example: audioserver audioserver_tmpfs file read,write,execute
