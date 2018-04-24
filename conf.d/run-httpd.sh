#!/bin/bash

DIR="/var/www/html"

# Check if /var/www/html empty or not
if [ "$(ls -A $DIR)" ]; then
     echo "Enjoy your RackTables ...!"
else
    echo "Copy RackTables source to webroot ...!"
    cp -r /usr/src/RackTables*/wwwroot/* $DIR/
    chmod 755 $DIR
    touch $DIR/inc/secret.php && chmod 666 $DIR/inc/secret.php
    chown -R apache:apache $DIR
fi

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

exec /usr/sbin/apachectl -DFOREGROUND
