#!/bin/sh
{
./radiokill.sh ; sleep 1 ; mplayer -ao alsa $1 > /dev/null 2>&1
} &
