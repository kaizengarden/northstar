#!/usr/perl5/bin/perl

## --benr Based on northstar


use strict;
use Sun::Solaris::Kstat;

my $DEBUG = 0;

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $HOSTNAME = `hostname`;
chomp($HOSTNAME);

my $Kstat = Sun::Solaris::Kstat->new();

######################################################################################
############# MAIN                                                              ######
######################################################################################
        
        &check_rrd();

	my $pagesize = `/usr/bin/pagesize`;
	chomp($pagesize);

	## Values in Pages
	my $SWAP_ALLOC =  ${Kstat}->{unix}->{0}->{vminfo}->{swap_alloc};
 	my $SWAP_FREE  =  ${Kstat}->{unix}->{0}->{vminfo}->{swap_free};
	my $SWAP_AVAIL =  ${Kstat}->{unix}->{0}->{vminfo}->{swap_avail};

	$SWAP_ALLOC *= $pagesize;
	$SWAP_FREE  *= $pagesize;
	$SWAP_AVAIL *= $pagesize;

        ### RRD Update

        #print("RRD Update: ${SWAP_ALLOC} ${SWAP_FREE} ${SWAP_AVAIL}  ( pages ) \n");
        `/opt/jtk/bin/rrdtool update /opt/jtk/data/vmem.rrd "N:${SWAP_ALLOC}:${SWAP_FREE}:${SWAP_AVAIL}"`;

        &output_graph();

        exit(0);





######################################################################################
############# SUBROUTINES                                                       ######
######################################################################################

sub check_rrd()
{

        if ( -e "${DATA_PATH}/vmem.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
                `/opt/jtk/bin/rrdtool create ${DATA_PATH}/vmem.rrd --start N --step 300 DS:SWAP_ALLOC:COUNTER:600:U:U DS:SWAP_FREE:COUNTER:600:U:U DS:SWAP_AVAIL:COUNTER:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph()
{

        ## Output graph
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/vmem.png -a PNG --width 350 --title="${HOSTNAME} Virtual Memory" 'DEF:avail=${DATA_PATH}/vmem.rrd:SWAP_AVAIL:AVERAGE' 'DEF:free=${DATA_PATH}/vmem.rrd:SWAP_FREE:AVERAGE'  'LINE1:avail#0000ff:Available' 'LINE1:free#ff0000:Free' `;

	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/vmem-5d.png -a PNG --start "-5d" --step 600 --title="${HOSTNAME} Virtual Memory" 'DEF:avail=${DATA_PATH}/vmem.rrd:SWAP_AVAIL:AVERAGE' 'DEF:free=${DATA_PATH}/vmem.rrd:SWAP_FREE:AVERAGE'  'LINE1:avail#0000ff:Available' 'LINE1:free#ff0000:Free' `;

	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/vmem-30d.png -a PNG --start "-30d" --step 3600 --title="${HOSTNAME} Virtual Memory" 'DEF:avail=${DATA_PATH}/vmem.rrd:SWAP_AVAIL:AVERAGE' 'DEF:free=${DATA_PATH}/vmem.rrd:SWAP_FREE:AVERAGE'  'LINE1:avail#0000ff:Available' 'LINE1:free#ff0000:Free' `;

}
