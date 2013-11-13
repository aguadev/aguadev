use MooseX::Declare;

=head2

	PACKAGE		Package
	
	PURPOSE
	
		THE Package OBJECT PERFORMS THE FOLLOWING TASKS:
		
			1. SYNC WORKFLOWS (DOWNLOAD FROM REMOTE REPO
			
				THEN UPLOAD TO REMOTE REPO)
			
			2. CREATE PROJECT & WORKFLOW FILES FROM DATABASE
			
			3. LOAD PROJECT & WORKFLOW FILES INTO DATABASE

=cut

use strict;
use warnings;
use Carp;

class Agua::Package with (Agua::Common::Package,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Project,
	Agua::Common::Workflow,
	Agua::Common::Privileges,
	Agua::Common::Stage,
	Agua::Common::App,
	Agua::Common::Parameter,
	Agua::Common::Base,
	Agua::Common::Util) extends Agua::Ops {


#### EXTERNAL MODULES
use Data::Dumper;
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### INTERNAL MODULES	
use Agua::DBaseFactory;
use Conf::Agua;
use Agua::Ops;
use Agua::Instance;


# Ints
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'logfile'       => ( isa => 'Str|Undef', is => 'rw' );
has 'owner'	        => ( isa => 'Str|Undef', is => 'rw' );
has 'package'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'remoterepo'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'sourcedir'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'rootpassword'  => ( isa => 'Str|Undef', is => 'rw' );
has 'dbuser'        => ( isa => 'Str|Undef', is => 'rw' );
has 'dbpass'        => ( isa => 'Str|Undef', is => 'rw' );
has 'sessionId'     => ( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'head' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);
has 'master' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);

has 'ops' 	=> (
	is 		=>	'rw',
	isa 	=>	'Agua::Ops',
	default	=>	sub { Agua::Ops->new();	}
);

has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	memory	=>	1	);	}
);

####////}}

method BUILD ($hash) {
}

method initialis ($json) {
#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	$self->json($json);
	if ( $self->json() ) {
		foreach my $key ( keys %{$self->{json}} ) {
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($self->{json}->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("json", $self->json());

	#### SET LOG
	my $username 	=	$self->username() || $self->json()->{username};
	my $logfile 	= 	$self->logfile();
	$self->logDebug("logfile", $logfile);
	my $mode		=	$self->mode();
	$self->logDebug("mode", $mode);
	if ( not defined $logfile or not $logfile ) {
		my $identifier 	= 	"package";
		$self->setUserLogfile($username, $identifier, $mode);
		$self->appendLog($logfile);
	}
	
	#### SET DATABASE HANDLE
	$self->logDebug("Doing self->setDbh()");
	$self->setDbh();
    
	#### VALIDATE
    $self->logError("User session not validated for username: $username") and exit unless $self->validate();

}

method setUserLogfile ($username, $identifier, $mode) {
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	
	return "$installdir/log/$username.$identifier.$mode.log";
}


}

1;

