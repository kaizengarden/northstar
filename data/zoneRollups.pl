#!/usr/perl5/bin/perl

##
## Northstar ZoneView Rollup Graph Creation
##

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";


my @colors = qw(0000b3 0037c6 0056c1 006fbf 0087c3 009bc6 00b3c9 00b2ab 00bf8d 00bb6c 00c463 00c324 00c100 14c300 54b900 7fc300 9ac200 bbc800 ffc000 e29500 ce7100 c85a00 c03901 bd1502 c60404 b82636 ba0a5d b8006a be007e b5009c ba00ba 9310ba 7000ba 5900ba 5800ed 3e00e7 0000b3);
my $color_count = @colors;


my $mem_defs, $cpu_defs, $io_defs;
my $mem_draws, $cpu_defs, $io_defs;
my $mem_math, $cpu_math, $io_math;

my @zonelist = `zoneadm list -p | grep -v global | cut -d: -f2`;
my $zone_count = @zonelist;

## Avoid a lack of colors or a division error:
if ( $zone_count == 0 ) {
	exit;
} elsif ( $zone_count > $color_count ) {
	
	while ($zone_count > $color_count) {
		push(@colors, qw(0000b3 0037c6 0056c1 006fbf 0087c3 009bc6 00b3c9 00b2ab 00bf8d 00bb6c 00c463 00c324 00c100 14c300 54b900 7fc300 9ac200 bbc800 ffc000 e29500 ce7100 c85a00 c03901 bd1502 c60404 b82636 ba0a5d b8006a be007e b5009c ba00ba 9310ba 7000ba 5900ba 5800ed 3e00e7 0000b3));
		$color_count = @colors;
	}
} 

$color_stride = $color_count / $zone_count; 


## Main Loop
foreach $x (@zonelist){
	chomp($x);
	my $color;

	$color = @colors[0];
	for ( my $v = 1; $v < $color_stride; $v++ ) {
		shift(@colors);	 
	}

	### Generate parameters for RSS
	$mem_defs  .= " \'DEF:${x}rss=${DATA_PATH}/caps-${x}.rrd:rss:AVERAGE\'";
	$mem_math  .= " \'CDEF:${x}rssG=${x}rss,1073741824,/\'";
	$mem_draws .= " \'AREA:${x}rss#${color}:${x}  :STACK\'";
	$mem_draws .= " \'GPRINT:${x}rssG:MIN:min\\: %2.1lf G \l \'";
	$mem_draws .= " \'GPRINT:${x}rssG:MAX:max\\: %2.1lf G \l \'";
	$mem_draws .= " \'GPRINT:${x}rssG:LAST:last\\: %2.1lf G \l \'";

	### Generate parameters for CPU
	$cpu_defs  .= " \'DEF:${x}cpu=${DATA_PATH}/caps-${x}.rrd:cpu:AVERAGE\'";
	$cpu_draws .= " \'AREA:${x}cpu#${color}:${x} :STACK\'";
	$cpu_draws .= " \'GPRINT:${x}cpu:MIN:min\\: %4.0lf %s \'";
	$cpu_draws .= " \'GPRINT:${x}cpu:MAX:max\\: %4.0lf %s \'";
	$cpu_draws .= " \'GPRINT:${x}cpu:LAST:last\\: %4.0lf %s \'";

	### Generate parameters for IO
	$read_defs  .= " \'DEF:${x}rd=${DATA_PATH}/zfsrw-${x}.rrd:read_bytes:AVERAGE\'";
	$read_draws .= " \'AREA:${x}rd#${color}:${x} :STACK\'";
	$read_draws .= " \'GPRINT:${x}rd:MIN:min\\: %5.2lf %s \'";
	$read_draws .= " \'GPRINT:${x}rd:MAX:max\\: %5.2lf %s \'";
	$read_draws .= " \'GPRINT:${x}rd:LAST:last\\: %5.2lf %s \'";

	$write_defs  .= " \'DEF:${x}wr=${DATA_PATH}/zfsrw-${x}.rrd:write_bytes:AVERAGE\'";
	$write_draws .= " \'AREA:${x}wr#${color}:${x} :STACK\'";
	$write_draws .= " \'GPRINT:${x}wr:MIN:min\\: %5.2lf %s \'";
	$write_draws .= " \'GPRINT:${x}wr:MAX:max\\: %5.2lf %s \'";
	$write_draws .= " \'GPRINT:${x}wr:LAST:last\\: %5.2lf %s \'";

}


## Render the Memory Graph
$GRAPH_SETUP_MEM="/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-mem-rollup-5d.png -a PNG --start \"-5d\" --step 600 --title=\"RSS Memory Usage by Zone\" -b 1024 --vertical-label=\"Bytes\" --watermark \"+Joyent Operations\" ";
`$GRAPH_SETUP_MEM $mem_defs $mem_math $mem_draws`;

## Render the CPU Graph
$GRAPH_SETUP_CPU="/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/caps-cpu-rollup-5d.png -a PNG --start \"-5d\" --step 600 --title=\"CPU Usage by Zone\" -b 1024  --vertical-label=\"CPU Units\" --watermark \"+Joyent Operations\"  ";
`$GRAPH_SETUP_CPU $cpu_defs $cpu_math $cpu_draws`;

## Render the IO Graphs
$GRAPH_SETUP_CPU="/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zones-read-rollup-5d.png -a PNG --start \"-5d\" --step 600 --title=\"Read I/O by Zone\" -b 1024  --vertical-label=\"Bytes\" --watermark \"+Joyent Operations\"  ";
`$GRAPH_SETUP_CPU $read_defs $read_draws`;

$GRAPH_SETUP_CPU="/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/zones-write-rollup-5d.png -a PNG --start \"-5d\" --step 600 --title=\"Write I/O by Zone\" -b 1024  --vertical-label=\"Bytes\" --watermark \"+Joyent Operations\"  ";
`$GRAPH_SETUP_CPU $write_defs $write_draws`;
