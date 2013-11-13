#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     doc

PURPOSE

    GENERATE PERLDOC-BASED WIKI MARKUP FOR APPLICATIONS AND MODULES
    
INPUT

    1. bin DIRECTORY LOCATION
    
    2. LOCATION OF OUTPUT DIRECTORY FOR DOCUMENTATION FILES
    
    
OUTPUT

    ONE DOCUMENTATION FILE FOR EACH *.pl APPLICATION IN NESTED
    
    SUBDIRS MIRRORING THE bin DIRECTORY

USAGE

sudo ./doc.pl <--inputdir String> <--outputdir String> [--help]

--name      :   Name of application

--inputdir   :	Name of inputdir where the .git directory is located

--outputdir :	Create packages inside RELEASE dir in the outputdir

--help      :   Print help info


EXAMPLES

./doc.pl \
 --inputdir /agua/0.6/bin \
 --outputdir /agua/0.6/docs/bin

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);

use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Doc;

#### GET OPTIONS
my $inputdir;
my $outputdir;
my $prefix = '';
my $help;
GetOptions (
    'inputdir=s'    => \$inputdir,
    'outputdir=s'   => \$outputdir,
    'prefix=s'    => \$prefix,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### SET LOG
my $logfile     = "/tmp/doc.log";
my $SHOWLOG     =   5;
my $PRINTLOG    =   5;

#### CHECK INPUTS
print "doc.pl    inputdir not defined\n" and exit if not defined $inputdir;
print "doc.pl    outputdir not defined\n" and exit if not defined $outputdir;

my $object = new Doc({
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
});
$object->docToWiki($inputdir, $outputdir, $prefix);

