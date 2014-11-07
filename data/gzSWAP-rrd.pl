#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent GlobalZone Swap Graphing 
## benr@joyent - 4/5/09

use strict;

my $HOSTNAME  = `hostname`;
chomp($HOSTNAME);
my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";



	&check_rrd();

	# benr@quadra ~$ swap -s
	# total: 900212k bytes allocated + 121228k reserved = 1028640k used, 1619292k available
	# benr@quadra ~$ swap -lk
	# swapfile             dev    swaplo   blocks     free
	# /dev/zvol/dsk/rpool/swap 182,9        4K 2094076K 2049656K


	
	my $ALLOC =
	my $RESV  = 	
	my $USED  = 
	my $AVAIL = 
	my $TOTAL = 
	my $FREE  =



	### UPDATE GRAPH DATA:
#	print("UPDATING ${DATA_PATH}/cpu.rrd: ${IDLE}:${INTR}:${SYS}:${USR}\n");
	`/opt/jtk/bin/rrdtool update ${DATA_PATH}/cpu.rrd "N:${IDLE}:${INTR}:${SYS}:${USR}"`;

	### UPDATE GRAPH IMAGE:
	&output_graph();




### SUB:

sub check_rrd()
{
        my $zone = shift();

        if ( -e "${DATA_PATH}/cpu.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
              	`/opt/jtk/bin/rrdtool create ${DATA_PATH}/cpu.rrd --start N --step 300 DS:idle:COUNTER:600:U:U DS:intr:COUNTER:600:U:U DS:sys:COUNTER:600:U:U DS:usr:COUNTER:600:U:U  RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph()
{

	## GRAPH CPU 
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/cpu.png -a PNG -w 350 --title="${HOSTNAME} CPU Usage" 'DEF:sys=${DATA_PATH}/cpu.rrd:sys:AVERAGE' 'DEF:usr=${DATA_PATH}/cpu.rrd:usr:AVERAGE' 'DEF:intr=${DATA_PATH}/cpu.rrd:intr:AVERAGE' 'DEF:idle=${DATA_PATH}/cpu.rrd:idle:AVERAGE' 'AREA:sys#e0e0e0:System' 'AREA:usr#00ff00:User:STACK' 'AREA:intr#ff0000:Interrupt:STACK' 'AREA:idle#0000ff:Idle:STACK'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/cpu-5d.png -a PNG -w 350 --title="${HOSTNAME} CPU Usage" --start "-5d" --step 600 'DEF:sys=${DATA_PATH}/cpu.rrd:sys:AVERAGE' 'DEF:usr=${DATA_PATH}/cpu.rrd:usr:AVERAGE' 'DEF:intr=${DATA_PATH}/cpu.rrd:intr:AVERAGE' 'DEF:idle=${DATA_PATH}/cpu.rrd:idle:AVERAGE' 'AREA:sys#e0e0e0:System' 'AREA:usr#00ff00:User:STACK' 'AREA:intr#ff0000:Interrupt:STACK' 'AREA:idle#0000ff:Idle:STACK'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/cpu-30d.png -a PNG -w 350 --title="${HOSTNAME} CPU Usage" --start "-30d" --step 3600 'DEF:sys=${DATA_PATH}/cpu.rrd:sys:AVERAGE' 'DEF:usr=${DATA_PATH}/cpu.rrd:usr:AVERAGE' 'DEF:intr=${DATA_PATH}/cpu.rrd:intr:AVERAGE' 'DEF:idle=${DATA_PATH}/cpu.rrd:idle:AVERAGE' 'AREA:sys#e0e0e0:System' 'AREA:usr#00ff00:User:STACK' 'AREA:intr#ff0000:Interrupt:STACK' 'AREA:idle#0000ff:Idle:STACK'`;
}


