use MooseX::Declare;

=head2

PACKAGE		Agua::Uml

	1. GENERATE TABLES OF METHOD INHERITANCE HIERARCHIES FOR MODULES
	
		THAT CAN BE USED TO CREATE UML DIAGRAMS
	
NOTES

		1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
		
		2. ROLE USAGE AND INHERITANCE LISTS CAN BE ON SEPARATE
		
			LINES OR JOINED TOGETHER, E.G.,
						
			class Agua::StarCluster with (Agua::Common::Aws,
				Agua::Common::Base,
				Agua::Common::Balancer,
				Agua::Common::Cluster,
				Agua::Common::SGE,
            
            AND
                
			class Agua::StarCluster with (Agua::Common::Aws, Agua::Common::Base, Agua::Common::Balancer, Agua::Common::Cluster, ...

				
		3. FOLLOW CALLS TO A ROLE THROUGH ALL OTHER ROLES USED BY THE CLASS:
		
            class A USES role B
            
            role B CALLS role C
            
            --> class A CALLS role C
		
=cut

use strict;
use warnings;
use Carp;

class Agua::Uml with (Agua::Common::Logger, Agua::Common::Util) {

# Strings
has 'mode'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'rolename'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 	);
has 'sourcefile'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetfile'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'sourcedir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'targetdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'classregex'=> ( isa => 'Str|Undef', is => 'rw', default	=>	".pm\$"	);

# Objects
has 'classes'	=> ( isa => 'HashRef', is => 'rw', required => 0 );

use Agua::Uml::Role;
use Agua::Uml::Class;

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

#### ROLE USER
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
	##### OPEN OUTPUT FILE
	#my $outfh;
	#open($outfh, ">$outputfile") or $self->logError("Can't open outputfile: $outputfile") and exit;
	#
	#$self->_roleUser($sourcefile, $targetfile, $outfh);
	#
	##### CLOSE $outfhPUT FILE	
	#close($outfh) or $self->logError("Can't close outputfile", $outputfile) and exit;

}



method _roleUser ($sourcefile, $targetfile, $outfh) {

	my $role = Agua::Uml::Role->new({
		sourcefile 	=> 	$sourcefile,
	    SHOWLOG    	=>  $self->SHOWLOG(),
	    PRINTLOG   	=>  $self->PRINTLOG
	});
	$self->logDebug("role", $role->summary());
	
	my $user = Agua::Uml::Class->new({
		targetfile 	=> 	$targetfile,
	    SHOWLOG    	=>  $self->SHOWLOG(),
	    PRINTLOG   	=>  $self->PRINTLOG
	});
	$self->logDebug("user", $user->summary());
	
	print $outfh $role->summary();
	print $role->summary();	
	
	#### GENERATE UML
	my $uml = $self->generateUml($role, $user, undef);
	$self->logDebug("uml", $uml);
	
	#### PRINT UML
	return $self->printUml($outfh, $role, $uml);	
}

### ROLE USERS
method roleUsers {
#### GET UML FOR ROLE AND ITS USERS
	$self->logDebug("");
	my $sourcefile	=	$self->sourcefile();
	my $targetdir	=	$self->targetdir();
	my $outputfile	=	$self->outputfile();
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetdir", $targetdir);
	$self->logDebug("outputfile", $outputfile);

	$self->logError("sourcefile not defined", $sourcefile) and exit if not defined $sourcefile;
	$self->logError("targetdir not defined", $targetdir) and exit if not defined $targetdir;
	$self->logError("outputfile not defined", $outputfile) and exit if not defined $outputfile;
	
	$self->_roleUsers($sourcefile, $targetdir, $outputfile);	
}

method _roleUsers ($sourcefile, $targetdir, $outputfile) {
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetdir", $targetdir);
	$self->logDebug("outputfile", $outputfile);

	my $role = Agua::Uml::Role->new({
		sourcefile 	=> 	$sourcefile,
	    SHOWLOG    	=>  $self->SHOWLOG(),
	    PRINTLOG   	=>  $self->PRINTLOG
	});
	$self->logDebug("role->modulename()", $role->modulename());

	#### GET USERS OF THIS ROLE
	my $users = $self->getUsers($role, $targetdir);
	$self->logDebug("USERS:", $self->hashKeysToString($users));
	
	#### OPEN OUTPUT DIR
	my ($outputdir) = $outputfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("outputdir", $outputdir);
	`mkdir -p $outputdir` if not -d $outputdir;

	#### OPEN OUTPUT FILE
	my $outfh;
	open($outfh, ">$outputfile") or $self->logError("Can't open outputfile: $outputfile") and exit;

	#### PRINT ROLE SUMMARY	
	print $outfh $role->summary();
	print $role->summary();	

	#### PRINT UML FOR EACH USER
	foreach my $key ( keys %$users ) {
		my $user = $users->{$key}->{object};
		$self->logDebug("key $key user->modulename: ", $user->modulename());

		my $outfile = "$outputfile--" . $user->modulename() . "--" . $role->modulename() . ".tsv";
		$outfile =~ s/::/-/g;
		$self->logDebug("outfile", $outfile);
	
		my $uml = $self->generateUml($role, $user, undef);
		$self->logDebug("uml", $uml);
		$self->logDebug("umlToString", $self->umlToString($uml));
		
		#### PRINT UML
		$self->printUml($outfh, $role, $uml);	
	}

	#### CLOSE $outfhPUT FILE	
	close($outfh) or $self->logError("Can't close outputfile", $outputfile) and exit;

	$self->logDebug("COMPLETED");
}

method getUsers ($role, $targetdir) {
	my $classes = $self->getClasses($targetdir);	
	#$self->logDebug("classes", $classes);
	$self->logDebug("no. classes", scalar(keys %$classes));
	
	my $users = {};
	foreach my $key ( keys %$classes ) {
		$self->logDebug("key", $key);


#next unless $key eq "Agua::Workflow";
#$self->logDebug("class", $classes->{$key}->toString());


		my $class = $classes->{$key};
		
		$self->logDebug("class->modulename()", $class->modulename());
		$self->logDebug("Adding class $key to users") if $class->hasRole($role);
		$users->{$key}->{object} = $class and next if $class->hasRole($role);


		next if not defined $class->roles();
		foreach my $subrolename ( keys %{$class->roles()} ) {
			my $subrole = $class->roles()->{$subrolename}->{object};
			#$self->logDebug("subrole", $subrole);
			$self->logDebug("subrole->modulename()", $subrole->modulename());
			$self->logDebug("Adding class $key to users") if $subrole->hasRole($role);
			$users->{$key}->{object} = $class and last if $subrole->hasRole($role);
		}
	}

	my @keys = keys %$users;
	$self->logDebug("no. users", $#keys + 1);
	$self->logDebug("USERS: @keys");
	
	return $users;
}


method getClasses ($targetdir) {
	$self->logDebug("targetdir", $targetdir);

	my $classes = $self->_getClasses($targetdir);

	my @array = sort keys %$classes;
	$self->logDebug("classes", \@array);
	$self->logDebug("FINAL CLASSES for targetdir", $targetdir);

	foreach my $modulename ( keys %$classes ) {
		$self->logDebug("modulename", $modulename);
		$self->logDebug("classes->{$modulename}", $classes->{$modulename}) if not $modulename;
	}
	
	return $self->classes($classes);
}

method _getClasses ($targetdir) {
	$self->logDebug("targetdir", $targetdir);
	my $classes = {};
	my $files = $self->getFiles($targetdir);
	$self->logNote("files", $files);


	my $showlog = $self->SHOWLOG();
	$self->SHOWLOG(2);
	
	foreach my $file ( @$files ) {
		my $targetfile = "$targetdir/$file";
		$self->logNote("targetfile", $targetfile);

#$self->logDebug("file", $file);
#$self->SHOWLOG(5) if $file eq "View.pm";

		my $class = Agua::Uml::Class->new({
			targetfile 	=> 	$targetfile,
			targetdir 	=> 	$targetdir,
			SHOWLOG    	=>  $self->SHOWLOG(),
			PRINTLOG   	=>  $self->PRINTLOG
		});
		#$self->logNote("class", $class);
		next if not defined $class or not defined $class->modulename();
		$self->logNote("class->modulename()", $class->modulename());
		$classes->{$class->modulename()} = $class;

#$self->SHOWLOG(2) if $file eq "View.pm";

	}

	$self->SHOWLOG($showlog);


	$self->logNote("CLASSES for targetdir", $targetdir);
	foreach my $modulename ( keys %$classes ) {
		$self->logNote("modulename", $modulename);
	}
	#$self->logNote("classes", $classes);
	
	my @keys = keys %$classes;
	foreach my $key ( @keys ) {
		my $modulename = $classes->{$key}->modulename();
		$self->logNote("modulename", $modulename);
	}
	
	$self->logNote("Doing directories");
	my $dirs = $self->getDirs($targetdir);
	$self->logNote("dirs", $dirs);
	foreach my $dir ( @$dirs ) {
		my $subclasses = $self->_getClasses("$targetdir/$dir"); 
		$classes = $self->addHashes($classes, $subclasses) if defined $subclasses and %$subclasses; 
	}
	
	$self->logNote("classes", $classes);
	$self->logNote("FINAL CLASSES for targetdir", $targetdir);
	foreach my $modulename ( keys %$classes ) {
		$self->logNote("modulename", $modulename);
	}
	
	return $classes;
}


#### USER ROLES
method userRoles {
	my $targetfile = $self->targetfile();
	$self->logDebug("targetfile", $targetfile);
	my $outputfile = $self->outputfile();
	$self->logDebug("outputfile", $outputfile);

	$self->logError("targetfile not defined", $targetfile) and exit if not defined $targetfile;
	$self->logError("outputfile not defined", $outputfile) and exit if not defined $outputfile;

	return $self->_userRoles($targetfile, $outputfile);
}

method _userRoles ($targetfile, $outputfile) {
	$self->logDebug("targetfile", $targetfile);
	my $user = Agua::Uml::Class->new({
		targetfile 	=> 	$targetfile,
	    SHOWLOG    	=>  $self->SHOWLOG(),
	    PRINTLOG   	=>  $self->PRINTLOG
	});
	$self->logDebug("user", $user->summary());
	#$self->logDebug("user->roles", $user->roles());	

	#### OPEN OUTPUT DIR
	my ($outputdir) = $outputfile =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("outputdir", $outputdir);
	`mkdir -p $outputdir` if not -d $outputdir;

	#### OPEN OUTPUT FILE
	my $outfh;
	open($outfh, ">$outputfile") or $self->logError("Can't open outputfile: $outputfile") and exit;
	print $outfh $user->summary();
	print $user->summary();	
	
	$self->_processUserRoles($user, $targetfile, $outfh);

	#### CLOSE $outfhPUT FILE	
	close($outfh) or $self->logError("Can't close outputfile", $outputfile) and exit;

}

method _processUserRoles ($user, $targetfile, $outfh) {
	$self->logDebug("");
	
	my $outputs = '';
	$self->logDebug("Returning because user->roles not defined") if not defined $user->roles();
	return $outputs if not defined $user->roles();
	
	my $counter = 0;
	foreach my $rolename ( keys %{$user->roles()} ) {
		print "rolename: $rolename\n";
		$counter++;
		return if $counter > 3;
		
		my $role = $user->roles()->{$rolename}->{object};
		my $filepath = $role->modulename();
		$filepath =~ s/::/\//g;
		$self->logDebug("filepath", $filepath);
		
		my $sourcefile = $user->basedir() . "/" . $filepath . ".pm";
		$self->logDebug("sourcefile", $sourcefile);
		
		#my $outfile = "$outputfile--" . $user->modulename() . "--" . $role->modulename() . ".tsv";
		#$outfile =~ s/::/-/g;
		#$self->logDebug("outfile", $outfile);
		
		#### PRINT UML TO OUTPUT FILE
		my $output = $self->_roleUser($sourcefile, $targetfile, $outfh);
		
		if ( defined $role->roles() ) {
			foreach my $subrolename ( keys %{$role->roles()} ) {
				$self->logDebug("subrolename", $subrolename);
				my $subrole = $role->roles()->{$subrolename}->{object};
				$self->logDebug("subrole", $subrole);
				
				my $out = $self->_processUserRoles($subrole, $targetfile, $outfh);
				#$self->logDebug("out", $out);
				$output .= $out if defined $out;
			}
		}
		
		$outputs .= $output;
	}
	
	#### RETURN OUTPUT FOR TESTING - REAL OUTPUT IS TO outfh
	return $outputs;
}


#### UML
method generateUml ($role, $user, $uml) {
	$uml = {} if not defined $uml;
	
	#### CHECK FOR EXTERNAL CALLS BY USER TO ROLE
	$uml = $self->checkRoleCalled($role, $user, $uml, undef);
	$self->logDebug("uml", $uml);
	
	#### CHECK FOR EXTERNAL CALLS TO ROLE BY OTHER ROLES USED BY USER
	foreach my $rolename ( sort keys %{$user->roles()} ) {
		$self->logDebug("CHECKING EXTERNALS for rolename", $rolename);
		my $subuser = $user->roles()->{$rolename}->{object};
		$self->logDebug("subuser", $subuser);
		
		next if $role->modulename() eq $subuser->modulename();

		my $subuml = $self->checkRoleCalled($role, $subuser, $uml, $user);
		$uml = $self->addHashes($uml, $subuml);
	}
	
	return $uml;
}

method checkRoleCalled ($role, $user, $uml, $parent) {
	my $username = $user->modulename();
	$self->logDebug("user->modulename", $username);
	my $modulename = $role->modulename();
	$self->logDebug("role->modulename", $modulename);
	$self->logDebug("user->externalSummary ", $user->externalSummary());
	$self->logDebug("role->methods", $role->methodSummary());
	return $uml if not defined $role->methods();
	return $uml if not defined $user->externals();
	
	#### ADD TO UML IF USER MAKES EXTERNAL CALL TO ROLE 
	foreach my $callee ( sort keys %{$user->externals()} ) {
		$self->logDebug("callee", $callee);		
		my $external = $user->externals()->{$callee};
		next if not exists $role->methods()->{$callee};
		
		#### IF PARENT EXISTS, ONLY ADD UML IF PARENT
		#### MAKES CALL TO USER METHOD WHICH MAKES CALL TO ROLE
		next if defined $parent and not $self->parentCallsCaller($modulename, $parent, $external);
		
		$self->logDebug("CALL TO $callee FOUND in methods external", $external);
		my @callers = sort keys %{$external->{caller}};
		foreach my $caller ( @callers ) {
			$uml->{$username} = [] if not exists $uml->{$username};
			push @{$uml->{$username}}, { 
				username=>	$user->modulename(),
				rolename=>	$role->modulename(),
				source 	=> 	$caller,
				count	=> 	$external->{caller}->{$caller},
				target	=>	$callee
			};
		}
	}
	
	foreach my $submodulename ( keys %{$user->roles()} ) {
		$self->logDebug("submodulename", $submodulename);
		my $subrole = $user->roles()->{$submodulename}->{object};
		#$self->logDebug("subrole", $subrole);
		$self->logDebug("subrole->modulename", $subrole->modulename());
		$self->logDebug("subrole->roleSummary", $subrole->roleSummary());
		#$self->logDebug("subrole", $subrole);
		$self->logDebug("subrole->toString", $subrole->toString());

		$self->checkRoleCalled($role, $subrole, $uml, $user);
	}
	
	
	$self->logDebug("modulename $username returning uml", $uml);
	
	return $uml;
}

method parentCallsCaller ($modulename, $parent, $external) {
	my $message = "modulename $modulename parent->modulename()";
	$message .= $parent->modulename();
	$message .= " external";
	$self->logDebug($message, $external);

	foreach my $methodname ( keys %{$external->{caller}} ) {
		next if $methodname eq "TOTAL";
		return 0 if not $parent->hasExternal($methodname);
	}

	return 1;
}
method printUml ($outfh, $role, $uml) {
	$self->logDebug("outfh", $outfh);
	$self->logDebug("role: $role");
	$self->logDebug("role->modulename()", $role->modulename());
	$self->logDebug("uml", $uml);
	my $rolename = $role->modulename();
	$self->logDebug("rolename", $rolename);
	
	##### PRINT EXTERNAL CALLS OF CLASSES IN A-Z ORDER
	my @modulenames = sort keys %{$uml};
	$self->logDebug("modulenames", \@modulenames);
	my $outputs = '';
	foreach my $modulename ( @modulenames ) {
		my $output = "$modulename\n";
		$output .= "\texternal_calls\n";
		$output .= "\t\t*$modulename\t*$rolename\n";
		$output .= $self->externalsToString($uml->{$modulename});

		print $outfh $output;
		print $output;
		
		$outputs .= $output;
	}

	return $outputs;
}

#### UTILS
method externalsToString ($externals) {
	my $string = '';

	foreach my $external ( @$externals ) {
		$string .= "\t\t";
		$string .= $external->{source};
		$string .= "\t";
		$string .= $external->{target};
		$string .= "\t";
		if ( $external->{count} > 1 ) {
			$string .= $external->{count};
			$string .= "\t";
		}
		$string .= "\n";
	}

	return $string;
}


method umlToString ($uml) {

}

method hashKeysToString ($hash) {
	return if not defined $hash;
	
	my $string = '';	
	foreach my $key ( keys %$hash) {
		$string .= "$key\n";
	}
	
	return $string;
}






}	#### Agua::Uml

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
#		$classes->{$class->modulename()} = $class;
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
