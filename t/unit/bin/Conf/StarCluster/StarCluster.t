#!/usr/bin/perl -w

=head3 B<APPLICATION>     StarCluster.t
	
	PURPOSE

		DRIVE TESTS OF Conf::StarCluster

=cut

use strict;

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More qw(no_plan);
use Test::File::Contents;
use File::Compare;
use File::Copy "cp";
use FindBin qw($Bin);

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

#### INTERNAL MODULES
use Test::Conf::StarCluster;

#### FILES
my $logfile         =   "$Bin/outputs/agua.log";
my $originalfile    =   "$Bin/inputs/syoung-microcluster.config";
my $inputfile       =   "$Bin/outputs/syoung-microcluster.config";
my $emptyfile       =   "$Bin/inputs/syoung-microcluster-empty.config";
my $addedfile       =   "$Bin/inputs/syoung-microcluster-added.config";
my $removedfile     =   "$Bin/inputs/syoung-microcluster-removed.config";

### TEST CONF
my $object = Test::Conf::StarCluster->new(
    logfile     =>  $logfile,
	backup      =>	0,
    SHOWLOG     =>  2,
    PRINTLOG    =>  5
);

$object->testGetKey($originalfile, $inputfile);
$object->testSetKey($originalfile, $inputfile, $addedfile);
$object->testRemoveKey($originalfile, $inputfile, $removedfile);

#### CLEAN UP
`rm -fr $Bin/outputs/*`;

