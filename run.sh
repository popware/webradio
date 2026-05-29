#!/bin/sh
echo
echo ---webserver stopping---
ps -AH | grep webserver
sudo killall -e webserver
ps -AH | grep webserver
echo ---webserver stopped---
sleep 2
echo
echo ---webserver started---
./webserver &
sleep 2
ps -AH | grep webserver
echo ---webserver running in background---
echo ---browser started---
firefox http://192.168.4.140:8080 > /dev/null 2>&1
echo ---browser stopped---
