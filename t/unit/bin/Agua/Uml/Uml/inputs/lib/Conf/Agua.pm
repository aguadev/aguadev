use MooseX::Declare;

class Conf::Agua with (Conf, Agua::Common::Logger) {
    
use Data::Dumper;

# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'logfile'  	    =>  ( isa => 'Str|Undef', is => 'rw' );
has 'separator'	=>	(	is	=>	'rw',	isa	=> 	'Str'	);

=head2

	PACKAGE		Conf::Agua

    PURPOSE
    
        READ AND WRITE ini-FORMAT CONFIGURATION FILES
		
=cut

method BUILD ($hash) {
    $self->initialise();
}

method initialise () {
}




}

