package Agua::Uml::Proto;
use Moose::Role;
use Method::Signatures::Simple;

=head2

PACKAGE		Agua::Uml::Proto

PURPOSE

		1. BASE METHODS FOR Agua::Uml

=cut


method getContents ($filepath) {
	$self->logCaller("filepath", $filepath);
	$self->logDebug("Can't find filepath: $filepath") and return if not -f $filepath;

	my $contents = $self->getFileContents($filepath);

	$self->logError("Classfile is empty: $filepath") and return if not $contents;
	
	return $contents;
}
	
method setSlots ($contents) {
	$self->logDebug("");

	requires 'slots';

	my $slots = {};

	#### SET INTERNAL METHODS
	while ( $contents =~ /has '([^\']+)/g ) {
		$slots->{$1} = 1;
	}
	$self->logDebug("slots", $slots);

	$self->slots($slots);
}


#### 'METHOD' METHODS
method setMethods ($contents) {
	requires 'methods';
	$self->logDebug("");
	
	requires 'methods';

	$self->setSlots($contents) if not defined $self->slots();

	my $blocks;
	@$blocks = split "\\nmethod\\s+", $contents if $contents =~ "\nmethod\\s+";
	@$blocks = split "\\nsub\\s+", $contents if $contents =~ "\nsub\\s+";
	return if not defined $blocks or not @$blocks;
	$self->logDebug("no. blocks", scalar(@$blocks));
	
	#### SET INTERNAL METHODS
	shift @$blocks;
	my $methods;
	foreach my $block ( @$blocks ) {
		my ($methodname) = $block =~ /^(\S+)/;
		$methods->{$methodname} = {};
	}
	$self->methods($methods);
	$self->logNote("methods", $methods);
	$self->logDebug("no. methods", scalar(keys %$methods));
}

method hasExternal ($methodname) {
	$self->logDebug("methodname", $methodname);
	$self->logDebug("self->externalsToString", $self->externalsToString());
	
	return 1 if defined $self->externals()->{$methodname};
	
	return 0;
}

#### CALL METHODS
method setCalls ($contents) {
	
	$self->setMethods($contents) if not defined $self->methods();
	
	my $blocks;
	@$blocks = split "\\n(method|sub)\\s+", $contents;
	$self->logDebug("no. blocks", scalar(@$blocks));
	shift @$blocks;

	#### SET CALLS
	my $calls;
	foreach my $block ( @$blocks ) {
		my ($methodname) = $block =~ /^(\S+)/;
		my $lines;
		@$lines = split "\n", $block;
		shift @$lines;
		
		foreach my $line ( @$lines ) {
			my ($call) = $line =~ /\$self->([^\$^\(^\s]+)/;
			next if not defined $call;
			
			if ( $self->methods()->{$call} ) {
				#$self->logDebug("INTERNAL CALL: $call");
				$self->logCall($self->internals(), $call, $methodname);
			}
			else {
				#$self->logDebug("EXTERNAL CALL: $call");
				$self->logCall($self->externals(), $call, $methodname);
			}
		}
	}
	$self->logNote("self->internals", $self->internals());
	$self->logNote("self->externals", $self->externals());
	$self->logDebug("no. self->internals", scalar(keys %{$self->internals()}));
	$self->logDebug("no. self->externals", scalar(keys %{$self->externals()}));
}

method logCall ($hash, $call, $methodname) {
	#$self->logDebug("call", $call);
	$methodname = '' if not defined $methodname;
	if ( exists $hash->{$call} ) {
		#$self->logDebug("EXISTS self->externals()->{$call}");
		if ( exists $hash->{$call}->{caller}->{$methodname} ) {
			$hash->{$call}->{caller}->{$methodname}++;
		}
		else {
			$hash->{$call}->{caller}->{$methodname} = 1;
		}
	}
	else {
		##$self->logDebug("NOT EXISTS self->externals()->{$call}");
		$hash->{$call}->{caller}->{$methodname} = 1;
	}
	$hash->{$call}->{TOTAL}++;

}

#### ROLE METHODS
method setRoles ($contents, $basedir) {
	$self->logDebug("basedir", $basedir);
	return if not $contents;

	#### REMOVE POD
	$contents =~ s/\n=head.+?\n=cut\n//msg;
	
	my $roles = {};
	if ( $contents =~ /class \S+\s+[^\n]*with\s+([^\(^\)^\s]+)/ms ) {
		#$self->logDebug("\$1", $1);
		$roles->{$1} = {};
	}
	
	####
	elsif ( $contents =~ /class \S+\s+[^\n]*with\s+\((.+?)\)/ms ) {
		my $block = $1;
		#$self->logDebug("block", $block);
		my $subroles = $self->parseRoleLines($block);
		#$self->logDebug("subroles", $subroles);
		$roles = $self->addHashes($roles, $subroles);
	}
	
	#### GET with '' STATEMENTS
	while ( $contents =~ /with '([^']+)';/g ) {
		$roles->{$1} = {};
	}
	
	my @array = sort keys %$roles;
	$self->logDebug("BEFORE INSTANTIATED roles", \@array);
	
	my $showlog = $self->SHOWLOG();
	$self->SHOWLOG(2);


