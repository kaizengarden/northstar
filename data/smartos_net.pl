#!/usr/perl5/bin/perl
## SmartOS/SDC Zone Network Grapher
##  link:0:z91_net0:obytes64

use strict;
use Sun::Solaris::Kstat;

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";

my $Kstat = Sun::Solaris::Kstat->new();

####################################################
my @zoneList = `/usr/sbin/zoneadm list -p`;


foreach(@zoneList){
        my ($zoneId, $zoneName, $zoneState, $zoneMount) = split(/:/, $_);
        #print("Got zone: $zoneName ($zoneId): $zoneMount\n");

        next if($zoneId == 0);

        ### VERIFY OR CREATE EXISTANCE OF ZONE RRD:
        &check_rrd($zoneId);

	my $zif0 = "z${zoneId}_net0";
        my $rzif0 =  ${Kstat}->{link}->{0}->{$zif0}->{rbytes64};
	my $ozif0 =  ${Kstat}->{link}->{0}->{$zif0}->{obytes64};

	my $zif1 = "z${zoneId}_net1";
        my $rzif1 =  ${Kstat}->{link}->{0}->{$zif1}->{rbytes64};
	my $ozif1 =  ${Kstat}->{link}->{0}->{$zif1}->{obytes64};
	
	#print("$zoneName net0: ${rzif0}/${ozif0}   net1: ${rzif1}/${ozif1}\n");

        ### UPDATE GRAPH DATA:
        `/opt/jtk/bin/rrdtool update ${DATA_PATH}/net-${zoneId}.rrd "N:${rzif0}:${ozif0}:${rzif1}:${ozif1}"`;

        ### UPDATE GRAPH IMAGE:
        &output_graph($zoneId, $zoneName); 
}
	


################## SUBS #############################################

sub check_rrd($)
{
        my $zoneId = shift();

        if ( -e "${DATA_PATH}/net-${zoneId}.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
                `/opt/jtk/bin/rrdtool create ${DATA_PATH}/net-${zoneId}.rrd --start N --step 300 DS:net0_rbits:COUNTER:600:U:U  DS:net0_obits:COUNTER:600:U:U DS:net1_rbits:COUNTER:600:U:U  DS:net1_obits:COUNTER:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph($$)
{
        my $zoneId = shift();
	my $zoneName = shift();

        ## 1 Day output:
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/net-${zoneId}.png -a PNG --title="${zoneName} Bandwidth" --vertical-label "Bits" 'DEF:net0_rbits=${DATA_PATH}/net-${zoneId}.rrd:net0_rbits:AVERAGE' 'DEF:net0_obits=${DATA_PATH}/net-${zoneId}.rrd:net0_obits:AVERAGE' 'DEF:net1_rbits=${DATA_PATH}/net-${zoneId}.rrd:net1_rbits:AVERAGE' 'DEF:net1_obits=${DATA_PATH}/net-${zoneId}.rrd:net1_obits:AVERAGE' 'LINE1:net0_rbits#ff0000:net0 Recieved' 'LINE1:net0_obits#0000ff:net0 Sent' 'LINE1:net1_rbits#00ff00:net1 Recieved' 'LINE1:net1_obits#ff9933:net1 Sent'`;

	## 5 Day output:
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/net-${zoneId}-5d.png -a PNG --start "-5d" --step 600 --title="${zoneName} Bandwidth" --vertical-label "Bits" 'DEF:net0_rbits=${DATA_PATH}/net-${zoneId}.rrd:net0_rbits:AVERAGE' 'DEF:net0_obits=${DATA_PATH}/net-${zoneId}.rrd:net0_obits:AVERAGE' 'DEF:net1_rbits=${DATA_PATH}/net-${zoneId}.rrd:net1_rbits:AVERAGE' 'DEF:net1_obits=${DATA_PATH}/net-${zoneId}.rrd:net1_obits:AVERAGE' 'LINE1:net0_rbits#ff0000:net0 Recieved' 'LINE1:net0_obits#0000ff:net0 Sent' 'LINE1:net1_rbits#00ff00:net1 Recieved' 'LINE1:net1_obits#ff9933:net1 Sent'`;

	## 30 Day output:	
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/net-${zoneId}-30d.png -a PNG --start "-30d" --step 3600 --title="${zoneName} Bandwidth" --vertical-label "Bits" 'DEF:net0_rbits=${DATA_PATH}/net-${zoneId}.rrd:net0_rbits:AVERAGE' 'DEF:net0_obits=${DATA_PATH}/net-${zoneId}.rrd:net0_obits:AVERAGE' 'DEF:net1_rbits=${DATA_PATH}/net-${zoneId}.rrd:net1_rbits:AVERAGE' 'DEF:net1_obits=${DATA_PATH}/net-${zoneId}.rrd:net1_obits:AVERAGE' 'LINE1:net0_rbits#ff0000:net0 Recieved' 'LINE1:net0_obits#0000ff:net0 Sent' 'LINE1:net1_rbits#00ff00:net1 Recieved' 'LINE1:net1_obits#ff9933:net1 Sent'`;


}



