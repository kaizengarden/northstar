#!/usr/perl5/bin/perl -w

### NORTHSTAR MODULE ############################################################

### +Joyent Accelerator CAP Grapher (RRD) for monitoring usage of CPU, RSS (RCAP) and VM.
## benr@joyent - 4/5/09

use strict;
use Sun::Solaris::Kstat;

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $Kstat = Sun::Solaris::Kstat->new();


my @zoneList = `/usr/sbin/zoneadm list -p`;
my @rcapStat = `/bin/rcapstat -z 1 1`;




foreach(@zoneList){

        my ($zoneId, $zoneName, $zoneState, $zoneMount) = split(/:/, $_);
        #print("Got zone: $zoneName ($zoneId): $zoneMount\n");

        next if($zoneId == 0);



	### VERIFY OR CREATE EXISTANCE OF ZONE RRD:
        &check_rrd($zoneName);

	### Get VM Used & Value (Cap)
        my $swapper = "swapresv_zone_${zoneId}";
        my $swapUsage = ${Kstat}->{caps}->{$zoneId}->{$swapper}->{usage};
        my $swapLimit = ${Kstat}->{caps}->{$zoneId}->{$swapper}->{value};

	### Get CPU Used & Value (Cap) 
        my $chipper = "cpucaps_zone_${zoneId}";
        my $cpuUsage = ${Kstat}->{caps}->{$zoneId}->{$chipper}->{usage};
	my $cpuValue = ${Kstat}->{caps}->{$zoneId}->{$chipper}->{value};



        my $rcapVM = 0;
        my $rcapRSS = 0;
        my $rcapCAP = 0;
        my $rcapOVER = "-";
        if (`/usr/bin/uname -v` !~ /^joyent/) {
          ###
          ### RCAP:
          ###
          foreach(@rcapStat) {
             my ($rid, $rzone, $rnproc, $rvm, $rrss, $rcap, $rat, $ravgat, $rpg, $ravgpg) = split;

                     next if ( $rid eq "id" );

             if ($rzone eq $zoneName) {
               #print("-- RCAP: $rzone, $rvm, $rrss, $rcap\n");
               $rcapVM   = $rvm;
               $rcapRSS  = $rrss;
               $rcapCAP  = $rcap;
               $rcapOVER = $rpg;
	       $rcapRSS = &deh($rcapRSS);
	       $rcapCAP = &deh($rcapCAP);
             }
         }
        } else {
          # memory_cap:(zoneid):(zonenames first 30 chars):key
          my $shortname = substr($zoneName,0,30);
          my $VM =  ${Kstat}->{memory_cap}->{$zoneId}->{$shortname}->{swap};
          my $RSS = ${Kstat}->{memory_cap}->{$zoneId}->{$shortname}->{rss};
          my $CAP = ${Kstat}->{memory_cap}->{$zoneId}->{$shortname}->{physcap};
          my $OVER = ${Kstat}->{memory_cap}->{$zoneId}->{$shortname}->{nover};
          $rcapVM  = $VM;
          $rcapRSS = $RSS;
          $rcapCAP = $CAP;
          $rcapOVER = $OVER;
        }



        #print(" >> ZONE ${zoneName}   - CPU: ${cpuUsage} / ${cpuValue} | RSS: ${rcapRSS} / ${rcapCAP} | VM: ${swapUsage} / ${swapLimit} \n");
	#next();

	### UPDATE GRAPH DATA:
	## For CPU
	#print(" Upading  ${DATA_PATH}/caps-${zoneName}.rrd with: N:${cpuUsage}:${cpuValue}:${rcapRSS}:${rcapCAP}:${swapUsage}:${swapLimit}\n");
	`/opt/jtk/bin/rrdtool update ${DATA_PATH}/caps-${zoneName}.rrd "N:${cpuUsage}:${cpuValue}:${rcapRSS}:${rcapCAP}:${swapUsage}:${swapLimit}"`;

	### UPDATE GRAPH IMAGE:
	&output_graph($zoneName);

}



### SUB:

## De- Human Readable (-h) values; from K, M, G to bytes
sub deh($)
{
	my $hvalue = shift;
	my $bvalue = 0;

	if ( $hvalue =~ m/K/ ) {
		$hvalue =~ s/K//;
		$bvalue = $hvalue * 1024;
	} elsif ($hvalue =~ m/M/ ) {
		$hvalue =~ s/M//;
		$bvalue = $hvalue * 1048576;
	} elsif ($hvalue =~ m/G/ ) {
		$hvalue =~ s/G//;
		$bvalue = $hvalue * 1073741824;
	}  else {
		print("ERROR: Could not de-humanize value $hvalue\n");
	} 
	
	return($bvalue);	

}

