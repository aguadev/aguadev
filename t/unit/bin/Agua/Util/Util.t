#!/usr/bin/perl -w

use Test::More;
plan skip_all => 'Onworking Agua::Common::Util tests';

use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

use Test::Agua::Util;

my $SHOWLOG 	=	2;
my $PRINTLOG 	=	5;
my $logfile = "/tmp/testuser.util.log";
my $object = Test::Agua::Util->new(
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
);

#Completed running plugin: sge.CreateCell
$object->testFileTail($Bin);

