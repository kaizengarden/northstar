#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent GlobalZone Process Count Graphing 
## benr@joyent - 4/5/09

use strict;
use Sun::Solaris::Kstat;

my $HOSTNAME  = `hostname`;
chomp($HOSTNAME);
my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();



        &check_rrd();


         my $NPROCS = ${Kstat}->{unix}->{0}->{system_misc}->{nproc};


        ### UPDATE GRAPH DATA:
        `/opt/jtk/bin/rrdtool update ${DATA_PATH}/procs.rrd "N:${NPROCS}"`;

        ### UPDATE GRAPH IMAGE:
        &output_graph();




### SUB:

sub check_rrd()
{
        my $zone = shift();

        if ( -e "${DATA_PATH}/procs.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
                `/opt/jtk/bin/rrdtool create ${DATA_PATH}/procs.rrd --start N --step 300 DS:nprocs:GAUGE:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph()
{

        ## GRAPH LOAD
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/procs.png -a PNG --start "-5d" --step 600 --title="${HOSTNAME} Processes" 'DEF:nprocs=${DATA_PATH}/procs.rrd:nprocs:AVERAGE' 'LINE1:nprocs#0000ff:Processes'`;
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/procs-30d.png -a PNG --start "-30d" --step 3600 --title="${HOSTNAME} Processes" 'DEF:nprocs=${DATA_PATH}/procs.rrd:nprocs:AVERAGE' 'LINE1:nprocs#0000ff:Processes'`;


}

