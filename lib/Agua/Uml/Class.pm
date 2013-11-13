use MooseX::Declare;

=head2

PACKAGE		Agua::Uml::Class

		1. CALCULATE AND CONTAIN THE ROLE USAGES AND INHERITANCES
		
			OF A CLASS
		
NOTES

		1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
		
		2. ROLES ARE INHERITED
		
			I.E., IF A INHERITS B WHICH USES C THEN A USES C
		
EXAMPLES

./uml.pl \
--role Agua::Common::Cluster \
--targetfile /agua/lib/Agua/Common/Cluster.pm \
--sourcedir /agua/lib/Agua \
--outputfile /agua/log/uml.tsv \
--mode users

=cut

use strict;
use warnings;
use Carp;

class Agua::Uml::Class with (Agua::Uml::Proto,
	Agua::Common::Logger,
	Agua::Common::Util) {

# Strings
has 'modulename'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetfile'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'basedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'sourcedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'stringindent'=> ( isa => 'Str|Undef', is => 'rw', default	=>	''	);

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
	$self->logDebug("");
	my $modulename	=	$self->modulename();
	$self->logDebug("BEFORE self->targetfile");
	my $targetfile	=	$self->targetfile();
	$self->logDebug("BEFORE self->targetdir");
	my $targetdir	=	$self->targetdir();
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("targetdir", $targetdir);

	#### GET FILE CONTENTS
	my $contents = $self->getContents($targetfile);
	return if not defined $contents;
	
	#### SET CLASS NAME
	$self->setClassName($contents);
	$self->logDebug("MUST BE SET modulename", $modulename);
	return if not defined $self->modulename();
	
	#### SET BASE DIR
	my $basedir = $self->setBaseDir($targetfile);
	$self->logDebug("basedir", $basedir);

	#### SET ROLES
	$self->setRoles($contents, $basedir);
	
	#### SET ROLE NAMES
	$self->setRoleNames();
	
	#### SET SLOTS
	$self->setSlots($contents);

	#### SET METHODS
	$self->setMethods($contents);
	
	#### SET INTERNAL AND EXTERNAL CALLS
	$self->setCalls($contents);
}

method setClassName ($contents) {
	my ($trash, $classname) = $contents =~ /^(.+\n)?class ([^\s^\$]+)/ms;
	return if not defined $classname;
	
	return $self->modulename($classname);
}
	

	
}	#### Agua::Uml::Class