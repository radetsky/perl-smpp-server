#!/bin/sh

while true; do kill -ALRM `cat /var/run/NetSDS/smppserver.pid`; sleep 5; done

