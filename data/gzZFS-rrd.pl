#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent GlobalZone ZFS VFS Graphing 
## benr@joyent - 4/5/09

use strict;
use Sun::Solaris::Kstat;

my $HOSTNAME  = `hostname`;
chomp($HOSTNAME);
my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();



	&check_rrd();

	## unix:0:vopstats_zfs:class
        my $read_bytes  =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{read_bytes};
        my $write_bytes =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{write_bytes};
        my $nread       =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{nread};
        my $nwrite      =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{nwrite};
        my $ngetattr    =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{ngetattr};
        my $nlookup     =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{nlookup};
        my $nseek       =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{nseek};
        my $naccess     =  ${Kstat}->{unix}->{0}->{vopstats_zfs}->{naccess};
        # ...



	### UPDATE GRAPH DATA:
	`/opt/jtk/bin/rrdtool update ${DATA_PATH}/zfs-rw.rrd "N:${read_bytes}:${write_bytes}"`;
	#`/opt/jtk/bin/rrdtool update ${DATA_PATH}/zfs-vop.rrd "N:${nread}:${nwrite}:${ngetattr}:${nseek}:${naccess}:${nlookup}"`;

	### UPDATE GRAPH IMAGE:
	&output_graph();




### SUB:

sub check_rrd()
{
        my $zone = shift();

        if ( -e "${DATA_PATH}/zfs-rw.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
              	`/opt/jtk/bin/rrdtool create ${DATA_PATH}/zfs-rw.rrd --start N --step 300 DS:read:COUNTER:600:U:U DS:write:COUNTER:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph()
{

	## GRAPH RW
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zfs-rw.png -a PNG --title="${HOSTNAME} ZFS Logical R/W" -w 350 -l 0 -r 'DEF:read=${DATA_PATH}/zfs-rw.rrd:read:AVERAGE' 'DEF:write=${DATA_PATH}/zfs-rw.rrd:write:AVERAGE' 'LINE1:read#0000ff:Read Bytes' 'LINE1:write#ff0000:Write Bytes'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zfs-rw-5d.png -a PNG --title="${HOSTNAME} ZFS Logical R/W" --start "-5d" --step 600 -w 350 -l 0 -r 'DEF:read=${DATA_PATH}/zfs-rw.rrd:read:AVERAGE' 'DEF:write=${DATA_PATH}/zfs-rw.rrd:write:AVERAGE' 'LINE1:read#0000ff:Read Bytes' 'LINE1:write#ff0000:Write Bytes'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zfs-rw-30d.png -a PNG --title="${HOSTNAME} ZFS Logical R/W" --start "-30d" --step 3600 -w 350 -l 0 -r 'DEF:read=${DATA_PATH}/zfs-rw.rrd:read:AVERAGE' 'DEF:write=${DATA_PATH}/zfs-rw.rrd:write:AVERAGE' 'LINE1:read#0000ff:Read Bytes' 'LINE1:write#ff0000:Write Bytes'`;



}


