use MooseX::Declare;

=head2

PACKAGE		Agua::Uml::Role

	1. CALCULATE AND CONTAIN THE SLOTS, METHODS AND CALLS
	
		OF A ROLE
		
NOTES

	1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
	
	2. ROLES ARE INHERITED
	
	
		I.E., IF A INHERITS B WHICH USES C THEN A USES C
		
=cut

use strict;
use warnings;
use Carp;

class Agua::Uml::Role with (Agua::Uml::Proto, Agua::Common::Logger, Agua::Common::Util) {
# Strings
has 'mode'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'modulename'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 	);
has 'sourcefile'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'sourcedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'basedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'stringindent'=> ( isa => 'Str|Undef', is => 'rw', default	=>	'');

# Objects
has 'slots'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'methods'	=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'roles'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'internals'	=> ( isa => 'HashRef|Undef', is => 'rw', default	=>	sub {{}} );
has 'externals'	=> ( isa => 'HashRef|Undef', is => 'rw', default	=>	sub {{}}	);
has 'rolenames'	=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=>	0	);

####/////}}}

method BUILD ($hash) {
	$self->logDebug("hash", $hash);
	return if not defined $hash;
	
	foreach my $key ( keys %{$hash} ) {
		$self->logDebug("ADDING key $key", $hash->{$key});
		$self->$key($hash->{$key}) if $self->can($key);
	}
	
	$self->logDebug("DOING self->initialise()");
	$self->initialise();

	return if not defined $self->modulename();
}

#### INITIALISE
method initialise {
	my $sourcefile	=	$self->sourcefile();
	$self->logDebug("sourcefile", $sourcefile);

	#### GET FILE CONTENTS
	my $contents = $self->getContents($sourcefile);
	return if not defined $contents;
	
	#### SET ROLE NAME
	$self->setRoleName($contents);
	
	#### SET BASE DIR
	my $basedir = $self->setBaseDir($sourcefile);
	
	#### SET ROLES
	$self->setRoles($contents, $basedir);

	#### SET SLOTS
	$self->setSlots($contents);

	#### SET METHODS
	$self->setMethods($contents);
	
	#### SET INTERNAL AND EXTERNAL CALLS
	$self->setCalls($contents);
}

method setRoleName ($contents) {
	my ($modulename) = $contents =~ /\n*package (\S+);/ms;
	$self->logDebug("modulename", $modulename);
	
	return $self->modulename($modulename);
}


}	#### Agua::Uml::Role