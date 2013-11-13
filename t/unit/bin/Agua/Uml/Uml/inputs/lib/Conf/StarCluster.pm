use MooseX::Declare;
#use Method::Signatures::Simple;

=head2

	PACKAGE		Conf::StarCluster

    PURPOSE
    
        1. READ AND WRITE STARCLUSTER ini-FORMAT CONFIGURATION FILES
			
=cut

class Conf::StarCluster with (Conf, Agua::Common::Logger) {

#use Data::Dumper;

has 'spacer'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"="		);
has 'separator'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"="		);
has 'comment'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"#"		);


}

=head1 LICENCE

This code is released under the MIT licence, a copy of which should
be provided with the code.

=end pod

=cut

1;


