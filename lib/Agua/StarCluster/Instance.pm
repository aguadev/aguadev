use MooseX::Declare;

=head2

	PACKAGE		StarCluster::Instance

    PURPOSE
    
        1. REPRESENT A StarCluster INSTANCE
		
		2. DETECT WHETHER INSTANCE IS RUNNING BASED ON listclusters OUTPUT

=cut

class Agua::StarCluster::Instance with (Agua::Common::Util, Agua::Common::Logger) {
#### EXTERNAL MODULES
use File::Path;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::StarCluster::Node;

# Boolean
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 0 );
has 'running'		=> ( isa => 'Bool|Undef', is => 'rw', default => undef );
has 'exists'		=> ( isa => 'Bool|Undef', is => 'rw', default => undef );

# Strings
has 'executable'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'launched'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'uptime'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'zone'			=> ( isa => 'Str|Undef', is => 'rw' );
has 'keypair'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'totalnodes'	=> ( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'ebsvolumes'	=> ( isa => 'ArrayRef|Undef', is => 'rw' );
has 'nodes'			=> ( isa => 'ArrayRef|Undef', is => 'rw' );
has 'master'		=> ( isa => 'Agua::StarCluster::Node|Undef', is => 'rw',
	default => sub { return Agua::StarCluster::Node->new({}); } );


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

	##### OPEN LOGFILE IF DEFINED
	#$self->openLogfile($self->logfile()) if $self->logfile();

	my $cluster = $self->cluster();
	
	#### GET CLUSTER LIST
	my $clusterlist = $self->getClusterList($cluster) if defined $cluster;
	return if not defined $clusterlist;
	
	#### PARSE CLUSTER LIST
	$self->parseClusterList($clusterlist);
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
	return $self->running();
	#my $clusterlist = $self->getClusterList($self->cluster());
	#$self->logDebug("clusterlist", $clusterlist);
	#
	#return 0 if not defined $clusterlist or not $clusterlist;
	#return 0 if not $clusterlist =~ /master running/ms;
	#return 1;
}

method hasNodes {
	my $nodes = $self->nodes();
	$self->logDebug("nodes", $nodes);

	return 1 if defined $nodes and @$nodes;
	return 0;
}

method getClusterList ($cluster) {
	$self->logCaller("");
	$self->logDebug("Agua::StarCluster::Instance::getClusterList(cluster)");
	$self->logDebug("cluster not defined") and return if not defined $cluster;
	$self->logDebug("cluster", $cluster) if defined $cluster;
	$self->logDebug("self->configfile is empty") if not $self->configfile();
	$self->logDebug("self->executable is empty") if not $self->executable();

	my $executable = $self->executable();
	my $configfile = $self->configfile();
	$self->logDebug("executable", $executable);
	$self->logDebug("configfile", $configfile);

	#### CHECK INPUTS
	$self->logError("executable not defined") and exit if not $executable;
	$self->logError("configfile not defined") and exit if not $configfile;
	
	#### SET HOME
	$ENV{'HOME'} = "/var/www";
	my $command = "$executable -c $configfile listclusters $cluster 2>&1";
	$self->logError("starcluster executable not found: $executable") and exit if not -f $executable;
	
	$self->logDebug("command", $command);
	my $clusterlist = `$command`;
	$self->logDebug("clusterlist", $clusterlist);
	return if not defined $clusterlist;
	return if $clusterlist =~ /!!! ERROR - Oops! Looks like you've found a bug in StarCluster/ms;
	return if $clusterlist =~ /!!! ERROR - AuthFailure: AWS was not able to validate the provided access credentials/;	
	
	return $clusterlist;
}

method parseClusterList ($clusterlist) {
	$self->logDebug("clusterlist", $clusterlist);
	my $cluster = $self->cluster();
	$self->logDebug("cluster", $cluster);

	#### DEFAULT: EXISTS BUT NOT RUNNING
	$self->exists(1);
	$self->running(0);

	if ( not defined $clusterlist
		or $clusterlist =~ /!!! ERROR - cluster \S+ does not exist/ ) {
		$self->exists(0);
		return 0;
	}

	$self->launched($clusterlist =~ /Launch time: ([^\n]+)/ms);
	$self->running(1) if $clusterlist =~ /master running/ms;

	$self->logDebug("self->launched", $self->launched());
	$self->logDebug("self->running", $self->running());

	$self->uptime($clusterlist =~ /Uptime: ([^\n]+)/ms);
	$self->zone($clusterlist =~ /Zone: ([^\n]+)/ms);
	$self->keypair($clusterlist =~ /Keypair: (\S+)/ms);
	$self->totalnodes($clusterlist =~ /Total nodes:\s+(\d+)/ms);

	#### PARSE MASTER NODE
	$self->parseMaster($clusterlist);
	
	#### GET EBS
	my ($ebs) = $clusterlist =~ /EBS volumes:\s*(.+)\n\s*Cluster nodes:/ms;
	$self->logDebug("ebs", $ebs);	
	return if not defined $ebs;
	
	$self->ebsvolumes([]) if $ebs eq "N/A";	
	my @vols = split "\n\\s*", $ebs if $ebs ne "N/A";
	$self->ebsvolumes(\@vols) if $ebs ne "N/A"; 
	
	$self->parseNodes($clusterlist);	
	
	$self->logDebug("Returning self->running", $self->running());
	$self->running();
}

method parseMaster ($clusterlist) {
	$clusterlist =~ /^.+?master\s+(\S+)\s+(\S+)\s+(\S+)/ms;
	my $status			=	$1	||	"";
	my $instanceid 		=	$2 	||	"";
	my $externalfqdn 	=	$3 	|| 	"";
	$self->master()->load({
		alias			=>	"master",
		status			=>	$status,
		externalfqdn	=>	$externalfqdn,
		instanceid		=>	$instanceid
	})
}

method parseNodes ($clusterlist) {
	my ($nodelist) = $clusterlist =~ /Cluster nodelist:\s*(.+)\n\s*Total nodelist:/ms;
	$self->logDebug("nodelist", $nodelist);
	return $self->nodes([]) if not defined $nodelist;
	return $self->nodes([]) if $nodelist =~ /^\s*$/;
	return $self->nodes([]) if $nodelist eq "N/A";
	
	my $nodes;
	my @array = split "\n", $nodelist;
	foreach my $line ( @array ) {
		$line =~ /^.+?(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/ms;
		my $alias			=	$1	||	"";
		my $status			=	$2	||	"";
		my $instanceid 		=	$3 	||	"";
		my $externalfqdn 	=	$4 	|| 	"";
		
		next if not defined $alias or not $alias;
		
		my $node = Agua::StarCluster::Node->new({
			alias			=>	$alias,
			status			=>	$status,
			externalfqdn	=>	$externalfqdn,
			instanceid		=>	$instanceid
		});
		push @$nodes, $node;
	}
	$self->logDebug("nodes", $nodes);

	$self->nodes($nodes);
}


	
}	#### class Agua::StarCluster::Instance
 
