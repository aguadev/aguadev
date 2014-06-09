#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     resetMaster

PURPOSE

    1. SET HEADNODE HOSTNAME TO LONG INTERNAL IP (AFTER REBOOT)

	2. IF HOSTNAME HAS CHANGED, UPDATE HOSTNAME IN CLUSTERS
	
		- REMOVE OLD HOSTNAME AS ADMIN/SUBMIT HOST
		
		- ADD NEW HOSTNAME AS ADMIN/SUBMIT HOST

USAGE

./resetMaster.pl <String cell> <String masterid> <String cgiscript> [--help]

	--cell		:   Name of SGE cell (also name of cluster)
	--masterid	:   EC2 ID of master node
	--cgiscript	:   Partial path to CGI script to be called by this script
	--help      :   Print help info

INPUT

	1. EC2 ID OF MASTER NODE TO BE UPDATED
	
	2. NAME OF CELL/CLUSTER TO WHICH MASTER NODE BELONGS

	3. PARTIAL PATH TO FIND CGI SCRIPT
	

OUTPUT
	
		RETURN A HASH OF INSTANCE VARIABLES:

			# INSTANCE INFO
			instanceid
			imageid
			longexternalip
			longinternalip
			status
			name
			instancetype
			launched
			availzone
			kernelid
			shortexternalip
			shortinternalip

			# SECURITY GROUP INFO
			reservationid
			amazonuserid
			securitygroup
		
			# BLOCK DEVICE KEYS [ARRAY]
			device
			volume
			attached

		E.G., EXAMPLE OUTPUT OF EC2 API 'ec2-describe-instances' COMMAND 
	
			RESERVATION     r-e30f5d89      558277860346    default
			INSTANCE        i-b42f3fd9      ami-90af5ef9    ec2-75-101-214-196.compute-1.amazonaws.com      ip-10-127-158-202.ec2.internal running aquarius        0               t1.micro        2010-12-24T09:51:37+0000        us-east-1a     aki-b51cf9dc    ari-b31cf9da            monitoring-disabled     75.101.214.196  10.127.158.202        ebs
			BLOCKDEVICE     /dev/sda1       vol-c6e346ae    2010-12-24T09:51:40.000Z
			BLOCKDEVICE     /dev/sdh        vol-266dc84e    2010-12-24T23:03:04.000Z
			BLOCKDEVICE     /dev/sdi        vol-fa6dc892    2010-12-24T23:05:50.000Z

EXAMPLES

resetMaster.pl --cell syoung-microcluster --masterid i-b34d25d2 --cgiscript "agua/0.6/reset.cgi"

=cut

#### FLUSH BUFFER
$| = 1;


my $logfile = "/tmp/agua.resetmaster.log";
print "resetMaster.pl     printing to logfile: $logfile\n" if $DEBUG;
open(STDOUT, ">$logfile") or die "Can't open logfile: $logfile\n";
open(STDERR, ">$logfile") or die "Can't open logfile: $logfile\n";

#### PRINT DATE
print "resetMaster.pl    Started: ";
print `date`;

#### SET EC2 HOME
$ENV{'EC2_HOME'} = '/usr/';

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;

#### GET OPTIONS
my $privatekey = "$Bin/private.pem";
my $publiccert = "$Bin/public.pem";
my $cell;
my $headnodeid;
my $cgiscript;
my $help;
GetOptions (
    'cell=s' 		=> \$cell,
    'headnodeid=s' 	=> \$headnodeid,
    'cgiscript=s' 	=> \$cgiscript,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";


#### GET HEADNODE URL
my $instanceinfo = getInstanceInfo($headnodeid, $privatekey, $publiccert);
my $url = $instanceinfo->{longexternalip};

#### GET MASTER INSTANCE ID
my $masterid = 	`curl -s http://169.254.169.254/latest/meta-data/instance-id`;

#### SET ARGS
my $args = {
	mode		=>	'resetMaster',
    cell 		=>	$cell,
    masterid 	=>	$masterid
};
print "resetMaster.pl    args: \n";
print Dumper $args;

#### CONVERT JSON TEXT TO OBJECT
use JSON;
my $jsonParser = JSON->new();
my $json = $jsonParser->allow_nonref->encode($args);
print "resetMaster.pl    json: $json\n";

my $ua = LWP::UserAgent->new;
my $address = "http://$url/$cgiscript";
print "resetMaster.pl    address: $address\n";

my $response = $ua->request(PUT $address, Content => $json);
print "resetMaster.pl    response: $response\n";
print Dumper $response if $DEBUG;
my $content = $response->content();
print "resetMaster.pl    content: $content\n";


#### PRINT DATE
print "resetMaster.pl    Completed: ";
print `date`;


sub usage {
    print `perldoc $0`;
}
    
sub getInstanceInfo {
	my $headnodeid	=	shift;
	my $privatekey	=	shift;
	my $publiccert	=	shift;
	
#my $DEBUG = 1;
	print "resetMaster.pl    getInstanceInfo(instanceid)\n" if $DEBUG;

	my $command = qq{ec2-describe-instances \\
-K $privatekey \\
-C $publiccert};	
	print "$command\n" if $DEBUG;
	my $result = `$command`;
	print "resetMaster.pl    result: $result\n" if $DEBUG;
	my @reservations = split "RESERVATION", $result;
	foreach my $reservation ( @reservations )
	{
		next if $reservation !~ /\s+$headnodeid\s+/;
		return parseInstanceInfo($reservation);
	}
	
	#print "resetMaster.pl    Returning instance: $instance\n";
}

sub parseInstanceInfo {
	my $info		=	shift;
	print "resetMaster::parseInstanceInfo    info: $info\n" if $DEBUG;

	my $instancekeys = {
	instanceid		=>	1,
	imageid			=>	2,
	longexternalip	=>	3,
	longinternalip	=>	4,
	status			=>	5,
	name			=>	6,
	instancetype	=>	9,
	launched		=>	10,
	availzone		=>	11,
	kernelid		=>	12,
	shortexternalip	=>	16,
	shortinternalip	=>	17	
	};

	#### FORMAT:
	#### 'reservation' => '	r-2b83a744	728213020069	@sc-syoung-microcluster'
	my $reservationkeys = {
	reservationid	=>	0,
	amazonuserid	=>	1,
	securitygroup	=>	2
	};
	my $blockdevicekeys = {
	device			=>	1,
	volume			=>	2,
	attached		=>	3
	};

	my @lines = split "\n", $info;
	my $instance;
	$instance->{blockdevices} = [];
	foreach my $line ( @lines )
	{
		if ( $line =~ /^BLOCKDEVICE/ )
		{
			my $blockdevice;
			my @elements = split "\t", $line;
			foreach my $key ( keys %$blockdevicekeys )
			{
				$blockdevice->{$key} = $elements[$blockdevicekeys->{$key}];
			}
			
			push @{$instance->{blockdevices}}, $blockdevice; 
		}
		if ( $line =~ /^INSTANCE/ )
		{
			my @elements = split "\t", $line;
			foreach my $key ( keys %$instancekeys )
			{
				$instance->{$key} = $elements[$instancekeys->{$key}];
			}
		}
		if ( $line =~ /^\s+/ )
		{
			$line =~ s/^\s+//;
			my @elements = split "\t", $line;
			foreach my $key ( keys %$reservationkeys )
			{
				$instance->{$key} = $elements[$reservationkeys->{$key}];
			}
		}
	}
	print "resetMaster::parseInstanceInfo    instance:\n" if $DEBUG;
	print Dumper $instance if $DEBUG;

	return $instance;
}