sub check_rrd($)
{
        my $zone = shift();

        if ( -e "${DATA_PATH}/caps-${zone}.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
              	`/opt/jtk/bin/rrdtool create ${DATA_PATH}/caps-${zone}.rrd --start N --step 300 DS:cpu:GAUGE:600:U:U  DS:cpucap:GAUGE:600:U:U DS:rss:GAUGE:600:U:U DS:rsscap:GAUGE:600:U:U DS:vm:GAUGE:600:U:U DS:vmcap:GAUGE:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph($)
{
	my $zone = shift();

	## GRAPH CPU - 1 Day
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-cpu-${zone}.png -a PNG --title="${zone} CPU Usage" 'DEF:cpu=${DATA_PATH}/caps-${zone}.rrd:cpu:AVERAGE' 'DEF:cpucap=${DATA_PATH}/caps-${zone}.rrd:cpucap:AVERAGE' 'AREA:cpucap#e0e0e0:CPU Cap' 'LINE1:cpu#ff0000:Used'`;
	## GRAPH CPU - 5 Day
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-cpu-${zone}-5d.png -a PNG --start "-5d" --step 600 --title="${zone} CPU Usage" 'DEF:cpu=${DATA_PATH}/caps-${zone}.rrd:cpu:AVERAGE' 'DEF:cpucap=${DATA_PATH}/caps-${zone}.rrd:cpucap:AVERAGE' 'AREA:cpucap#e0e0e0:CPU Cap' 'LINE1:cpu#ff0000:Used'`;
	## GRAPH CPU - 30 Day
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-cpu-${zone}-30d.png -a PNG --start "-30d" --step 3600 --title="${zone} CPU Usage" 'DEF:cpu=${DATA_PATH}/caps-${zone}.rrd:cpu:AVERAGE' 'DEF:cpucap=${DATA_PATH}/caps-${zone}.rrd:cpucap:AVERAGE' 'AREA:cpucap#e0e0e0:CPU Cap' 'LINE1:cpu#ff0000:Used'`;

	## GRAPH MEM (RSS&VM Together) - 1 Day
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-mem-${zone}.png -a PNG --title="${zone} Memory Usage" -b 1024 --vertical-label="Bytes" 'DEF:rss=${DATA_PATH}/caps-${zone}.rrd:rss:AVERAGE' 'DEF:rsscap=${DATA_PATH}/caps-${zone}.rrd:rsscap:AVERAGE'   'DEF:vm=${DATA_PATH}/caps-${zone}.rrd:vm:AVERAGE' 'DEF:vmcap=${DATA_PATH}/caps-${zone}.rrd:vmcap:AVERAGE' 'AREA:vmcap#e0e0e0:VM (Swap) Cap' 'AREA:rsscap#c7c7ff:RSS Cap'  'LINE1:vm#000000:VM (Swap) Used' 'LINE1:rss#0000ff:RSS Used'`;
	## GRAPH MEM (RSS&VM Together) - 5 Day
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-mem-${zone}-5d.png -a PNG --start "-5d" --step 600 --title="${zone} Memory Usage" -b 1024 --vertical-label="Bytes" 'DEF:rss=${DATA_PATH}/caps-${zone}.rrd:rss:AVERAGE' 'DEF:rsscap=${DATA_PATH}/caps-${zone}.rrd:rsscap:AVERAGE'   'DEF:vm=${DATA_PATH}/caps-${zone}.rrd:vm:AVERAGE' 'DEF:vmcap=${DATA_PATH}/caps-${zone}.rrd:vmcap:AVERAGE' 'AREA:vmcap#e0e0e0:VM (Swap) Cap' 'AREA:rsscap#c7c7ff:RSS Cap'  'LINE1:vm#000000:VM (Swap) Used' 'LINE1:rss#0000ff:RSS Used'`;
	## GRAPH MEM (RSS&VM Together) - 30 Day
	`/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-mem-${zone}-30d.png -a PNG --start "-30d" --step 3600 --title="${zone} Memory Usage" -b 1024 --vertical-label="Bytes" 'DEF:rss=${DATA_PATH}/caps-${zone}.rrd:rss:AVERAGE' 'DEF:rsscap=${DATA_PATH}/caps-${zone}.rrd:rsscap:AVERAGE'   'DEF:vm=${DATA_PATH}/caps-${zone}.rrd:vm:AVERAGE' 'DEF:vmcap=${DATA_PATH}/caps-${zone}.rrd:vmcap:AVERAGE' 'AREA:vmcap#e0e0e0:VM (Swap) Cap' 'AREA:rsscap#c7c7ff:RSS Cap'  'LINE1:vm#000000:VM (Swap) Used' 'LINE1:rss#0000ff:RSS Used'`;


}


