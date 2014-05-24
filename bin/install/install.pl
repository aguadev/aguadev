#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     install

PURPOSE

    1. INSTALL THE DEPENDENCIES FOR Agua
    
    2. CREATE THE REQUIRED DIRECTORY STRUCTURE
    
INPUT

    1. INSTALLATION DIRECTORY (DEFAULT: /agua)
    
    2. www DIRECTORY (DEFAULT: /var/www)
        
OUTPUT

    1. REQUIRED DIRECTORY STRUCTURE AND PERMISSIONS
    
        FOR PROPER RUNNING OF Agua
        
    2. RUNNING APACHE INSTALLATION CONFIGURED FOR Agua
    
    3. RUNNING MYSQL INSTALLATION AWAITING MYSQL DATABASE
    
        CONFIGURATION WITH CONFIG

USAGE

sudo ./install.pl \
 [--mode String] \
 [--installdir String] \
 [--apachedir String] \
 [--userdir String] \
 [--wwwdir String] \
 [--wwwuser String] \
 [--domainname String] \
 [--logfile String] \
 [--newlog] \
 [--log ] \ 
 [--printlog ] \ 
 [--help]

 --mode          :  Installation option
	upgrade 		- 	Link directories and set permissions
	installApache	-	Install Apache2 and its dependencies
	enableHttps		-	Enable HTTPS and generate CA certificate
	installExchange	-	Install node.js and rabbitmq exchange
	enableReboot	-	Fix /etc/fstab to enable reboot of m1.micro instance
	installEc2		-	Install AWS ec2-api-tools
	installR		-	Install R statistical package
	installMysql	-	Install MySQL 5
	linkDirectories	-	Create required links for Agua 
	setPermissions	-	Set required permissions for Agua
	setStartup		-	Set Agua startup script
 --installdir    :  Target directory to install repository to (e.g., 1.2.0)
 --urlprefix     :  Prefix to URL (e.g., http://myhost.com/URLPREFIX/agua.html)
                    (default: agua)
 --userdir       :  Path to users home directory (default: /nethome)
 --wwwdir        :  Path to 'WWW' directory (default: /var/www)
 --wwwuser       :  Name of apache user (default: "www-data")
 --apachedir     :  Path to apache installation (default: /etc/apache2)
 --domainname    :  Domain name to use for CA certificate
 --logfile       :  Print log to this file
 --newlog        :  Flag to create new log file and backup old
 --log       :  Print log output to STDOUT (5 levels of increasing info: 1,2,3,4,5, default: 2, 'warning' and 'critical' info only)
 --printlog      :  Print log output to logfile (5 levels of increasing info: 1,2,3,4,5, default: 5, all log output) 
 --help          :  Print help info
 
EXAMPLES

# Install Agua (Agua files are located in the default /agua directory)
sudo install.pl --mode installBioApps

# Install Agua (Agua files are located in /aguadev directory)
sudo install.pl --mode installBioApps --installdir /aguadev

# Install BioApps package into Agua (Agua files are located in default /agua directory)
sudo install.pl --mode installBioApps

# Install BioApps package into Agua (Agua files are located in /aguadev directory)
sudo install.pl --mode installBioApps --installdir /aguadev

=cut


#### FLUSH BUFFER
$| = 1;

my $whoami = `whoami`;
if ( not $whoami =~/^root\s*$/ ) {
	print "You must be root to run config.pl\n";
	exit;
}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use lib "$Bin/../../lib/external/lib/perl5";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Agua::Install;

#### GET OPTIONS
my $mode        = 	"install";
my $urlprefix   = 	"agua";
my $installdir  = 	"$Bin/../..";
my $userdir     = 	"/nethome";
my $apachedir   = 	"/etc/apache2";
my $wwwdir      = 	"/var/www";
my $wwwuser     = 	"www-data";
my $logfile     = 	"/tmp/agua-install.log";
my $tempdir		=	"/tmp";
my $database;
my $domainname;
my $newlog;
my $log		=	2;
my $printlog	=	5;
my $help;
GetOptions (
    'mode=s'        =>  \$mode,
    'urlprefix=s'   =>  \$urlprefix,
    'installdir=s'  =>  \$installdir,
    'database=s'    =>  \$database,
    'apachedir=s'   =>  \$apachedir,
    'domainname=s'  =>  \$domainname,
    'userdir=s'     =>  \$userdir,
    'wwwdir=s'      =>  \$wwwdir,
    'wwwuser=s'     =>  \$wwwuser,
    'logfile=s'     =>  \$logfile,
    'tempdir=s'     =>  \$tempdir,
    'newlog=s'      =>  \$newlog,
    'log=s'     =>  \$log,
    'printlog=s'    =>  \$printlog,
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

#### CHECK IF URL PREFIX EXISTS
my $urlprefixpath = "$wwwdir/$urlprefix";
print "install.pl    urlprefix directory already exists: $urlprefix\n" and exit if -d $urlprefixpath;

my $object = Agua::Install->new(
    {
        urlprefix   =>  $urlprefix,
        installdir  =>  $installdir,
        database    =>  $database,
        apachedir   =>  $apachedir,
        domainname  =>  $domainname,
        userdir     =>  $userdir,
        wwwdir      =>  $wwwdir,
        wwwuser     =>  $wwwuser,
        logfile     =>  $logfile,
        tempdir     =>  $tempdir,
        newlog      =>  $newlog,
        log			=>	$log,
		printlog    =>  $printlog
    }
);

#### RUN QUERY
no strict;
eval { $object->$mode() };
if ( $@ ){
	print "Error: $mode): $@\n";
}
print "\nCompleted $0\n";


sub usage {
    print `perldoc $0`;
    exit;
}
    
