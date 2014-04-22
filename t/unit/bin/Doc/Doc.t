#!/usr/bin/perl -w
use strict;

=head2

APPLICATION     doc

PURPOSE         TEST Doc.pm MODULE FOR GENERATING PERLDOC-BASED WIKI MARKUP FOR APPLICATIONS AND MODULES
    
INPUT

    1. bin DIRECTORY LOCATION
    
    2. LOCATION OF OUTPUT DIRECTORY FOR DOCUMENTATION FILES
    
    
OUTPUT

    ONE DOCUMENTATION FILE FOR EACH *.pl APPLICATION IN NESTED
    
    SUBDIRS MIRRORING THE bin DIRECTORY


USAGE		./Doc.t [Int --showlog] [Int --printlog]
                            [String logfile] [--help]

		--showlog		Displayed log level (1-5)	
		--printlog		Logfile log level (1-5)	
		--logfile		Location of logfile
		--help			Show this message

=cut

use Test::More	tests => 2;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
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

#### SET LOG
my $logfile     = "$Bin/outputs/doc.log";


#### GET OPTIONS
my $showlog     =   2;
my $printlog    =   5;
my $help;
GetOptions (
    'showlog=i'     => \$showlog,
    'printlog=i'    => \$printlog,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### INTERNAL MODULES
use Test::Doc;

my $object = new Test::Doc({
    logfile     =>  $logfile,
    showlog     =>  $showlog,
    printlog    =>  $printlog,
    basedir     =>  $Bin
});

$object->testDocToWiki();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}
