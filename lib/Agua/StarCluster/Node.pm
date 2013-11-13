use MooseX::Declare;

=head2

	PACKAGE		Agua::StarCluster::Node

    PURPOSE
    
        1. REPRESENT A StarCluster INSTANCE
		
		2. DETECT WHETHER INSTANCE IS RUNNING BASED ON listclusters OUTPUT

=cut

class Agua::StarCluster::Node with (Agua::Common::Util, Agua::Common::Logger) {
#### EXTERNAL MODULES
use File::Path;
use Data::Dumper;

# Booleans
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 0 );
has 'running'		=> ( isa => 'Bool|Undef', is => 'rw', default => undef );
has 'exists'		=> ( isa => 'Bool|Undef', is => 'rw', default => undef );

# Strings
has 'internalfqdn'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'internalip'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'instanceid'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'externalfqdn'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'externalip'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'status'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

####/////}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	$self->logDebug("DOING self->loadArgs()");
	$self->loadArgs($hash);

	$self->logDebug("DOING self->initialise()");
	$self->initialise();
}

method initialise {
	$self->logDebug("");
}

method loadArgs ($args) {
	$self->logDebug("args", $args);
	#### IF HASH IS DEFINED, ADD VALUES TO SLOTS
	if ( defined $args ) {
		foreach my $key ( keys %{$args} ) {
			$self->logDebug("ADDING key $key", $args->{$key});
			$args->{$key} = $self->unTaint($args->{$key});
			$self->$key($args->{$key}) if $self->can($key);
		}
	}
    
    $self->logDebug("Completed");
}

method load ($args) {
	$self->logDebug("args", $args);

	$self->logDebug("DOING self->clear()");
	$self->clear();
	
	$self->logDebug("DOING self->loadArgs()");
	$self->loadArgs($args);

	$self->logDebug("DOING self->initialise()");
	$self->initialise();
}

method clear {
	my $meta = Agua::StarCluster->meta();

	#### GET ATTRIBUTES
	my $attributes;
	@$attributes = $meta->get_attribute_list();
	$self->logDebug("attributes", $attributes);

	#### RESET TO DEFAULT OR CLEAR ALL ATTRIBUTES
	foreach my $attribute ( @$attributes ) {
        next if $attribute eq "SHOWLOG";
        next if $attribute eq "PRINTLOG";
        next if $attribute eq "db";
        
		my $attr = $meta->get_attribute($attribute);
		my $required = $attr->is_required;
		$required = "undef" if not defined $required;
		my $default 	= $attr->default;
		my $isa  		= $attr->{isa};
		$isa =~ s/\|.+$//;		
		my $ref = ref $default;
		my $value 		= $attr->get_value($self);
		#$self->logDebug("$attribute: $isa value", $value);
		next if not defined $value;

		if ( not defined $default ) {
			$attr->clear_value($self);
		}
		else {
			#$self->logDebug("SETTING VALUE TO DEFAULT", $default);
			if ( $ref ne "CODE" ) {
				$attr->set_value($self, $default);
			}
			else {
				$attr->set_value($self, &$default);
			}
		}
		$self->logNote("CLEARED $attribute ($isa)", $attr->get_value($self));
	}
}

method isRunning {
	return 1 if $self->status() eq "running";
	return 0;
}

	
}	#### class Agua::StarCluster::Node
 
