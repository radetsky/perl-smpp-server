#!/bin/sh

#SERVPIDFILE=/var/run/NetSDS/smppserver.pid

while :; do
    /usr/sbin/smppserver --daemon --conf=/etc/NetSDS/smppserver.conf
    sleep 1
done
