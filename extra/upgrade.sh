#!/bin/bash


echo "Checking Northstar 0.5.6 Dependancies"

VERSION=`/usr/bin/uname -v`

if [ $VERSION == "snv_121" ]
then

 if pkginfo SUNWperl-xml-parser >/dev/null
 then
	echo "PERL XML dependancy already installed."
 else
        echo "Installing PERL XML module dependancy..."
        yes | /usr/sbin/pkgadd -G -d /opt/jtk/var/pkg/SUNWperl-xml-parser-121.pkg  SUNWperl-xml-parser
 fi

 echo "Creating flows..."
 /opt/jtk/bin/autoflow

 echo ""
 echo "Enabling Net Extended Accounting."
 echo ""
 #mkdir /var/adm/exacct/ 2>/dev/null
 #/usr/sbin/acctadm -e extended -f /var/adm/exacct/net net
else
        echo "Version is $VERSION, not 121, manual intervention may be required for post-121 builds."
fi


echo ""
echo "Upgrading RRD Databases to provide 30 days of data."
echo ""

cd /opt/jtk/data/
echo "Creating backup in backup/"
mkdir backup 2>/dev/null
cp * backup/

for i in `ls *.rrd`
do

 if /opt/jtk/bin/rrdtool info $i  | grep 'rra\[2\]' | grep 'rows = 1440' >/dev/null
 then
   echo "Upgrading RRD datafile $i ..."
   /opt/jtk/bin/rrdtool resize $i 2 GROW 7200
   mv resize.rrd $i
 else 
   echo "RRD $i is fine, skipping."
 fi
done


echo "Done.  You may verify by using 'rrdtool info somedb.rrd'.  Look for rra[2].rows."
rm -f /opt/jtk/upgrade.sh
rm -f /opt/jtk/install.sh
