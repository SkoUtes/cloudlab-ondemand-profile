#!/bin/bash

sleep 20

while :
do
	sleep 2
	if tail /local/logs/install.log | grep -q -E -o '(Cleanup\s{4}:\s{1}libgcc-4.8.5-39.el7'; then
		break
	else
		:
	fi
done
sleep 10
export yum_ps=$(ps aux|grep "/bin/yum update -y"|cut -c -15 |grep -E -o '[0-9]{3,5}')
kill -9 $yum_ps