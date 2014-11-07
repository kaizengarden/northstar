#!/usr/perl5/bin/perl

use strict;
use Sun::Solaris::Kstat;

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";

my $ks = Sun::Solaris::Kstat->new();

my @flowsCombined;

############## FLOW & LINK BUILDERS ###############
my @linkKeys;
my @flow_tmp;
my @flowKeys;

## Build a list of all LINKS
my $link_ref = $ks->{link}{0};
foreach my $lk ( keys(%$link_ref) ){
        #print("Found key for: $lk\n");
        push(@linkKeys, $lk);
}

## Build a list of all FLOWS
my $flow_ref = $ks->{unix}{0};
foreach my $fk ( keys(%$flow_ref) ){
        if ( $flow_ref->{$fk}{class} eq "flow" && $fk !~ m/^mac\// ){
                push(@flow_tmp, $fk);
        }
}
## Now purge duplication from the flows list
foreach my $x (@flow_tmp){
  push(@flowKeys, $x) unless (  grep( /$x/, @linkKeys) );
}
####################################################



#### Process the LINKS
foreach my $link (@linkKeys) {

	&check_rrd($link);

	my $rbits = $link_ref->{${link}}{rbytes64} * 8;
	my $obits = $link_ref->{${link}}{obytes64} * 8;
	`echo \"L $link rbits: $rbits obits: $obits\" >> /tmp/rrd-debug.txt`;

        ### UPDATE GRAPH DATA:
        `/opt/jtk/bin/rrdtool update ${DATA_PATH}/flow-${link}.rrd "N:${rbits}:${obits}"`;

        ### UPDATE GRAPH IMAGE:
        &output_graph($link);
	push(@flowsCombined, $link);
}

#### Process the FLOWS
foreach my $flow (@flowKeys) {

        &check_rrd($flow);

        my $rbits = $flow_ref->{${flow}}{rbytes} * 8;
        my $obits = $flow_ref->{${flow}}{obytes} * 8;
	`echo \"F $flow rbits: $rbits obits: $obits\" >> /tmp/rrd-debug.txt`;

        ### UPDATE GRAPH DATA:
        `/opt/jtk/bin/rrdtool update ${DATA_PATH}/flow-${flow}.rrd "N:${rbits}:${obits}"`;

        ### UPDATE GRAPH IMAGE:
        &output_graph($flow); 
	push(@flowsCombined, $flow);
}


sub rollup() {
#####   Process rollup graphs ###########################################################
my $flipper = 1;
my @colors = qw(13FF00 0DFF08 07FF0F 02FF17 00FF20 00FF28 00FF30 00FF39 00FE41 00FC4A 00FA53 00F85B 00F564 00F26D 00EE76 00EB7E 00E787 00E38F 00DE98 00D9A0 00D4A8 00CFB0 00CAB8 00C4C0 00BEC7 00B8CF 00B2D6 00ACDD 00A6E3 009FEA 0099F0 0092F6 008CFB 0085FF 007EFF 0078FF 0071FF 016BFF 0764FF 0D5EFF 1357FF 1A51FF 214BFF 2845FF 2F3FFF 363AFF 3E34FF 462FFF 4E2AFF 5625FF 5E20FF 661CFF 6E18FF 7714FF 7F11FF 880EFF 900BFF 9908FF A106FF A904FF B203FF BA01FF C201FF CA00FF);

my $iflows_defs;
my $iflows_draws; 
my $oflows_defs;
my $oflows_draws;

foreach my $x (@flowsCombined) {
        my $color;

        # This is to alternate colors across a spetrum, ugly but descriptive.
        if ( $flipper == 1) {
                $color = $colors[0];
                shift(@colors);
                $flipper = 0;
        } else {
                $color = pop(@colors);
                $flipper = 1;
        }


        ### Generate parameters for Flows
        $iflows_defs  .= " \'DEF:${x}in=${DATA_PATH}/flows-${x}.rrd:rbits:AVERAGE\'";
        $iflows_draws .= " \'AREA:${x}in#${color}:${x} :STACK\'";
        $iflows_draws .= " \'GPRINT:${x}in:MIN:min\\: %5.2lf %s \'";
        $iflows_draws .= " \'GPRINT:${x}in:MAX:max\\: %5.2lf %s \'";
        $iflows_draws .= " \'GPRINT:${x}in:LAST:last\\: %5.2lf %s \'";

        $oflows_defs  .= " \'DEF:${x}out=${DATA_PATH}/flows-${x}.rrd:obits:AVERAGE\'";
        $oflows_draws .= " \'AREA:${x}out#${color}:${x} :STACK\'";
        $oflows_draws .= " \'GPRINT:${x}out:MIN:min\\: %5.2lf %s \'";
        $oflows_draws .= " \'GPRINT:${x}out:MAX:max\\: %5.2lf %s \'";
        $oflows_draws .= " \'GPRINT:${x}out:LAST:last\\: %5.2lf %s \'";
}

## Render the FLOW Rollup Graphs
my $GRAPH_SETUP_CPU="/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zones-iflows-rollup-5d.png -a PNG --start \"-5d\" --step 600 --title=\"Network Bits Recieved by Flow\" -b 1024  --vertical-label=\"Bits\" --watermark \"+Joyent Operations\"  ";
`$GRAPH_SETUP_CPU $iflows_defs $iflows_draws`;

$GRAPH_SETUP_CPU="/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zones-oflows-rollup-5d.png -a PNG --start \"-5d\" --step 600 --title=\"Network Bits Sent by Flow\" -b 1024  --vertical-label=\"Bits\" --watermark \"+Joyent Operations\"  ";
`$GRAPH_SETUP_CPU $oflows_defs $oflows_draws`;

}

################## SUBS #############################################

sub check_rrd($)
{
        my $flow = shift();

        if ( -e "${DATA_PATH}/flow-${flow}.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
                `/opt/jtk/bin/rrdtool create ${DATA_PATH}/flow-${flow}.rrd --start N --step 300 DS:rbits:COUNTER:600:U:U  DS:obits:COUNTER:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph($)
{
        my $flow = shift();

        ## 1 Day output:
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/flow-${flow}.png -a PNG --title="${flow} Bandwidth" --vertical-label "Bits" 'DEF:in=${DATA_PATH}/flow-${flow}.rrd:rbits:AVERAGE' 'DEF:out=${DATA_PATH}/flow-${flow}.rrd:obits:AVERAGE' 'LINE1:in#ff0000:Recieved' 'LINE1:out#0000ff:Sent'`;
        ## 5 Day output:
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/flow-${flow}-5d.png -a PNG --start "-5d" --step 600 --title="${flow} Bandwidth" --vertical-label "Bits" 'DEF:in=${DATA_PATH}/flow-${flow}.rrd:rbits:AVERAGE' 'DEF:out=${DATA_PATH}/flow-${flow}.rrd:obits:AVERAGE' 'LINE1:in#ff0000:Recieved' 'LINE1:out#0000ff:Sent'`;
        ## 30 Day output:
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/flow-${flow}-30d.png -a PNG --start "-30d" --step 3600 --title="${flow} Bandwidth" --vertical-label "Bits" 'DEF:in=${DATA_PATH}/flow-${flow}.rrd:rbits:AVERAGE' 'DEF:out=${DATA_PATH}/flow-${flow}.rrd:obits:AVERAGE' 'LINE1:in#ff0000:Recieved' 'LINE1:out#0000ff:Sent'`;

}




