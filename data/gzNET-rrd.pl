#!/usr/perl5/bin/perl

## --benr Based on jnetstat


use strict;
use Sun::Solaris::Kstat;

my $DATA_PATH = "/opt/jtk/data";
my $GRAPH_PATH = "/opt/jtk/www/graphs";
my $HOSTNAME = `hostname`;
chomp($HOSTNAME);

my $Kstat = Sun::Solaris::Kstat->new();

######################################################################################
############# MAIN								######
######################################################################################
	

	my @links; 

	my @physLinks = `/usr/sbin/dladm show-phys -p -o LINK,STATE,DEVICE`;
	foreach(@physLinks) {
		my ($link,$state,$dev) = split(/:/, $_);
		next if ($state ne "up"); 

		&check_rrd($link);
		# print("Pushing $link\n");
		push(@links, $link);

                my $interface = $link;
                my $instance = $link;

		if ($interface =~ m/^e1000g/ ) {
			$interface = "e1000g";
			$instance =~ s/^e1000g//;
		} else {
                	$interface =~ s/\d+//;
                	$instance =~ s/[a-z]+//;
		}

		my $speed    = ${Kstat}->{$interface}->{$instance}->{mac}->{ifspeed} / 8;
		my $bytesIn  = ${Kstat}->{$interface}->{$instance}->{mac}->{rbytes64};
		my $bytesOut = ${Kstat}->{$interface}->{$instance}->{mac}->{obytes64};

		my $bitsIn   = $bytesIn * 8;	
		my $bitsOut  = $bytesOut * 8;	
		
		`/opt/jtk/bin/rrdtool update /opt/jtk/data/${link}.rrd "N:${bitsIn}:${bitsOut}"`;
		
	}		




	&output_graph(@links);

	exit(0);





######################################################################################
############# SUBROUTINES							######
######################################################################################

sub check_rrd($)
{
	my $link = shift;

        if ( -e "${DATA_PATH}/${link}.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
                `/opt/jtk/bin/rrdtool create ${DATA_PATH}/${link}.rrd --start N --step 300 DS:bits-in:COUNTER:600:U:U DS:bits-out:COUNTER:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph(@)
{
	my $links = @_;
	#my @colors = qw(0000b3 0037c6 0056c1 006fbf 0087c3 009bc6 00b3c9 00b2ab 00bf8d 00bb6c 00c463 00c324 00c100 14c300 54b900 7fc300 9ac200 bbc800 ffc000 e29500 ce7100 c85a00 c03901 bd1502 c60404 b82636 ba0a5d b8006a be007e b5009c ba00ba 9310ba 7000ba 5900ba 5800ed 3e00e7 0000b3);
	my @colors = qw(0000b3 0037c6 00b3c9 00b2ab 00bf8d 14c300 54b900 ffc000 e29500 ce7100 c85a00 c03901 bd1502 c60404 b82636 ba0a5d b8006a be007e b5009c ba00ba 9310ba 7000ba 5900ba 5800ed 3e00e7 0000b3);

	my $fivedayprefix = "/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/net.png -a PNG --start \"-5d\" --step 600 --title=\"$HOSTNAME Network\" --vertical-label \"Bits\" --watermark \"+Joyent Operations\"  ";
	my $thirtydayprefix = "/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/net-30d.png -a PNG --start \"-30d\" --step 3600 --title=\"$HOSTNAME Network\" --vertical-label \"Bits\" --watermark \"+Joyent Operations\" ";

	#my $defs;
	#my $lines;
	#my $draws;
	my $mush;

	foreach my $link (@links) {
		my $color1 = shift(@colors);
		my $color2 = shift(@colors);
		
		my $a1  = " \'DEF:${link}in=${DATA_PATH}/${link}.rrd:bits-in:AVERAGE\' ";
		my $b1 = " \'LINE1:${link}in#${color1}:${link} In \' ";
		my $c1 = " \'GPRINT:${link}in:MIN:min\\: %5.2lf %s\' \'GPRINT:${link}in:MAX:max\\: %5.2lf %s\' \'GPRINT:${link}in:LAST:last\\: %5.2lf %s\\j\' ";
		
		$mush .= "$a1 $b1 $c1 ";
	
		my $a2  = " \'DEF:${link}out=${DATA_PATH}/${link}.rrd:bits-out:AVERAGE\' ";
		my $b2 = " \'LINE1:${link}out#${color2}:${link} Out\' ";
		my $c2 = " \'GPRINT:${link}out:MIN:min\\: %5.2lf %s\' \'GPRINT:${link}out:MAX:max\\: %5.2lf %s\' \'GPRINT:${link}out:LAST:last\\: %5.2lf %s\\j\' ";

		$mush .= "$a2 $b2 $c2 ";

	}

	## Output graph
	`$fivedayprefix $mush`;
	`$thirtydayprefix $mush`;

}

