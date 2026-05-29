#!/bin/sh
#{
sudo killall -e webserver > /dev/null 2>&1
sudo rm /tmp/webserver.log
./webserver > /tmp/webserver.log 2>&1 &
#} &
