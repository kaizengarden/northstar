#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent GlobalZone CPU Graphing 
## benr@joyent - 4/5/09

use strict;
use Sun::Solaris::Kstat;

my $HOSTNAME  = `hostname`;
chomp($HOSTNAME);
my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();



	&check_rrd();

	#unix:0:system_misc:ncpus
	#cpu:1:sys:cpu_nsec_idle 14511351257606130
	#cpu:1:sys:cpu_nsec_intr 14610602201435
	#cpu:1:sys:cpu_nsec_kernel       2393494887301495
	#cpu:1:sys:cpu_nsec_user 3394121418891352	

	my $CPUS = ${Kstat}->{unix}->{0}->{system_misc}->{ncpus};
	my $IDLE = 0;
	my $INTR = 0;
	my $SYS  = 0;
	my $USR  = 0;

	## Must poll each CPU
	for ( my $i = 0; $i < $CPUS; $i++ ){
		$IDLE += ${Kstat}->{cpu}->{$i}->{sys}->{cpu_nsec_idle};	
		$INTR += ${Kstat}->{cpu}->{$i}->{sys}->{cpu_nsec_intr};	
		$SYS  += ${Kstat}->{cpu}->{$i}->{sys}->{cpu_nsec_kernel};	
		$USR  += ${Kstat}->{cpu}->{$i}->{sys}->{cpu_nsec_user};	
	}
	



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
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/cpu-5d.png -a PNG -w 350 --start "-5d" --step 600 --title="${HOSTNAME} CPU Usage" 'DEF:sys=${DATA_PATH}/cpu.rrd:sys:AVERAGE' 'DEF:usr=${DATA_PATH}/cpu.rrd:usr:AVERAGE' 'DEF:intr=${DATA_PATH}/cpu.rrd:intr:AVERAGE' 'DEF:idle=${DATA_PATH}/cpu.rrd:idle:AVERAGE' 'AREA:sys#e0e0e0:System' 'AREA:usr#00ff00:User:STACK' 'AREA:intr#ff0000:Interrupt:STACK' 'AREA:idle#0000ff:Idle:STACK'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/cpu-30d.png -a PNG -w 350 --start "-30d" --step 3600 --title="${HOSTNAME} CPU Usage" 'DEF:sys=${DATA_PATH}/cpu.rrd:sys:AVERAGE' 'DEF:usr=${DATA_PATH}/cpu.rrd:usr:AVERAGE' 'DEF:intr=${DATA_PATH}/cpu.rrd:intr:AVERAGE' 'DEF:idle=${DATA_PATH}/cpu.rrd:idle:AVERAGE' 'AREA:sys#e0e0e0:System' 'AREA:usr#00ff00:User:STACK' 'AREA:intr#ff0000:Interrupt:STACK' 'AREA:idle#0000ff:Idle:STACK'`;
}


