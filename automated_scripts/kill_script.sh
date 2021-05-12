#!/bin/bash

sleep 100

digit=$(cat /local/logs/install.log | grep -E -o '\<1/[0-9]{3}' | grep -E -o '[0-9]{3}')

while :
do
	sleep 2
	if tail /local/logs/install.log | grep -q -E -o "Cleanup\s{4}: libgcc-4.8.5-39.el7 \s+ $digit/$digit"; then
		break
	else
		:
	fi
done
sleep 10
export yum_ps=$(ps aux|grep "/bin/yum update -y"|cut -c -15 |grep -E -o '[0-9]{3,5}')
kill -9 $yum_ps