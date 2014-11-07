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

	my $PHYS = 1048576 * get_physmem();
	my $ARC  = 1048576 * get_arcSize();
	my $KERX = 1048576 * get_kernelSize();
	my $FREE = 1048576 * get_freeMem();
	my $KERN = $KERX - $ARC;
	my $USED = $PHYS - $FREE;
	my $USER = $PHYS - $ARC - $KERN - $FREE;
	my $TOTAL    = $PHYS;

if ( $DEBUG ) {
print <<DEBUG;
 -- DEBUG DEBUG DEBUG DEBUG --

 Physical: 	$TOTAL
 Kernel:        $KERN
 ZFS ARC: 	$ARC
 User:          $USER

 Used:          $USED
 Free:          $FREE

 -- DEBUG DEBUG DEBUG DEBUG --
DEBUG
	exit(1);
} 



        ### RRD Update

        #print("RRD Update: N:${KERN}:${ARC}:${USER}:${USED}:${FREE}:${TOTAL} \n");
        `/opt/jtk/bin/rrdtool update /opt/jtk/data/memory.rrd "N:${KERN}:${ARC}:${USER}:${USED}:${FREE}:${TOTAL}"`;

        &output_graph();

        exit(0);





######################################################################################
############# SUBROUTINES                                                       ######
######################################################################################

sub check_rrd()
{

        if ( -e "${DATA_PATH}/memory.rrd" ) {
                ##print("File exists.\n");
                return();
        } else {
                print("RRD Does not exist, creating.\n");
                `/opt/jtk/bin/rrdtool create ${DATA_PATH}/memory.rrd --start N --step 300 DS:KERN:GAUGE:600:U:U DS:ARC:GAUGE:600:U:U DS:USER:GAUGE:600:U:U DS:USED:GAUGE:600:U:U DS:FREE:GAUGE:600:U:U DS:TOTAL:GAUGE:600:U:U RRA:MIN:0.5:1:8640 RRA:MAX:0.5:12:8640 RRA:AVERAGE:0.5:1:8640`;
        }

}


sub output_graph()
{

        ## Output graph
	my $UPPER_LIMIT = $TOTAL * 1.2;
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/mem.png -a PNG --title="$HOSTNAME Physical Memory" --width 350 --rigid -l 0 -u $UPPER_LIMIT  'DEF:KERN=${DATA_PATH}/memory.rrd:KERN:AVERAGE' 'DEF:ARC=${DATA_PATH}/memory.rrd:ARC:AVERAGE' 'DEF:USER=${DATA_PATH}/memory.rrd:USER:AVERAGE' 'DEF:USED=${DATA_PATH}/memory.rrd:USED:AVERAGE' 'DEF:FREE=${DATA_PATH}/memory.rrd:FREE:AVERAGE' 'DEF:TOTAL=${DATA_PATH}/memory.rrd:TOTAL:AVERAGE' 'AREA:TOTAL#8ec6ff:Total Memory' 'AREA:USED#96ff8e:Used Memory' 'AREA:KERN#000000:Kernel Memory' 'AREA:ARC#ff0000:ZFS ARC:STACK' `;
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/mem-5d.png -a PNG --title="$HOSTNAME Physical Memory" --start "-5d" --step 600 --width 350 --rigid -l 0 -u $UPPER_LIMIT  'DEF:KERN=${DATA_PATH}/memory.rrd:KERN:AVERAGE' 'DEF:ARC=${DATA_PATH}/memory.rrd:ARC:AVERAGE' 'DEF:USER=${DATA_PATH}/memory.rrd:USER:AVERAGE' 'DEF:USED=${DATA_PATH}/memory.rrd:USED:AVERAGE' 'DEF:FREE=${DATA_PATH}/memory.rrd:FREE:AVERAGE' 'DEF:TOTAL=${DATA_PATH}/memory.rrd:TOTAL:AVERAGE' 'AREA:TOTAL#8ec6ff:Total Memory' 'AREA:USED#96ff8e:Used Memory' 'AREA:KERN#000000:Kernel Memory' 'AREA:ARC#ff0000:ZFS ARC:STACK' `;
        `/opt/jtk/bin/rrdtool graph ${GRAPH_PATH}/mem-30d.png -a PNG --title="$HOSTNAME Physical Memory" --start "-30d" --step 3600 --width 350 --rigid -l 0 -u $UPPER_LIMIT  'DEF:KERN=${DATA_PATH}/memory.rrd:KERN:AVERAGE' 'DEF:ARC=${DATA_PATH}/memory.rrd:ARC:AVERAGE' 'DEF:USER=${DATA_PATH}/memory.rrd:USER:AVERAGE' 'DEF:USED=${DATA_PATH}/memory.rrd:USED:AVERAGE' 'DEF:FREE=${DATA_PATH}/memory.rrd:FREE:AVERAGE' 'DEF:TOTAL=${DATA_PATH}/memory.rrd:TOTAL:AVERAGE' 'AREA:TOTAL#8ec6ff:Total Memory' 'AREA:USED#96ff8e:Used Memory' 'AREA:KERN#000000:Kernel Memory' 'AREA:ARC#ff0000:ZFS ARC:STACK' `;


}




#
# Totals up RSS for each process, via ps (Memory Resident) Returns in MB
#
sub get_userRSS()
{
        my @procRSS = `/usr/bin/ps -e -o rss`;
        my $userRSS = 0;
        foreach ( @procRSS ) {
                chomp($_);
                $userRSS = $userRSS + $_;      
        }
        return($userRSS /1024);
}


#
# Totals up VSZ for each process, via ps (Virtual Size) Returns in MB
#
sub get_userVM()
{
        my @procVM  = `/usr/bin/ps -e -o vsz`;
        my $userVM  = 0;
        foreach ( @procVM ) {
                chomp($_);
                $userVM = $userVM + $_;
        }

        return($userVM /1024);
}

sub get_kernelSize()
{

        my $ppkernel = ${Kstat}->{unix}->{0}->{system_pages}->{pp_kernel};
        my $kernelsz = $ppkernel * $pagesize;   ## Kernel size in bytes

        return( $kernelsz / 1048576 );          ## Return kernel size in MB
}

sub get_physmem()
{
        my $physpg = ${Kstat}->{unix}->{0}->{system_pages}->{physmem};
        my $phys   = $physpg * $pagesize;

        return( $phys / 1048576 );
}

sub get_arcSize()
{
        my $arcsz = ${Kstat}->{zfs}->{0}->{arcstats}->{size};

        return ( $arcsz / 1048576 );    ## Return in MB
}


sub get_freeMem()
{
        my $freepg = ${Kstat}->{unix}->{0}->{system_pages}->{pagesfree};
        my $free   = $freepg * $pagesize;

        return ( $free / 1048576 );
}


