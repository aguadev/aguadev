#!/usr/bin/perl -w

=head2

	APPLICATION 	download
	
	PURPOSE
	
		1. VERIFY USE ACCESS TO FILES OR PROJECT DATABASE ENTRIES
		
		2. SEND DOWNLOAD DATA STREAM TO CLIENT

	USAGE

		./download.pl <QUERY_STRING>

	EXAMPLES

./download.pl "mode=downloadFile&username=admin&sessionId=9999999999.9999.999&filepath=/nethome/admin/agua/Project1/Workflow1/stdout/3-elandIndex.stdout"

=cut

use strict;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/lib";
use Agua::Download;

#### EXTERNAL MODULES
use Data::Dumper;

#### GET INPUT
my $input = $ARGV[0];

#### SET LOG
my $SHOWLOG     =   0;
my $PRINTLOG    =   4;
my $logfile     =   "/tmp/agua-download.$$.log";

#### GET CONF
use Conf::Yaml;
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/conf/config.yaml",
	backup		=>	1,
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2
);

my $workflow = Agua::Download->new({
    conf		=>	$conf,
    input 		=>	$input,
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
});

my ($mode) = $input =~ /mode=([^&]+)/;
$mode = "downloadFile" if not defined $mode;

#### RUN QUERY
no strict;
my $result = $workflow->$mode();
use strict;

exit;



