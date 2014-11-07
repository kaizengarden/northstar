#!/usr/bin/bash


if [ -e /opt/jtk/bin/northstar ]
then
cat <<ECHO
  Welcome to       __   __           __              
.-----.-----.----.|  |_|  |--.-----.|  |_.---.-.----.
|     |  _  |   _||   _|     |__ --||   _|  _  |   _|
|__|__|_____|__|  |____|__|__|_____||____|___._|__|  
                                                     
ECHO
else
        echo "Northstar must be unpacked into /opt/jtk." 
        echo "/opt/jtk/bin/northstar not found.  Exiting."
	rm -f /opt/jtk/install.sh
	mv /opt/jtk/upgrade.sh /opt/jtk/.upgrade.sh
        exit
fi


### Insert the lighttpd SMF & start it:
echo "Installing lighttpd SMF and starting...."
/usr/sbin/svccfg import /opt/jtk/var/svc/northstar_lighttpd.xml




VERSION=`/usr/bin/uname -v`

if [ $VERSION == "snv_121" ]
then
	echo "Installing PERL XML module dependancy..."
	yes | /usr/sbin/pkgadd -G -d /opt/jtk/var/pkg/SUNWperl-xml-parser-121.pkg  SUNWperl-xml-parser
	echo "Creating flows..."
	/opt/jtk/bin/autoflow | /bin/logger -p user.err -t northstar
else
        echo "Version is $VERSION, not 121, manual intervention required."
fi


if [ $VERSION == "snv_121" ]
then
	echo "Enabling Net Extended Accounting."
	mkdir /var/adm/exacct/ 2>/dev/null
	/usr/sbin/acctadm -e extended -f /var/adm/exacct/net net
fi

### Add the crontab entries:
echo "Install root Crontabs..."
cat >>/var/spool/cron/crontabs/root <<END

### NORTHSTAR ###############################################################
0,10,20,30,40,50 * * * * /opt/jtk/bin/northstar > /opt/jtk/www/northstar.html
0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/ns_dataloader

END



################################ THESE ARE THE _OLD_ WAY #################
## Zone RRDs
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/zoneIO-rrd.pl
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/zoneCAPS-rrd.pl
## Global Zone RRDs
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/gzLOAD-rrd.pl
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/gzCPU-rrd.pl
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/gzZFS-rrd.pl
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/gzDISK-rrd.pl
#0,5,10,15,20,25,30,35,40,45,50,55 * * * * /opt/jtk/data/gzNET-rrd.pl
########################### ^^^ THESE ARE THE _OLD_ WAY ^^^ ##############

/usr/sbin/svcadm restart cron
echo "Done."


rm -f /opt/jtk/install.sh
rm -f /opt/jtk/upgrade.sh
