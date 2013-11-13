use MooseX::Declare;

=head2

PACKAGE		Agua::Uml::Role

	1. CALCULATE AND CONTAIN THE SLOTS, METHODS AND CALLS
	
		OF A ROLE
		
NOTES

	1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
	
	2. ROLES ARE INHERITED
	
	
		I.E., IF A INHERITS B WHICH USES C THEN A USES C
		
EXAMPLES

./uml.pl \
--sourcefile /agua/lib/Agua/Common/Cluster.pm \
--targetdir /agua/lib/Agua \
--outputfile /agua/log/uml.tsv \
--mode users

=cut

use strict;
use warnings;
use Carp;

class Agua::Uml::Role with (Agua::Uml::Proto, Agua::Common::Logger, Agua::Common::Util) {

#if ( 1 ) {
#
## Strings
#has 'mode'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'modulename'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 	);
#has 'sourcefile'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'sourcedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
#
## Objects
#has 'methods'	=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
#
#}
#
#####/////}}}
#
#method BUILD ($hash) {
#	$self->logDebug("hash", $hash);
#	return if not defined $hash;
#	
#	foreach my $key ( keys %{$hash} ) {
#		$self->logDebug("ADDING key $key", $hash->{$key});
#		$self->$key($hash->{$key}) if $self->can($key);
#	}
#	
#	$self->logDebug("DOING self->initialise()");
#	$self->initialise();
#}
#
##### INITIALISE
#method initialise {
#	my $sourcefile	=	$self->sourcefile();
#	$self->logDebug("sourcefile", $sourcefile);
#
#	my $contents = $self->getFileContents($sourcefile);
#
#	#### SET ROLENAME
#	$self->setRoleName($contents);
#	
#	#### SET INTERNAL METHODS
#	$self->setMethods($contents);
#}
#
#method setRoleName ($contents) {
#	my ($classname) = $contents =~ /\npackage (\S+)/ms;
#	
#	return $self->classname($classname);
#}
#	
#
#method toString {
#	my $string = "";
#	$string .= $self->modulename();
#	$string .= "\n";
#	$string .= "\tmethods\n";
#	my @keys = sort keys %{$self->methods()};
#	foreach my $key ( @keys ) {
#		$string .= "\t\t$key\n";
#	}
#	
#	return $string;
#}
#


}	#### Agua::Uml::Role