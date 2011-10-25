#!/bin/sh

#SERVPIDFILE=/var/run/NetSDS/smppserver.pid

while :; do
    /usr/sbin/smppserver2 --daemon --conf=/etc/NetSDS/smppserver2.conf
    sleep 1
done
