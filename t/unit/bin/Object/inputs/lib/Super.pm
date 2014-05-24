package Super;

=head2

ROLE        Super

PURPOSE

	TEST Object.pm
	
=cut

#### EXTERNAL MODULES
use Data::Dumper;

sub new {
 	my $self 		=	shift;
    my $arguments 	=	shift;

    ### INITIALISE THE OBJECT'S ELEMENTS
    $self->initialise($arguments);

    return $self;
}

sub getSlots {
	my @slots = qw(
SUPER1

logfile
log
printlog
backup
OLDlog
OLDprintlog
errpid
indent
username
logfh
oldout
olderr
errortype
	);
	
	return \@slots;
}

sub initialise {
    my $self		=	shift;
    my $arguments	=	shift;

	print "Doing Super::initialise    arguments: \n";
	print Dumper $arguments;
	
	#### ADD ANCESTER SLOTS, MAKE AND LOAD SLOTS
	print "DOING Super::doSlots\n";
	$self->doSlots($arguments);

	print "Doing Super::initialise    DOING self->indent(4)\n";
	$self->indent(4);
	print "AFTER Super::initialise    AFTER self->indent(4)\n";

	$self->loadSlots($arguments) if defined $SLOTS and @$SLOTS;	
}

sub logDebug {
    my ($self, $message, $variable) = @_;
	
	return -1 if not $self->log() > 3 and not $self->printlog() > 3;

	$message = '' if not defined $message;
    $self->appendLog($self->logfile()) if not defined $self->logfh();   

	my $text = $variable;
	if ( not defined $variable and $#_ == 2 )	{
		$text = "undef";
	}
	elsif ( ref($variable) )	{
		$text = $self->objectToJson($variable);
	}

    my ($package, $filename, $linenumber) = caller;
    my $timestamp = $self->logTimestamp();
	my $callingsub = (caller 1)[3] || '';
	
	my $indent = $self->indent();
	my $spacer = " " x $indent;
	my $line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$message\n";
	$line = "$timestamp$spacer" . "[DEBUG]   \t$callingsub\t$linenumber\t$message: $text\n" if $#_ == 2;

    print { $self->logfh() } $line if defined $self->logfh() and $self->printlog() > 3;
    print $line if $self->log() > 3;
	return $line;
}

1;

