#!/bin/bash
# SCADA Simulator
#
# Copyright 2018 Carnegie Mellon University. All Rights Reserved.
#
# NO WARRANTY. THIS CARNEGIE MELLON UNIVERSITY AND SOFTWARE ENGINEERING INSTITUTE MATERIAL IS FURNISHED ON AN "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY KIND, EITHER EXPRESSED OR IMPLIED, AS TO ANY MATTER INCLUDING, BUT NOT LIMITED TO, WARRANTY OF FITNESS FOR PURPOSE OR MERCHANTABILITY, EXCLUSIVITY, OR RESULTS OBTAINED FROM USE OF THE MATERIAL. CARNEGIE MELLON UNIVERSITY DOES NOT MAKE ANY WARRANTY OF ANY KIND WITH RESPECT TO FREEDOM FROM PATENT, TRADEMARK, OR COPYRIGHT INFRINGEMENT.
#
# Released under a MIT (SEI)-style license, please see license.txt or contact permission@sei.cmu.edu for full terms.
#
# [DISTRIBUTION STATEMENT A] This material has been approved for public release and unlimited distribution.  Please see Copyright notice for non-US Government use and distribution.
# This Software includes and/or makes use of the following Third-Party Software subject to its own license:
# 1. Packery (https://packery.metafizzy.co/license.html) Copyright 2018 metafizzy.
# 2. Bootstrap (https://getbootstrap.com/docs/4.0/about/license/) Copyright 2011-2018  Twitter, Inc. and Bootstrap Authors.
# 3. JIT/Spacetree (https://philogb.github.io/jit/demos.html) Copyright 2013 Sencha Labs.
# 4. html5shiv (https://github.com/aFarkas/html5shiv/blob/master/MIT%20and%20GPL2%20licenses.md) Copyright 2014 Alexander Farkas.
# 5. jquery (https://jquery.org/license/) Copyright 2018 jquery foundation.
# 6. CanvasJS (https://canvasjs.com/license/) Copyright 2018 fenopix.
# 7. Respond.js (https://github.com/scottjehl/Respond/blob/master/LICENSE-MIT) Copyright 2012 Scott Jehl.
# 8. Datatables (https://datatables.net/license/) Copyright 2007 SpryMedia.
# 9. jquery-bridget (https://github.com/desandro/jquery-bridget) Copyright 2018 David DeSandro.
# 10. Draggabilly (https://draggabilly.desandro.com/) Copyright 2018 David DeSandro.
# 11. Business Casual Bootstrap Theme (https://startbootstrap.com/template-overviews/business-casual/) Copyright 2013 Blackrock Digital LLC.
# 12. Glyphicons Fonts (https://www.glyphicons.com/license/) Copyright 2010 - 2018 GLYPHICONS.
# 13. Bootstrap Toggle (http://www.bootstraptoggle.com/) Copyright 2011-2014 Min Hur, The New York Times.
# DM18-1351
#


if [ $(vmtoolsd --cmd 'info-get guestinfo.scada.config') = '1' ]
	then
	vmtoolsd --cmd 'info-set guestinfo.scada.config 0'
	exit

elif [ ! -f /usr/local/bin/config.txt ]
	then
	ip=$(vmtoolsd --cmd 'info-get guestinfo.address')
	mask=$(vmtoolsd --cmd 'info-get guestinfo.netmask')
	gateway=$(vmtoolsd --cmd 'info-get guestinfo.gateway')


	echo -e "" > /etc/sysconfig/network-scripts/ifcfg-ens32

	echo -e "DEVICE=ens32" | tee -a /etc/sysconfig/network-scripts/ifcfg-ens32
	echo -e "ONBOOT=yes" | tee -a /etc/sysconfig/network-scripts/ifcfg-ens32
	echo -e 'IPADDR='$ip | tee -a /etc/sysconfig/network-scripts/ifcfg-ens32
	echo -e 'NETMASK='$mask | tee -a /etc/sysconfig/network-scripts/ifcfg-ens32
	echo -e 'GATEWAY='$gateway | tee -a /etc/sysconfig/network-scripts/ifcfg-ens32

	iface=2
	for i in $(ip -o link show | grep ens | awk -F': ' '{print $2}'); do
		ip link set $i down
		ip link set $i name ens3$iface
		ip link set ens3$iface up
		if [ $iface != 2 ]
			then
			echo -e "" > /etc/sysconfig/network-scripts/ifcfg-ens3$iface
			echo -e "DEVICE=ens3"$iface | tee -a /etc/sysconfig/network-scripts/ifcfg-ens3$iface
			echo -e "ONBOOT=yes" | tee -a /etc/sysconfig/network-scripts/ifcfg-ens3$iface
                fi
		let iface=iface+1
	done
	systemctl restart network.service
	echo -e "0" > /usr/local/bin/config.txt
fi

server=$(vmtoolsd --cmd 'info-get guestinfo.scada.web')
port=$(vmtoolsd --cmd 'info-get guestinfo.scada.port')

iptables -I INPUT 1 -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT 1 -p tcp -m tcp --dport 443 -j ACCEPT
iptables -I INPUT 1 -p tcp -m tcp --dport $port -j ACCEPT

docker rm -f $(docker ps -a -q)
docker network rm $(docker network ls -q)

/bin/python2.7 /usr/local/bin/plc/PLC_manager.py -n $server:$port
