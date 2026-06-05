#!/bin/sh
echo ---stopping webradio---
sudo killall -e firefox > /dev/null 2>&1
sudo killall -e webserver > /dev/null 2>&1
./radiokill.sh
echo ---starting webserver---
./webserver &
sleep 1
echo ---starting browser---
firefox http://192.168.4.140:8080 > /dev/null 2>&1
echo ---stopping webradio---
sudo killall -e webserver > /dev/null 2>&1
./radiokill.sh
echo ---webradio stopped---
