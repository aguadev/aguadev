use MooseX::Declare;

=head2

PACKAGE		Logger

PURPOSE

	1. PRINT LOG MESSAGES TO FILE
	
	2. ENABLE MULTIPLE LOG LEVELS WITH Agua::Common::Logger ROLE
	
	3. STORE ALL LOG MESSAGES (WITH LOG LEVELS) IN ARRAY
	
=cut

use strict;
use warnings;
use Carp;

class Agua::Logger with Agua::Common::Logger {

# Booleans
has 'SHOWLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );

# Objects
has 'lines'     => ( isa => 'ArrayRef', is => 'rw', default => sub { [] } );

####////}	

method BUILD ($hash) {
	$self->logDebug("");
}

method write ($line) {
	return if not defined $self->logfile();
	$self->appendLog() if not defined $self->logfh();

	push @{$self->lines()}, $line;
	print { $self->logfh() } "$line\n";
}	

method writeLines ($line) {
	return if not @{self->lines()};
	return if not defined $self->logfile();
	$self->appendLog() if not defined $self->logfh();

	foreach my $line ( @{$self->lines()} ) {
		print { $self->logfh() } "$line\n";
	}	
}	

method add ($line) {
	return if not defined $line;
	return if not defined $self->logfile();
	$self->appendLog() if not defined $self->logfh();
	
	push @{$self->lines()}, $line;
}

method report {
	my $report = '';
	foreach my $line ( @{$self->lines()} ) {
		$report	.=	"$line\n";
	}
	
	return $report;
}


} #### Agua::Logger


