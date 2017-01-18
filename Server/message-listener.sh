#
# message-listener.sh -- shell script to start web listener
#
# 2016-01-17 Steven Wart created this file
#

echo "WEBROOT_PATH is ${WEBROOT_PATH}" > $HOME/whereami.txt
node $WEBROOT_PATH/scripts/message-listener.js
