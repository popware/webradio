#!/bin/sh
echo -- deploying
sudo killall -e webserver
sudo cp r*.sh /usr/local/bin
sudo cp v*.sh /usr/local/bin
echo -- deploy done