$self->SHOWLOG(5) if $self->modulename() eq "Agua::View";
		
	#### INSTANTIATE ROLES
	#$self->logDebug("BEFORE INSTANTIATED keys \%roles", keys %$roles);
	foreach my $rolename ( keys %$roles ) {
		$self->logDebug("rolename", $rolename);
		
		my $path = $self->moduleToPath($rolename, $basedir);
		$self->logDebug("path", $path);
		if ( not -f $path ) {
			$self->logDebug("Skipping rolename $rolename because can't find path", $path);
			$self->logDebug("DOING delete roles->{$rolename}");
			delete $roles->{$rolename};
			next;
		}
		
		$self->logDebug("roles->{$rolename}", $roles->{$rolename});
		
		$self->logGroup("setRoles    ADD ROLE");
		
		require Agua::Uml::Role;
		my $role = Agua::Uml::Role->new({
			stringindent	=>	$self->stringindent() . "\t",
			sourcefile		=>	$path
			,
			SHOWLOG			=>	$self->SHOWLOG(),
			PRINTLOG		=>	$self->PRINTLOG(),
			indent			=>	$self->indent()
		});
		$self->logDebug("role: $role");
		$self->logDebug("role->modulename() not defined") if not defined $role->modulename();

		$self->logGroupEnd("setRoles    ADD ROLE");

		next if not defined $role or not defined $role->modulename();
		
		$roles->{$rolename}->{object} = $role;
	}

	$self->SHOWLOG($showlog);


	#$self->logDebug("AFTER INSTANTIATED keys \%roles", keys %$roles);
	@array = sort keys %$roles;
	$self->logDebug("AFTER INSTANTIATED roles", \@array);

	
	return $self->roles($roles);
}

method parseRoleLines ($block) {
	$self->logDebug("block", $block);
	my $roles = {};
	my @lines = split "\n", $block;
	#$self->logDebug("lines", @lines);
	foreach my $line ( @lines ) {
		#$self->logDebug("line", $line);
		my ($role) = $line =~ /([\w:]+)/;
		#$self->logDebug("role", $role);
		$roles->{$role} = {};
	}

	return $roles;
}
	
method setBaseDir ($inputfile) {
	$self->logDebug("inputfile", $inputfile);
	my $modulename = $self->modulename();
	$self->logError("modulename not defined") and exit if not defined $modulename;
	$self->logNote("modulename", $modulename);
	$self->logNote("inputfile", $inputfile);
	$modulename =~ s/::/\//g;
	$self->logNote("modulename", $modulename);
	my ($basedir) = $inputfile =~ /^(.+?)\/$modulename.pm$/;
	$self->logDebug("basedir", $basedir);
	
	return $self->basedir($basedir);
}

method moduleToPath ($modulename, $basedir) {
	$self->logDebug("modulename", $modulename);
	$self->logDebug("basedir", $basedir);
	$modulename =~ s/::/\//g;
	my $path = "$basedir/$modulename.pm";
	$self->logDebug("path", $path);
	
	return $path;
}

method hasRole ($role) {
#### role: Agua::Uml::Role object
	#$self->logDebug("role: $role");
	my $modulename = $role->modulename();
	$self->logDebug("Checking if this object uses role", $modulename);
	$self->logDebug("self->roles()", $self->rolesToString());

	$self->logDebug("returning 0") if not defined $self->roles();
	return 0 if not defined $self->roles();

	$self->logDebug("returning 1") if $self->roles()->{$modulename};
	return 1 if $self->roles()->{$modulename};
	
	
	
	$self->logDebug("returning 0");
	return 0;
}

