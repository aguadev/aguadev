#!/usr/bin/perl -w
use strict;

=head2

APPLICATION     stager

PURPOSE

PACKAGE		Agua::Ops::Stager

PURPOSE

	A TOOL TO SIMPLIFY THE TASK OF STAGING FROM
	
	DEVEL --> PRODUCTION REPOSITORIES

	-   SIMPLE COMMAND TO STAGE ANY REPO
	
	-   ALLOW MULTILINE COMMIT MESSAGE

	-   stage.pm DOES FILE MANIPULATIONS, RENAMING, ETC.

	-   stage.conf (Agua::Conf FORMAT) STORES STAGE INFO

EXAMPLES

./stage.pl \
--version 0.8.0-alpha+build.1 \
--stagefile /repos/private/syoung/biorepodev/stage.pm \
--mode 1-2 \
--message "First line
(EMPTY LINE)
(EMPTY LINE)
Second line
Third line"

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Agua::Ops;

#### GET OPTIONS
my $branch          =   "master";
my $versionformat  =   "semver";
my $logfile 		= 	"/tmp/stager.log";
my $SHOWLOG     	=   2;
my $PRINTLOG    	=   5;
my $stagefile;
my $mode;
my $message;
my $version;
my $versiontype;
my $package;
my $outputdir;
my $releasename;
my $versionfile;
my $help;
GetOptions (

	#### REQUIRED
    'mode=s'            =>  \$mode,
    'stagefile=s'       =>  \$stagefile,
    'message=s'     	=>  \$message,

	#### EITHER OR
	'version=s'         =>  \$version,
    'versiontype=s'     =>  \$versiontype,

	#### DEBUG
    'SHOWLOG=s'         =>  \$SHOWLOG,
    'PRINTLOG=s'        =>  \$PRINTLOG,

	#### OPTIONAL
    'versionfile=s'     =>  \$versionfile,
    'versionformat=s'   =>  \$versionformat,
    'branch=s'          =>  \$branch,
    'outputdir=s'       =>  \$outputdir,
    'releasename=s'     =>  \$releasename,
    'logfile=s'         =>  \$logfile,
    'help'              =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "version.pl    bad mode format: $mode (example: N-N)\n" and exit if $mode !~ /^(\d+)-(\d+)$/;

print "version.pl    stagefile not defined\n" and exit if not defined $stagefile;
print "version.pl    message not defined\n" and exit if not defined $message;
print "version.pl    neither version nor versiontype are defined\n" and exit if not defined $version and not defined $versiontype;
print "version.pl    both version and versiontype are defined\n" and exit if defined $version and defined $versiontype;
print "version.pl    versiontype must be 'major'O, 'minor', 'patch' or 'build'\n" and exit if defined $versiontype and not $versiontype =~ /^(major|minor|patch|release|build)$/;
print "version.pl    releasename must be 'alpha', 'beta', or 'rc'\n" and exit if defined $releasename and not $releasename =~ /^(alpha|beta|rc)$/;


my $object = Agua::Ops->new({
    version     	=>  $version,
    versiontype     =>  $versiontype,
    versionfile     =>  $versionfile,
    versionformat   =>  $versionformat,
    branch          =>  $branch,
    package     	=>  $package,
    logfile         =>  $logfile,
    outputdir       =>  $outputdir,
    releasename     =>  $releasename,
    logfile     	=>   $logfile,
    SHOWLOG     	=>   $SHOWLOG,
    PRINTLOG   		=>   $PRINTLOG
});
$object->stageRepo($stagefile, $mode, $message);

######################## SUBROUTINES #####################

sub usage {
    print `perldoc $0`;
    exit;
}