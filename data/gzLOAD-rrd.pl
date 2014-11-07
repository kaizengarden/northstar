#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent GlobalZone Load Graphing 
## benr@joyent - 4/5/09

use strict;
use Sun::Solaris::Kstat;

my $HOSTNAME  = `hostname`;
chomp($HOSTNAME);
my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();



	&check_rrd();

        my $LOAD1 = ${Kstat}->{unix}->{0}->{system_misc}->{avenrun_1min};
        my $LOAD5 = ${Kstat}->{unix}->{0}->{system_misc}->{avenrun_5min};
        my $LOAD15 = ${Kstat}->{unix}->{0}->{system_misc}->{avenrun_15min};

        $LOAD1 /= 256;
        $LOAD5 /= 256;
        $LOAD15 /= 256;


	### UPDATE GRAPH DATA:
	`/opt/jtk/bin/rrdtool update ${DATA_PATH}/load.rrd "N:${LOAD1}:${LOAD5}:${LOAD15}"`;

	### UPDATE GRAPH IMAGE:
	&output_graph();




### SUB:

sub check_rrd()
{
        my $zone = shift();

        if ( -e "${DATA_PATH}/load.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
              	`/opt/jtk/bin/rrdtool create ${DATA_PATH}/load.rrd --start N --step 300 DS:load1:GAUGE:600:U:U DS:load5:GAUGE:600:U:U DS:load15:GAUGE:600:U:U  RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph()
{

	## GRAPH LOAD
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/load.png -w 350 -a PNG --title="${HOSTNAME} Load Average" 'DEF:load1=${DATA_PATH}/load.rrd:load1:AVERAGE' 'DEF:load5=${DATA_PATH}/load.rrd:load5:AVERAGE' 'DEF:load15=${DATA_PATH}/load.rrd:load15:AVERAGE' 'AREA:load15#e0e0e0:15m Load' 'LINE1:load5#ff0000:5m Load' 'LINE1:load1#0000ff:1m Load'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/load-5d.png -w 350 -a PNG --start "-5d" --step 600 --title="${HOSTNAME} Load Average" 'DEF:load1=${DATA_PATH}/load.rrd:load1:AVERAGE' 'DEF:load5=${DATA_PATH}/load.rrd:load5:AVERAGE' 'DEF:load15=${DATA_PATH}/load.rrd:load15:AVERAGE' 'AREA:load15#e0e0e0:15m Load' 'LINE1:load5#ff0000:5m Load' 'LINE1:load1#0000ff:1m Load'`;
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/load-30d.png -w 350 -a PNG --start "-30d" --step 3600 --title="${HOSTNAME} Load Average" 'DEF:load1=${DATA_PATH}/load.rrd:load1:AVERAGE' 'DEF:load5=${DATA_PATH}/load.rrd:load5:AVERAGE' 'DEF:load15=${DATA_PATH}/load.rrd:load15:AVERAGE' 'AREA:load15#e0e0e0:15m Load' 'LINE1:load5#ff0000:5m Load' 'LINE1:load1#0000ff:1m Load'`;


}


