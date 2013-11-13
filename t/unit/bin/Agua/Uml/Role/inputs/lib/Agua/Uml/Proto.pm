package Agua::Uml::Proto;
use Moose::Role;
use Method::Signatures::Simple;

=head2

PACKAGE		Agua::Uml::Proto

PURPOSE

		1. BASE METHODS FOR Agua::Uml

=cut

method setInternalMethods ($contents) {

	requires 'methods';
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
	$self->logDebug("methods", $methods);
}

method setCalls ($contents) {
	my $blocks;
	@$blocks = split "\\nmethod\\s+", $contents;
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
			my ($call) = $line =~ /\$self->([^\(^\s]+)/;
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
	$self->logDebug("self->internals", $self->internals());
	$self->logDebug("self->externals", $self->externals());
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

method setRoles ($targetdir, $classfile, $class) {
	my $contents 	=	$self->getFileContents($classfile);
	return if not $contents;
	
	my $roles = {};
	if ( $contents =~ /class $class\s+[^\{]*with\s+([^\(^\)^\s]+)/ms ) {
		$self->logDebug("\$1", $1);
		$roles->{$1} = 1;
	}
	elsif ( $contents =~ /class $class\s+with\s+\((.+?)\)/ms ) {
		my $block = $1;
		$self->logDebug("block", $block);
		my $subroles = $self->parseRoleLines($block);
		$self->logDebug("subroles", $subroles);
		$roles = $self->addHashes($roles, $subroles);
	}
	$self->logDebug("roles", $roles);
	
	##### EXPAND TO ROLES USED BY ROLES
	#foreach my $role ( keys %$roles ) {
	#	my $subroles = $self->getSubRoles($targetdir, $role)
	#}
	$self->roles($roles);
	$self->logDebug("roles", $roles);
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
		$roles->{$role} = 1;
	}

	return $roles;
}
	
method hasRole ($role) {
#### role: Agua::Uml::Role object
	my $rolename = $role->rolename();
	$self->logDebug("rolename", $rolename);
	$self->logDebug("self->roles()", $self->roles());

	return 1 if $self->roles()->{$rolename};

	

	return 0;
}



1;
