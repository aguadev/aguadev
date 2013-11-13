use MooseX::Declare;

=head2

	PACKAGE		Agua::Instance
	
	PURPOSE
	
		AN ABSTRACT CLASS REPRESENTING A GENERIC EC2 INSTANCE

=cut

class Agua::Instance with Agua::Common::Logger {

use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Getopt::Simple;

#### INTERNAL MODULES
use Agua::Ops;

# Booleans
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 0 );

#### Int
has 'amazonuserid'	=> ( isa => 'Int|Undef', is => 'rw', required	=>	0	);

#### String
has 'instanceid'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'privatekey'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'publiccert'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'imageid'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'externalfqdn'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'internalfqdn'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'externalip'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'internalip'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);	
has 'status'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'keyname'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'instancetype'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'launched'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'availzone'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'kernelid'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'reservationid'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'securitygroup'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

#### Objects
has 'blockdevices'	=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=>	0	);
has 'tags'			=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'ops' 			=> (
	is =>	'rw',
	'isa' => 'Agua::Ops',
	default	=>	sub { Agua::Ops->new({});	}
);


####/////}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	$self->logDebug("");
	$self->init($hash);
	$self->logDebug("self->instanceid", $self->instanceid());
	$self->getInfo() if defined $self->instanceid();
}

method init($hash) {
	#### OPEN LOGFILE IF DEFINED
	$self->startLog($self->logfile()) if defined $self->logfile();
	$self->logDebug("logfile: " . $self->logfile()) if defined $self->logfile();

	#### SET ops SHOWLOG AND PRINTLOG
	$self->ops()->SHOWLOG($self->SHOWLOG());
	$self->ops()->PRINTLOG($self->PRINTLOG());
	
	$self->load($hash) if defined $hash and $hash != {};
}

method getInfo () {
=head2

	SUBROUTINE 		getInfo
	
	PURPOSE
	
		RETURN A HASH OF INSTANCE VARIABLES

	NOTES
	
		RESERVATION     r-e30f5d89      558277860346    default
		INSTANCE        i-b42f3fd9      ami-90af5ef9    ec2-75-101-214-196.compute-1.amazonaws.com      ip-10-127-158-202.ec2.internal running aquarius        0               t1.micro        2010-12-24T09:51:37+0000        us-east-1a     aki-b51cf9dc    ari-b31cf9da            monitoring-disabled     75.101.214.196  10.127.158.202        ebs
		BLOCKDEVICE     /dev/sda1       vol-c6e346ae    2010-12-24T09:51:40.000Z
		BLOCKDEVICE     /dev/sdh        vol-266dc84e    2010-12-24T23:03:04.000Z
		BLOCKDEVICE     /dev/sdi        vol-fa6dc892    2010-12-24T23:05:50.000Z
=cut

	my $instanceid = $self->instanceid();
	my $privatekey = $self->privatekey();
	my $publiccert = $self->publiccert();
	return if not defined $instanceid;
	return if not defined $privatekey;
	return if not defined $publiccert;
	$self->logDebug("instanceid", $instanceid);
	$self->logDebug("privatekey", $privatekey);
	$self->logDebug("publiccert", $publiccert);
	
	my $command = qq{ec2-describe-instances \\
-K $privatekey \\
-C $publiccert \\
$instanceid};
	$self->logDebug("$command");
	my $info = `$command`;
	return $self->parseInfo($info);
}

method parseInfo ($info) {
	$self->logDebug("info", $info);

	my $instancekeys = {
	instanceid		=>	1,
	imageid			=>	2,
	externalfqdn	=>	3,
	internalfqdn	=>	4,
	status			=>	5,
	keyname			=>	6,
	instancetype	=>	9,
	launched		=>	10,
	availzone		=>	11,
	kernelid		=>	12,
	externalip		=>	16,
	internalip		=>	17	
	};

	#### FORMAT:
	#### 'reservation' => '	r-2b83a744	728213020069	@sc-syoung-microcluster'
	my $reservationkeys = {
	reservationid	=>	1,
	amazonuserid	=>	2,
	securitygroup	=>	3
	};
	my $blockdevicekeys = {
	device			=>	1,
	volume			=>	2,
	attached		=>	3
	};

	my @lines = split "\n", $info;
	my $blockdevices = [];
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
			
			push @$blockdevices, $blockdevice; 
		}
		if ( $line =~ /^INSTANCE/ )
		{
			my @elements = split "\t", $line;
			foreach my $key ( keys %$instancekeys )
			{
				$self->$key($elements[$instancekeys->{$key}]);
			}
		}
		if ( $line =~ /^RESERVATION/ )
		{
			my @elements = split "\t", $line;
			foreach my $key ( keys %$reservationkeys )
			{
				$self->$key($elements[$reservationkeys->{$key}]);
			}
		}
	}
	$self->blockdevices($blockdevices);

$self->logDebug("self", $self);

}

method load ($hash) {
	foreach my $key ( keys %$hash ) {
		$self->$key($hash->{$key});
	}
}

method addTag ($key, $value) {
	$self->tags({}) if not defined $self->tags();
	$self->tags()->{$key}	= $value;
}

method removeTag ($key, $value) {
	return if not exists $self->tags()->{$key};
	delete $self->tags()->{$key};
}



}