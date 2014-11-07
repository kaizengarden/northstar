#!/usr/perl5/bin/perl -w

## benr@joyent - 4/2/09

use strict;
use Sun::Solaris::Kstat;

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();


my @zoneList = `/usr/sbin/zoneadm list -p`;




foreach(@zoneList){

        my ($zoneId, $zoneName, $zoneState, $zoneMount) = split(/:/, $_);
        #print("Got zone: $zoneName ($zoneId): $zoneMount\n");

        next if($zoneId == 0);



	### VERIFY OR CREATE EXISTANCE OF ZONE RRD:
        &check_rrd($zoneName);



        ## Now we have a zone name and its mountpoint.... lets now find its fs_id:
        my $fs_id = &find_fsid($zoneMount);

        ## Lets pull some vopstats:
        my $voppie = "vopstats_${fs_id}";
        my $read_bytes  =  ${Kstat}->{unix}->{0}->{$voppie}->{read_bytes};
        my $write_bytes =  ${Kstat}->{unix}->{0}->{$voppie}->{write_bytes};
        my $nread       =  ${Kstat}->{unix}->{0}->{$voppie}->{nread};
        my $nwrite      =  ${Kstat}->{unix}->{0}->{$voppie}->{nwrite};
        my $ngetattr    = ${Kstat}->{unix}->{0}->{$voppie}->{ngetattr};
        # ...

        #print(" >> OPS: $nread / $nwrite   BYTES: $read_bytes / $write_bytes\n");

	### UPDATE GRAPH DATA:
	`/opt/jtk/bin/rrdtool update ${DATA_PATH}/zfsrw-${zoneName}.rrd "N:${read_bytes}:${write_bytes}"`;

	### UPDATE GRAPH IMAGE:
	&output_graph($zoneName);

}



### SUB:


#[root@am1-ja2950-63 /opt/jtk/data]# /usr/bin/df -g /zones/gmqecyaa
#/zones/gmqecyaa    (zones/gmqecyaa    ):       131072 block size           512 frag size  
#31457280 total blocks   31169736 free blocks 31169736 available       31307544 total files
#31169736 free files     47775753 filesys id  
#     zfs fstype       0x00000004 flag             255 filename length


sub find_fsid($)
{
        my $fs = shift();

        my @df = `/usr/bin/df -g $fs`;  ## use df -g to return fs structure for mountpoint
	my $cleanline = $df[2]; 
	$cleanline =~ s/^\s*//;	## Trim any leading whitespace
        my @x = split(/\s+/, $cleanline);   ## we only want the 3rd line of output
        my $fs_id = $x[3];              ## Now take the filesys id value, which is 4th on the line of output
        $fs_id = sprintf("%x", $fs_id); ## Finally, convert the dec fs_id to hex.

        ##print("Found fs_id of $fs_id for $fs\n");

        return($fs_id);

}

sub check_rrd($)
{
        my $zone = shift();

        if ( -e "${DATA_PATH}/zfsrw-${zone}.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
              	`/opt/jtk/bin/rrdtool create ${DATA_PATH}/zfsrw-${zone}.rrd --start N --step 300 DS:read_bytes:COUNTER:600:U:U  DS:write_bytes:COUNTER:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph($)
{
	my $zone = shift();

	## 1 Day output:
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zfsrw-${zone}.png -a PNG --title="${zone} I/O" --vertical-label "Bytes" 'DEF:read=${DATA_PATH}/zfsrw-${zone}.rrd:read_bytes:AVERAGE' 'DEF:write=${DATA_PATH}/zfsrw-${zone}.rrd:write_bytes:AVERAGE' 'LINE1:read#ff0000:Read' 'LINE1:write#0000ff:Write'`;
	## 5 Day output:
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zfsrw-${zone}-5d.png -a PNG --start "-5d" --step 600 --title="${zone} I/O" --vertical-label "Bytes" 'DEF:read=${DATA_PATH}/zfsrw-${zone}.rrd:read_bytes:AVERAGE' 'DEF:write=${DATA_PATH}/zfsrw-${zone}.rrd:write_bytes:AVERAGE' 'LINE1:read#ff0000:Read' 'LINE1:write#0000ff:Write'`;
	## 30 Day output:
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zfsrw-${zone}-30d.png -a PNG --start "-30d" --step 3600 --title="${zone} I/O" --vertical-label "Bytes" 'DEF:read=${DATA_PATH}/zfsrw-${zone}.rrd:read_bytes:AVERAGE' 'DEF:write=${DATA_PATH}/zfsrw-${zone}.rrd:write_bytes:AVERAGE' 'LINE1:read#ff0000:Read' 'LINE1:write#0000ff:Write'`;

}

