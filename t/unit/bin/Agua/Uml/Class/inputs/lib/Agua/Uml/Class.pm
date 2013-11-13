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

if ( 1 ) {

# Strings
has 'modulename'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

# Objects
has 'methods'	=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'roles'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'internals'	=> ( isa => 'HashRef|Undef', is => 'rw', default	=>	sub {{}} );
has 'externals'	=> ( isa => 'HashRef|Undef', is => 'rw', default	=>	sub {{}}	);
}

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
	my $modulename		=	$self->modulename();
	my $targetfile	=	$self->targetfile();
	my $targetdir	=	$self->targetdir();

	$self->logDebug("modulename", $modulename);
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("targetdir", $targetdir);

	#### GET FILE CONTENTS
	$self->logDebug("Can't find targetfile: $targetfile") and exit if not -f $targetfile;
	my $contents = $self->getFileContents($targetfile);
	$self->logError("Classfile is empty: $targetfile") and exit if not $contents;
	
	#### CHECK CLASS IN FILE AND SET CLASS IF ABSENT
	$modulename = $self->setModuleName($contents, $targetfile, $modulename);
	$self->logDebug("modulename", $modulename);
	
	#### SET INTERNAL METHODS
	$self->setInternalMethods($contents);
	
	#### SET INTERNAL AND EXTERNAL CALLS
	$self->setCalls($contents);

	#### SET ROLES
	$self->setRoles($targetdir, $targetfile, $modulename);
}

method setClassName ($contents) {
	my ($classname) = $contents =~ /class (\S+)/ms;
	
	return $self->classname($classname);
}
	

method toString {
	my $string = "class " . $self->modulename();
	
	
	
}
	
}	#### Agua::Uml::Class