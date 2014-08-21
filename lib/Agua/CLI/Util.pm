package Agua::CLI::Util;
use Moose::Role;
use Method::Signatures::Simple;

=head2

ROLE        Agua::CLI::Util

PURPOSE

	1. PROVIDE COMMON UTILITY METHODS FOR Agua::CLI CLASSES

=cut

#Boolean

# Ints

# Strings

# Objects


method getLoader {
	$self->logDebug("self->logfile", $self->logfile());
	
	return Agua::Package->new({
		username	=>	$self->username(),
		database	=>	$self->database(),
		logfile		=>	$self->logfile(),
		log			=>	$self->log(),
		printlog	=>	$self->printlog(),
		conf		=>	$self->conf(),
		db	        =>	$self->db()
	});
}

method setUsername {
	my $username    =   $self->username();
	$self->logDebug("username", $username);
	
	if ( not defined $username ) {
		$username   =   `whoami`;
		$username       =~  s/\s+$//;
		$self->username($username);
	}
	
	return $username;
}


no Moose::Role;

1;