#!/bin/bash

# Show vlans
# Fabio Rodrigues (anfabio@gmail.com)
# Version 1.0

#$vlans = `/sbin/ip addr | grep inet | egrep -v \"inet6|127\.0\.0\.1|eth0\"`
readarray vlans < <(/sbin/ip addr | grep inet | egrep -v "inet6|127\.0\.0\.1|eth0" | sort -t' ' -k11.5n)
#(IFS=$'\n'; echo "${vlans[*]}")

        echo "VLAN-ID NAME IP-ADDRESS" | xargs -n3 printf "%-12s%-12s%s\n"
	echo "======= ========== =============" | xargs -n3 printf "%-12s%-12s%s\n"

for i in "${vlans[@]}"
	do
	ip=`echo $i | awk {'print $2'} |cut -d/ -f1`
	vlan=`echo $i | awk {'print $7'}`
	vlan_name=`cat /home/afrs/Documents/vlans.txt |grep ^$vlan |awk {'print $2'}`

	echo "$vlan $vlan_name $ip" | xargs -n3 printf "%-12s%-12s%s\n"
#	echo "$vlan	$vlan_name		$ip"


done
exit 0