#### STRING METHODS
method toString {
	my $string = "class " . $self->modulename();
	$string .= $self->slotSummary() if defined $self->slots();
	$string .= $self->roleSummary() if defined $self->roles();
	$string .= $self->methodSummary() if defined $self->methods();
	$string .= $self->internalSummary() if defined $self->internals();
	$string .= $self->externalSummary() if defined $self->externals();
	
	return $string;	
}

method rolesToString{
	$self->logNote("");
	return $self->hashKeysToString($self->roles());
}

method methodsToString{
	$self->logNote("");
	return $self->hashKeysToString($self->methods());
}

method externalsToString{
	$self->logNote("");
	return $self->hashKeysToString($self->externals());
}

method internalsToString{
	$self->logNote("");
	return $self->hashKeysToString($self->internals());
}

method hashKeysToString ($hash) {
	my $stringindent = $self->stringindent();
	my $string = '';	
	foreach my $key ( keys %$hash) {
#		$string .= "\t$stringindent$key\n";
		$string .= "$stringindent$key ";
	}
	
	return $string;
}

method summary {
	my $string = "";
	$string .= $self->modulename();
	$string .= "\n";
	
	#### ROLES
	$string .= $self->rolenameSummary();
	
	#### SLOTS
	$string .= $self->slotSummary();
	
	#### METHODS
	$string .= $self->methodSummary();
	
	#### INTERNALS
	$string .= $self->internalSummary();
	
	#### EXTERNALS
	$string .= $self->externalSummary();
}

method rolenameSummary {
	my $string = $self->stringindent() . "\troles: ";
	my $rolenames = $self->rolenames();
	$string .= $self->stringindent() . "@$rolenames" if defined $rolenames;
	$string .= "\n";

	return $string;
}

method roleSummary {
	my $string = $self->stringindent() . "\troles: ";
	return $string if not defined $self->roles();

	my @keys = sort keys %{$self->roles()};
	$string .= $self->stringindent() . "@keys";
	$string .= "\n";
	
	return $string;
}

method slotSummary {
	my $string = $self->stringindent() . "\tslots: ";
	return $string if not defined $self->slots();

	my @keys = sort keys %{$self->slots()};
	$string .= $self->stringindent() . "@keys";
	$string .= "\n";
	
	return $string;
}

method methodSummary {
	my $string = $self->stringindent() . "\tmethods: ";
	return $string if not defined $self->methods();

	my @keys = sort keys %{$self->methods()};
	$string .= $self->stringindent() . "@keys";
	$string .= "\n";
	
	return $string;
}

method internalSummary {
	my $string = $self->stringindent() . "\tinternals: ";
	return $string if not defined $self->internals();

	my @keys = sort keys %{$self->internals()};
	$string .= $self->stringindent() . "@keys";
	$string .= "\n";
	
	return $string;
}

method externalSummary {
	my $string = $self->stringindent() . "\texternals: ";
	return $string if not defined $self->externals();

	my @keys = sort keys %{$self->externals()};
	$string .= $self->stringindent() . "@keys";
	$string .= "\n";
	
	return $string;
}

method setRoleNames {
	my $nameshash = $self->recursiveRolenames();
	$self->logNote("nameshash", $nameshash);

	my @rolenames = sort keys %$nameshash;
	$self->logNote("rolenames", \@rolenames);
	
	$self->rolenames(\@rolenames);
}

method recursiveRolenames {
	$self->logNote("self->modulename", $self->modulename());
	my $rolenames;
	foreach my $rolename ( keys %{$self->roles()} ) {
		$self->logNote("self->modulename " . $self->modulename() . " rolename", $rolename);
		$rolenames->{$rolename} = 1;
		$self->logDebug("Getting role for rolename", $rolename);
		my $role = $self->roles()->{$rolename}->{object};
		$self->logNote("role: $role");
		my $subrolenames = $role->recursiveRolenames() if defined $role;
		$self->logNote("self->modulename " . $self->modulename() . " subrolenames", $subrolenames);
		$self->addHashes($rolenames, $subrolenames) if defined $subrolenames;
	}
	
	$self->logNote("self->modulename ".  $self->modulename() . " returning rolenames", $rolenames);

	return $rolenames;
}


1;
