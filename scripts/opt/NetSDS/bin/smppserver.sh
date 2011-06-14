#!/bin/sh

#SERVPIDFILE=/var/run/NetSDS/smppserver.pid

while :; do
    cd /opt/NetSDS/bin
    ./smppserver —daemon 
    sleep 1
done
