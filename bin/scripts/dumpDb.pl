#!/usr/bin/perl -w
use strict;

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;


=head2

    NAME		dumpDb
    
    PURPOSE
	
		DUMP ALL THE TABLES IN A DATABASE TO .TSV FILES

    INPUT
	
		1. DATABASE NAME
		
		2. LOCATION TO PRINT .TSV FILES

    OUTPUT
	
		1. ONE .TSV FILE FOR EACH TABLE IN DATABASE

    USAGE
	
		./dumpDb.pl <--db String> <--outputdir String> [-h] 

    --db          :   Name of database
    --outputdir   :   Location of output directory
    --help        :   print this help message

	< option > denotes REQUIRED argument
	[ option ] denotes OPTIONAL argument

    EXAMPLE

perl dumpDb.pl --db agua --outputdir /agua/0.6/bin/sql/dump

=cut

#### TIME
my $time = time();

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### INTERNAL MODULES
use Agua::Configure;
use Agua::DBaseFactory;
use Timer;
use Util;
use Conf::Yaml;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use File::Copy;
use Getopt::Long;

#### GET OPTIONS
my $db;
my $dumpfile;
my $outputdir;	
my $help;
GetOptions (
	'db=s' => \$db,
	'dumpfile=s' => \$dumpfile,
	'outputdir=s' => \$outputdir,
	'help' => \$help) or die "No options specified. Try '--help'\n";
if ( defined $help )	{	usage();	}

#### FLUSH BUFFER
$| =1;

#### CHECK INPUTS
die "Database not defined (option --db)\n" if not defined $db;
die "Output directory not defined (option --outputdir)\n" if not defined $outputdir; 
die "File with same name as output directory already exists: $outputdir\n" if -f $outputdir;

#### CREATE OUTPUT DIRECTORY
File::Path::mkpath($outputdir) if not -d $outputdir;
die "Can't create output directory: $outputdir\n" if not -d $outputdir;

#### SET LOG
my $logfile = "/tmp/dumpdb.log";
my $SHOWLOG 	= 	2;
my $PRINTLOG 	= 	5;

#### GET CONF
my $configfile = "$Bin/../../conf/config.yaml";
my $conf = Conf::Yaml->new({
	inputfile 	=> $configfile,
	logfile		=>	$logfile,
	SHOWLOG		=>	2,
	PRINTLOG	=>	5
});

#### GET DATABASE INFO
my $dbtype = $conf->getKey("database", 'DBTYPE');
my $database = $conf->getKey("database", 'DATABASE');
my $user = $conf->getKey("database", 'USER');
my $password = $conf->getKey("database", 'PASSWORD');
print "dumpDb.pl    dbtype: $dbtype\n" if $DEBUG;
print "dumpDb.pl    user: $user\n" if $DEBUG;
print "dumpDb.pl    password: $password\n" if $DEBUG;
print "dumpDb.pl    database: $database\n" if $DEBUG;

#### CREATE OUTPUT DIRECTORY
File::Path::mkpath($outputdir) if not -d $outputdir;
die "Can't create output directory: $outputdir\n" if not -d $outputdir;

my $object = Agua::Configure->new({
	conf		=>	$conf,
	database	=>	$db,
	configfile	=>	$configfile,
	logfile		=>	$logfile,
	SHOWLOG		=>	$SHOWLOG,
	PRINTLOG	=>	$PRINTLOG
});

$object->setDbh();
my $timestamp = $object->_getTimestamp($database, $user, $password);
$timestamp =~ s/:/-/g;
$dumpfile = "$outputdir/$db.$timestamp.dump" if not defined $dumpfile;
$object->_dumpDb($database, $user, $password, $dumpfile);
print "dumpfile:\n\n$dumpfile\n\n";

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\n";
print "dumpDb.pl    Run time: $runtime\n";
print "dumpDb.pl    Completed $0\n";
print Util::datetime(), "\n";
print "dumpDb.pl    ****************************************\n\n\n";
exit;

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#									SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
    print `perldoc $0`;
	exit;
}
