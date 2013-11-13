#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     install

PURPOSE:

    1. AUTOMATICALLY CREATE A CA CERTIFICATE:
    
        -   QUIT IF FLAG FILE IS PRESENT
        
        -   FAIL IF CAN'T CREATE FLAG FILE

            -   FLAG FILE IS INSIDE conf DIRECTORY (WRITABLE ONLY BY ROOT)

        -   OTHERWISE, GENERATE CA CERTIFICATE 
    
INPUT

    1. INSTALLATION DIRECTORY (DEFAULT: /agua)
    
    2. APACHE DIRECTORY (DEFAULT: /etc/apache2)

    3. (OPTIONAL) DOMAIN NAME, E.G. www.mydomain.com
    
    4. (OPTIONAL) LOG FILE
    
    5. REQUIRED: WORKING INSTALLATION OF APACHE2
    
OUTPUT

    1. RUNNING HTTPS INSTALLATION
    
USAGE

    sudo ./createCert.pl <--installdir String> [--apachedir String] [--domainname String] [--help]
    
    --installdir       :   Path to Agua install directory (default: /agua)
    --apachedir        :   Path to apache2 installation (default: /etc/apache2)
    --domainname       :   Optional domain name (e.g., www.mydomain.com)
    --help             :   Print help info

EXAMPLES

sudo createCert.pl --installdir /path/to/installdir 

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Agua::Installer;

#### GET OPTIONS
my $installdir = "/agua";
my $domainname;
my $apachedir = "/etc/apache2";
my $logfile = "$Bin/../../createcert.log";
my $help;
GetOptions (
    'installdir=s'  => \$installdir,
    'apachedir=s'   => \$apachedir,
    'domainname=s'  => \$domainname,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

my $installer = Agua::Installer->new(
    {
        installdir  =>  $installdir,
        domainname  =>  $domainname,
        logfile     =>  $logfile
    }
);
$installer->openLogfile();

#### QUIT IF FLAG FILE FOUND
my $flagfile = "$Bin/../../conf/.https/CA_CERT_INSTALLED";
my $date = `date`;
$date =~ s/\s+$//;
if ( -f $flagfile ) {
    print "$date\tflagfile found. Quitting\n";
    exit;
}

#### OTHERWISE, CREATE FLAG FILE
`echo $date > $flagfile`;

print "$date\n";
print "createCert.pl    installdir: $installdir\n";
print "createCert.pl    logfile: $logfile\n";
print "createCert.pl    domainname: $domainname\n" if defined $domainname;

$installer->enableHttps();
print "Completed $0\n";


sub usage {
    print `perldoc $0`;
}
    
