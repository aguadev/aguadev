use MooseX::Declare;

=head2

PACKAGE		Agua::Uml

	1. GENERATE TABLES OF METHOD INHERITANCE HIERARCHIES FOR MODULES
	
		THAT CAN BE USED TO CREATE UML DIAGRAMS
	
NOTES

		1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
		
		2. ROLES ARE INHERITED
		
			I.E., IF A INHERITS B WHICH USES C THEN A USES C
		
EXAMPLES

./uml.pl \
--role Agua::Common::Cluster \
--sourcefile /agua/lib/Agua/Common/Cluster.pm \
--sourcedir /agua/lib/Agua \
--outputfile /agua/log/uml.tsv \
--mode users

=cut

use strict;
use warnings;
use Carp;

class Agua::Uml with (Agua::Common::Logger, Agua::Common::Util) {

if ( 1 ) {

# Strings
has 'mode'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'rolename'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 	);
has 'sourcefile'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'sourcedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'targetdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'classregex'=> ( isa => 'Str|Undef', is => 'rw', default	=>	".pm\$"	);

# Objects
has 'classes'	=> ( isa => 'HashRef', is => 'rw', required => 0 );

use Agua::Uml::Role;
use Agua::Uml::Class;

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
}

#### INITIALISE
method initialise {
	$self->logDebug("");
}

method roleUser {
#### GET UML FOR ROLE AND ITS USERS

	#my $sourcefile	=	$self->sourcefile();
	#my $targetfile	=	$self->targetfile();
	#my $outputfile	=	$self->outputfile();
	#$self->logDebug("sourcefile", $sourcefile);
	#$self->logDebug("targetfile", $targetfile);
	#$self->logDebug("outputfile", $outputfile);
	#$self->logError("sourcefile not defined", $sourcefile) and exit if not defined $sourcefile;
	#$self->logError("targetfile not defined", $targetfile) and exit if not defined $targetfile;
	#$self->logError("outputfile not defined", $outputfile) and exit if not defined $outputfile;
	#
	#$self->_roleUser($sourcefile, $targetfile);
}

method _roleUser ($sourcefile, $targetfile, $outputfile) {
	my $role = Agua::Uml::Role->new({
		sourcefile 	=> 	$sourcefile,
	    SHOWLOG    	=>  $self->SHOWLOG(),
	    PRINTLOG   	=>  $self->PRINTLOG
	});
	$self->logDebug("role", $role);
	
	my $user = Agua::Uml::Class->new({
		targetfile 	=> 	$targetfile,
	    SHOWLOG    	=>  $self->SHOWLOG(),
	    PRINTLOG   	=>  $self->PRINTLOG
	});
	$self->logDebug("user", $user);

	#### GENERATE UML
	my $uml = $self->generateUml($role, $user, undef);
	$self->logDebug("uml", $uml);

	#### PRINT UML
	return $self->printUml($outputfile, [$role], $uml);	
}

