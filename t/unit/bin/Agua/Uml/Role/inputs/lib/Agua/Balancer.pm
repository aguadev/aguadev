#use Moose;
use MooseX::Declare;
=head2

	PACKAGE		Balancer
	
	PURPOSE
	
		MONITOR THE LOAD BALANCER RUNNING FOR EACH CLUSTER (I.E., SGE CELL)
		
		AND RESTART IT IF IT HAS BECOME INACTIVE (E.G., DUE TO A RECURRENT
		
		ERROR IN STARCLUSTER WHEN PARSING XML OUTPUT AND/OR XML ERROR MESSAGES
		
		CAUSED BY A BUG IN SGE)
	
	NOTES    
	
		1. CRON JOB RUNS THE SCRIPT checkBalancers.pl EVERY MINUTE
		
		* * * * * /agua/0.6/bin/scripts/checkBalancers.pl
		
=cut

use strict;
use warnings;
use Carp;

class Agua::Balancer with (Agua::Common::Aws, Agua::Common::Balancer, Agua::Common::Cluster, Agua::Common::SGE, Agua::Common::Util) {

#### EXTERNAL MODULES
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/..";

#### INTERNAL MODULES	
use Agua::DBaseFactory;
use Conf::Agua;
use Agua::Instance::StarCluster

# Booleans
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 1 );

# Ints
has 'keydir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'adminkey'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'interval'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'waittime'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 100	);
has 'stabilisationtime'	=> ( is  => 'rw', 'isa' => 'Int', required	=>	0, default => 30	);
has 'minnodes'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
has 'maxnodes'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );

# Strings
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'	=>  ( isa => 'Str', is => 'rw'	);
has 'username'  =>  ( isa => 'Str', is => 'rw'	);
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );

# Objects
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

####////}	

method BUILD ($hash) {
	$self->logDebug("Agua::Balancer::BUILD()");
	
	#### SET DATABASE HANDLE
	$self->setDbh();

}


}


