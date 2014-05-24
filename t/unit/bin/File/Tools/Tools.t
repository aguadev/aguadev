#!/usr/bin/perl -w

=head2

    TEST            Tools.t
    
    PURPOSE
    
		TEST File::Tools MODULE, WHICH PERFORMS BASIC FILE CHECKING AND
        
        MANIPULATION TASKS, SUCH AS:

			1. svn TOOLS - BACKUP/MIRROR WITH AUTO DELETE/ADD
			
			2. comment TOOLS - ADD/REMOVE/COMMENT DEBUG LINES IN PERL AND JS FILES
			
			3. NEXTGEN INPUT FILE QUALITY CHECKS

=cut

use strict;

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
use Test::File::Tools;
use Conf::Yaml;

my $logfile = "$Bin/outputs/testuser.filetools.log";
my $log = 2;
my $printlog = 2;

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
	log			=>	$log,
	printlog    =>  $printlog	
);

my $filetool = Test::File::Tools->new({
    logfile     =>  $logfile,
	log			=>	$log,
	printlog    =>  $printlog,
    conf        =>  $conf
});

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More;

plan 'skip_all' => "Onworking File::Tools tests";


