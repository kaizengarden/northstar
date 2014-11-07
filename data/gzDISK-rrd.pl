#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent GlobalZone (Physical) Disk Graphing 
## benr@joyent - 4/5/09

use strict;
use Sun::Solaris::Kstat;

sub GetZpoolInstances();

#my @ZpoolDisks = qw(sd2);			# <------- EDIT THIS BASED ON ZPOOL CONFIGURATION!!!! ie: qw(sd1 sd2 sd3);
my @ZpoolDisks = GetZpoolInstances();

my $HOSTNAME  = `hostname`;
chomp($HOSTNAME);
my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();


###########
###########
###########
###########		CURRENTLY HARDCODED FOR SD1!!!!
###########
###########
###########

foreach my $disk (@ZpoolDisks){

	#print("Working on $disk...\n");
	&check_rrd($disk);

	my $sdInst = $disk;
	$sdInst =~ s/sd//;
	
	my $READ_BYTES  = ${Kstat}->{sd}->{$sdInst}->{$disk}->{nread};
	my $WRITE_BYTES = ${Kstat}->{sd}->{$sdInst}->{$disk}->{nwritten};
	my $READS       = ${Kstat}->{sd}->{$sdInst}->{$disk}->{reads};
	my $WRITES	= ${Kstat}->{sd}->{$sdInst}->{$disk}->{writes};

	#print("$READ_BYTES $WRITE_BYTES $READS $WRITES \n");

	### UPDATE GRAPH DATA:
	`/opt/jtk/bin/rrdtool update ${DATA_PATH}/disk-${disk}.rrd "N:${READ_BYTES}:${WRITE_BYTES}:${READS}:${WRITES}"`;

	### UPDATE GRAPH IMAGE:
	&output_graph($disk);
	##print("Done.\n");
}

exit;


### SUB:

sub check_rrd($)
{
        my $disk = shift();

        if ( -e "${DATA_PATH}/disk-${disk}.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
              	`/opt/jtk/bin/rrdtool create ${DATA_PATH}/disk-${disk}.rrd --start N --step 300 DS:readbytes:COUNTER:600:U:U DS:writebytes:COUNTER:600:U:U DS:readops:COUNTER:600:U:U DS:writeops:COUNTER:600:U:U  RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph($)
{
        my $disk = shift();

	## GRAPH LOAD
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/disk-${disk}.png -w 350 -a PNG --title="${HOSTNAME} ${disk} Physical R/W" -l 0 -r 'DEF:readbytes=${DATA_PATH}/disk-${disk}.rrd:readbytes:AVERAGE' 'DEF:writebytes=${DATA_PATH}/disk-${disk}.rrd:writebytes:AVERAGE' 'LINE1:readbytes#0000ff:Read Bytes' 'LINE1:writebytes#ff0000:Write Bytes'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/disk-${disk}-5d.png -w 350 -a PNG --start "-5d" --step 600 --title="${HOSTNAME} ${disk} Physical R/W" -l 0 -r 'DEF:readbytes=${DATA_PATH}/disk-${disk}.rrd:readbytes:AVERAGE' 'DEF:writebytes=${DATA_PATH}/disk-${disk}.rrd:writebytes:AVERAGE' 'LINE1:readbytes#0000ff:Read Bytes' 'LINE1:writebytes#ff0000:Write Bytes'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/disk-${disk}-30d.png -w 350 -a PNG --start "-30d" --step 3600 --title="${HOSTNAME} ${disk} Physical R/W" -l 0 -r 'DEF:readbytes=${DATA_PATH}/disk-${disk}.rrd:readbytes:AVERAGE' 'DEF:writebytes=${DATA_PATH}/disk-${disk}.rrd:writebytes:AVERAGE' 'LINE1:readbytes#0000ff:Read Bytes' 'LINE1:writebytes#ff0000:Write Bytes'`;

}


###
### Here we use several tricks to get the zpool disk names out of the zpool.cache, then we loop through iostat in order to derefence into a standard sdX isntance
###	The result is a returned array with sdX1, sdX2, etc.
###
sub GetZpoolInstances(){
        my @ZpoolInstances;
	my @sdList;

        ## Get a list of all the proper names for the available disks:
        my @sdTemp = `iostat -E | grep Soft | awk '{print \$1}'`;
        foreach(@sdTemp){
                chomp($_);
                #print ("IOstat said: $_\n");
                push(@sdList, $_);
        }
         
        ## Now get the disks used by the pools
        my @poolDisks = `strings /etc/zfs/zpool.cache  | grep dsk`;
        foreach(@poolDisks) {
                chomp($_);
                $_ =~ s/.*\/dev\/dsk\///;
                push(@ZpoolDisks, $_);
        }
         
        ## Now look up each sd* device looking for our pool disk; this is crapy but works.
        foreach my $poolDrive (@ZpoolDisks){
                $poolDrive =~ s/s\d//;
                #print("Doing $poolDrive.........\n");                  # poolDrive is a cXtXdX pool drive.

                foreach my $ioDrive (@sdList) {                            # ioDrive is a sdX name from the list of all disks
                        my $tmpOut = `iostat -En $ioDrive | grep Soft | awk '{print \$1}'`;     # Now convert each ioDrive into cXtXdX format
                        chomp($tmpOut);

                        if ( $poolDrive eq $tmpOut  ) {                 # Finally, see if the conversion result matches one of our pool disks.
                                #print("Found it. $poolDrive is $ioDrive\n");
                                push(@ZpoolInstances, $ioDrive);
                        } else {
                                #print("Nope... $poolDrive is not $ioDrive ( $tmpOut )\n");
                        }
                }
        }
         
        return(@ZpoolInstances);
}

