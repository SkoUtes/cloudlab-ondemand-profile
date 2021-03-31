#!/bin/bash

while
ps aux|grep yum update|cut -c -25 |grep -E -o '[0-9]{3,5}'