#method roleUsers {
##### GET UML FOR ROLE AND ITS USERS
#
#	my $sourcefile	=	$self->sourcefile();
#	my $sourcedir	=	$self->sourcedir();
#	my $targetdir	=	$self->targetdir();
#	my $outputfile	=	$self->outputfile();
#	$self->logDebug("sourcefile", $sourcefile);
#	$self->logDebug("sourcedir", $sourcedir);
#	$self->logDebug("targetdir", $targetdir);
#	$self->logDebug("outputfile", $outputfile);
#
#	my $role = Agua::Uml::Role->new({
#		sourcefile 	=> 	$sourcefile,
#	    SHOWLOG    	=>  $self->SHOWLOG(),
#	    PRINTLOG   	=>  $self->PRINTLOG
#	});
#	$self->logDebug("role", $role);
#
#	#### GET USERS OF THIS ROLE
#	my $users = $self->getUsers($role, $targetdir);
#	$self->logDebug("users", $users);
#	
#	#### GENERATE UML
#	my $uml = {};
#	foreach my $user ( @$users ) {
#		$self->generateUml($uml, $role, $user);
#	}
#	$self->logDebug("uml", $uml);
#
#	#### PRINT UML
#	return $self->printUml($outputfile, [$role], $uml);	
#}
#
#
#method generateUml ($uml, $role, $class) {
#	my $classname = $class->classname();
#	$self->logDebug("classname", $classname);
#	my $externals 	= $class->externals();
#	$self->logDebug("externals", $externals);
#	my $methods 	=	$role->methods();
#	$self->logDebug("methods", $methods);
#	
#	foreach my $key ( sort keys %$externals ) {
#		my $external = $externals->{$key};
#		next if not exists $methods->{$key};
#		$self->logDebug("CALL TO $key FOUND in methods external", $external);
#		my @callers = sort keys %$external->{caller};
#		foreach my $caller ( @callers ) {
#			$uml->{$classname} = [] if not exists $uml->{$classname};
#			push @{$uml->{$classname}}, { 
#				source 	=> 	$caller,
#				count	=> 	$external->{caller}->{$caller},
#				target	=>	$key
#			};
#		}
#	}
#	$self->logDebug("uml", $uml);
#	
#	return $uml;
#}
#
#method getUsers ($role, $targetdir) {
#	my $classes = $self->getClasses($targetdir);	
#	$self->logDebug("classes", $classes);
#	
#	my $users = [];
#	foreach my $key ( keys %$classes ) {
#
#		my $class = $classes->{$key};
#
#		$self->logDebug("key", $key);
#		
#		$self->logDebug("class", $class);
#		push @$users, $class if $class->hasRole($role);
#		
#		last;
#	}
#	$self->logDebug("users", $users);
#	
#	return $users;
#}
#
#method getClasses ($targetdir) {
#	$self->logDebug("targetdir", $targetdir);
#	
#	my $classes = {};
#	my $files = $self->getFiles($targetdir);
#	$self->logDebug("files", $files);
#	foreach my $file ( @$files ) {
#		my $classfile = "$targetdir/$file";
#		$self->logDebug("classfile", $classfile);
#		my $class = Agua::Uml::Class->new({
#			classfile 	=> 	$classfile,
#			targetdir 	=> 	$targetdir,
#			SHOWLOG    	=>  $self->SHOWLOG(),
#			PRINTLOG   	=>  $self->PRINTLOG
#		});
#		$self->logDebug("class", $class);
#		next if not defined $class;
#		$self->logDebug("classname", $class->classname());
#
#			
#		#next if $class->classname() ne "Agua::StarCluster";
#
#		
#		$classes->{$class->classname()} = $class;
#
#
#		#last;
#
#	}
#	$self->classes($classes);
#	$self->logDebug("classes", $classes);
#	
#	my @keys = keys %$classes;
#	foreach my $key ( @keys ) {
#		print $classes->{$key}->externalCallsToString();
#	}
#	
#	#$self->logDebug("DEBUG EXIT") and exit;
#	
#
#	#my $dirs = $self->getDirs($targetdir);
#	#$self->logDebug("dirs", $dirs);
#	#foreach my $dir ( @$dirs ) {
#	#	my $subfiles = $self->getClasses("$targetdir/$dir"); 
#	#	@$classes = (@$classes, @$subfiles) if @$subfiles;
#	#}
#	#$self->logDebug("classes", $classes);
#	
#	return $classes;
#}
#
#method getRoles ($sourcedir) {
#	$self->logDebug("sourcedir", $sourcedir);
#	
#	my $classes = {};
#	my $files = $self->getFiles($sourcedir);
#	$self->logDebug("files", $files);
#	foreach my $file ( @$files ) {
#		my $classfile = "$sourcedir/$file";
#		my $class = Agua::Uml::Role->new({
#			classfile 	=> 	$classfile,
#			sourcedir 	=> 	$sourcedir,
#			SHOWLOG    	=>  $self->SHOWLOG(),
#			PRINTLOG   	=>  $self->PRINTLOG
#		});
#		$self->logDebug("class", $class);
#		
#		$classes->{$class->classname()} = $class;
#		last;
#	}
#	$self->classes($classes);
#	$self->logDebug("classes", $classes);
#	
#	#$self->logDebug("DEBUG EXIT") and exit;
#	
#
#	#my $dirs = $self->getDirs($sourcedir);
#	#$self->logDebug("dirs", $dirs);
#	#foreach my $dir ( @$dirs ) {
#	#	my $subfiles = $self->getRoles("$sourcedir/$dir"); 
#	#	@$classes = (@$classes, @$subfiles) if @$subfiles;
#	#}
#	#$self->logDebug("classes", $classes);
#	
#	return $classes;
#}
#
#method printUml ($outputfile, $roles, $uml) {
#	$self->logDebug("outputfile", $outputfile);
#	$self->logDebug("uml", $uml);
#	
#	#### OPEN OUTPUT FILE
#	open(OUT, ">$outputfile") or $self->logError("Can't open outputfile", $outputfile) and exit;
#
#	#### PRINT ROLE WITH METHODS
#	foreach my $role ( @$roles ) {
#		print OUT $role->toString();
#		print $role->toString();
#	}
#	
#	##### PRINT EXTERNAL CALLS OF CLASSES IN A-Z ORDER
#	my @classnames = sort keys %{$uml};
#	$self->logDebug("classnames", \@classnames);
#	foreach my $classname ( @classnames ) {
#		
#		print OUT $classname;
#		print OUT "\n";
#		print OUT "\texternal_calls\n";
#		print OUT $self->externalsToString($uml->{$classname});
#
#		print "$classname\n";
#		print "\n";
#		print "\texternal_calls\n";
#		print $self->externalsToString($uml->{$classname});
#	}
#
#	#### CLOSE OUTPUT FILE	
#	close(OUT) or $self->logError("Can't close outputfile", $outputfile) and exit;
#}
#
#method externalsToString ($externals) {
#	my $string = '';
#	foreach my $external ( @$externals ) {
#		$string .= "\t\t";
#		$string .= $external->{source};
#		$string .= "\t";
#		$string .= $external->{target};
#		$string .= "\t";
#		if ( $external->{count} > 1 ) {
#			$string .= $external->{count};
#			$string .= "\t";
#		}
#		$string .= "\n";
#	}		
#
#	return $string;
#}




}	#### Agua::Uml