#package Agua::Admin;
#use Moose;
use MooseX::Declare;

=head2

		PACKAGE		Admin
		
		PURPOSE
		
			THE Admin OBJECT PERFORMS THE FOLLOWING	TASKS:
			
				1. AUTHENTICATE USER ACCESS (PASSWORD AND SESSION ID)

				2. CREATE, MODIFY OR DELETE USERS
				
=cut
use strict;
use warnings;
use Carp;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use Data::Dumper;

class Agua::Admin with (Agua::Common) {

use Agua::Instance;

# Ints
has 'SHOWLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sessionId'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'  =>  ( isa => 'Str', is => 'rw' );
has 'project'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'workflow'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'keypairfile'=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'scopes'	=> ( is  => 'rw', 'isa' => 'Str|Undef', default	=> "" );

# Objects
has 'json'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

has 'head' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub {
		Agua::Instance->new({
			logfile		=>	"/tmp/admin.head.log",
			SHOWLOG		=>	2,
			PRINTLOG	=>	5
		});
	}
);

### /////}

method BUILD ($hash) {
	#$self->logDebug("Agua::Admin::BUILD()");
	#$self->initialise();
}

method initialise ($json) {
	#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	$self->json($json);
	if ( $json )
	{
		foreach my $key ( keys %{$json} )
		{
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($json->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("json", $json);
	
	#### START LOGFILE
	my $username 	=	$self->username() || $self->json()->{username};
	my $logfile 	= 	$self->logfile();
	$self->logDebug("logfile", $logfile);
	my $mode		=	$self->mode();
	$self->logDebug("mode", $mode);
	if ( not defined $logfile or not $logfile ) {
		my $identifier 	= 	"workflow";
		$self->setUserLogfile($username, $identifier, $mode);
		$self->appendLog($logfile);
	}
	
	#### SET HEADNODE OPS LOG
	if ( defined $self->logfile() ) {
		$self->head()->ops()->logfile($self->logfile());
		$self->head()->ops()->SHOWLOG($self->SHOWLOG());
		$self->head()->ops()->PRINTLOG($self->PRINTLOG());
	}

	#### SET DATABASE HANDLE
	$self->setDbh();	

    #### VALIDATE
	my $session_id	=	$json->{sessionId};
	my $password	=	$json->{password};
	if ( defined $session_id ) {
	    $self->logError("User session not validated") and exit unless $self->validate();
	}
	elsif ( not defined $password ) {
	    $self->logError("Password not validated") and exit;
	}
	
	$self->logDebug("end of BUILD");
}

method setUserLogfile ($username, $identifier, $mode) {
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	
	return "$installdir/log/$username.$identifier.$mode.log";
}



}


