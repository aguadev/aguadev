use MooseX::Declare;
use Method::Signatures::Modifiers;

class Conf::Yaml with (Conf, Agua::Common::Logger, Agua::Common::Util) {

use YAML::Tiny;
use Data::Dumper;

# Bool
has 'memory'		=> ( isa => 'Bool', 	is => 'rw', default	=> 	0);
has 'backup'		=> ( isa => 'Bool', 	is => 'rw', default	=> 	1);

# Ints
has 'valueoffset'	=>  ( isa => 'Int', is => 'rw', default => 24 );
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'inputfile' 	=>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'outputfile' 	=> (	is	=>	'rw',	isa	=>	'Str'	);

# Objects
has 'memorystore'	=> ( isa => 'HashRef|Undef', is => 'rw', required => 0, default	=> 	undef );
has 'yaml' 	=> (
	is 		=>	'rw',
	isa 	=> 	'YAML::Tiny',
	default	=>	method {	YAML::Tiny->new();	}
);

#####////}}}}
method BUILD ($arguments) {
	$self->initialise($arguments);
}

method initialise ($arguments) {
	$self->setSlots($arguments);

	if ( defined $self->inputfile() and not defined $self->outputfile() ) {
		$self->outputfile($self->inputfile());	
	}
}

method read ($inputfile) {
=head2

	SUBROUTINE 		read
	
	PURPOSE
	
		READ CONFIG FILE AND STORE VALUES
		
=cut

	#$self->logCaller();
	$self->logNote("inputfile", $inputfile);
	$self->logNote("self->memory()", $self->memory());
	
	#### SET memorystore IF memory
	if ( $self->memory() ) {
		if ( defined $self->memorystore() ) {
			return $self->readFromMemory();
		}
		else {
			my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;

			$self->yaml($yaml);
			
			$self->memorystore($$yaml[0]);
		}
	}
	else {
		#open(FILE, "<", $inputfile) or die "Can't open inputfile: $inputfile\n";
		my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;
		
		$self->yaml($yaml);
	}
}

method write ($file) {
	$self->logNote("file", $file);
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	
	#$self->logNote("FINAL file", $file);
	
	my $yaml 		=	$self->yaml();
	#$self->logNote("yaml", $yaml);

	my $memory = $self->memory();
	$self->logNote("memory", $memory);
	
	return $self->writeToMemory($$yaml[0]) if $self->memory();

	return $yaml->write($file);
}

method getKey ($key, $subkey) {
	#$self->logCaller();
	$self->logNote("key", $key);
	$self->logNote("subkey", $subkey) if defined $subkey;

	$self->read($self->inputfile());

	return $self->_getKey($key, $subkey);
}

method _getKey ($key, $subkey) {
	$self->logNote("key", $key);
	$self->logNote("subkey", $subkey) if defined $subkey;

	my $yaml 		= 	$self->yaml();

	if ( $key =~ /^([^:]+):(\S+)$/ ) {
		my ($name, $subname) = $key =~ /^([^:]+):(\S+)$/;
		#$self->logNote("name", $name);		
		#$self->logNote("subname", $subname);		
		
		if ( not defined $subkey ) {
			return $yaml->[0]->{$name}->{$subname};
		}
		else {
			return $yaml->[0]->{$name}->{$subname}->{$subkey};
		}
	}
	else {
		if ( not defined $subkey ) {
			$self->logNote("NO name:subname IN KEY, NO subkey    yaml->[0]->{$key}", $yaml->[0]->{$key});
			return $yaml->[0]->{$key};
		}
		else {
			$self->logNote("NO name:subname IN KEY, subkey PRESENT    yaml->[0]->{$key}->{$subkey}", $yaml->[0]->{$key}->{$subkey});
			return $yaml->[0]->{$key}->{$subkey};
		}
	}
}

method setKey ($key, $subkey, $value) {
	$self->logNote("key", $key);
	$self->logNote("subkey", $subkey);
	$self->logNote("value", $value);
	$self->read($self->inputfile());
	$self->_setKey($key, $subkey, $value);
	$self->write($self->outputfile());
}

method _setKey ($key, $subkey, $value) {
	$self->logNote("key", $key);
	$self->logNote("subkey", $subkey);
	$self->logNote("value", $value);

	my $yaml 		= 	$self->yaml();
	if ( $key =~ /^([^:]+):(\S+)$/ ) {
		my ($name, $subname) = $key =~ /^([^:]+):(\S+)$/;
		#$self->logNote("name", $name);		
		#$self->logNote("subname", $subname);		
		
		if ( not defined $subkey ) {
			$yaml->[0]->{$name} = {} if not defined $yaml->[0]->{$name};
			$yaml->[0]->{$name}->{$subname} = $value;
		}
		else {
			$yaml->[0]->{$name} = {} if not defined $yaml->[0]->{$name};
			$yaml->[0]->{$name}->{$subname} = {} if not defined $yaml->[0]->{$name}->{$subname};
			$yaml->[0]->{$name}->{$subname}->{$subkey} = $value;
		}
	}
	else {
		if ( not defined $subkey ) {
			$yaml->[0]->{$key}	=	$value;
		}
		else {
			$yaml->[0]->{$key} = {} if not defined $yaml->[0]->{$key};
			$yaml->[0]->{$key}->{$subkey} = $value;
		}
	}
	
	$self->yaml($yaml);
}

method removeKey ($key) {
	$self->logNote("key", $key);

	$self->_removeKey($key);
	
	$self->write($self->outputfile());
}

method _removeKey ($key) {
	$self->logNote("key", $key);

	return if not defined $self->yaml()->[0]->{$key};
	
	return delete $self->yaml()->[0]->{$key};
}

method writeToMemory ($hash) {
	$self->logNote();
	#$self->logNote("hash", $hash);
	
	$self->memorystore($hash);
}

method readFromMemory {
	$self->logNote();
	
	$self->yaml()->[0] = $self->memorystore();
}


}	#### Conf::Yaml