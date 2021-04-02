#!/bin/bash

sleep 20

while :
do
	sleep 2
	if [[ tail /local/logs/install.log ]]; then
		break
	fi
done
ps aux|grep yum update|cut -c -25 |grep -E -o '[0-9]{3,5}'