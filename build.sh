#!/bin/sh
NAME=webserver
rm $NAME > /dev/null 2>&1
echo -- building $NAME
crystal build $NAME.cr
echo -- build done
