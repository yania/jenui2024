#!/bin/bash

echo
echo "Script: $@"
echo

team=$( awk 'BEGIN{ FS=","; } { cad = $24; gsub("\"", "", cad); ll = length(cad); print "g" substr(cad,ll-1); }' <<<"$@" )

echo Team: $team

/home/tablon/client -q contest -u $team -x "ER_%xp4v?l" /home/tablon/analizer.sonarqube $@

