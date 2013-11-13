use MooseX::Declare;

=head2

	PACKAGE		Instance::StarCluster

    PURPOSE
    
        1. REPRESENT A StarCluster INSTANCE
		
		2. DETECT WHETHER INSTANCE IS RUNNING BASED ON listclusters OUTPUT

=cut

class Agua::Instance::StarCluster with (Agua::Common::Util, Agua::Common::Logger) {
#### EXTERNAL MODULES
use File::Path;
use Data::Dumper;

# Booleans
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 0 );
has 'running'		=> ( isa => 'Bool|Undef', is => 'rw', default => undef );

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


####/////}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	$self->initialise($hash) if defined $hash;
}

method initialise ($hash) {
	$self->logDebug("Agua::Instance::StarCluster::initialise()");
	foreach my $key ( keys %{$hash} ) {
		$self->$key($hash->{$key}) if $self->can($key);
	}

	##### OPEN LOGFILE IF DEFINED
	#$self->openLogfile($self->logfile()) if $self->logfile();

	my $cluster = $self->cluster();
	$self->getClusterInfo($cluster) if defined $cluster;
}

method isRunning {
	my $clusterinfo = $self->getClusterInfo($self->cluster());
	$self->logDebug("clusterinfo", $clusterinfo);

	return 0 if not defined $clusterinfo or not $clusterinfo;
	return 0 if not $clusterinfo =~ /master running/ms;
	return 1;
}

method hasNodes {
	my $clusterinfo = $self->getClusterInfo($self->cluster());
	$self->logDebug("clusterinfo", $clusterinfo);

	return 0 if not defined $clusterinfo or not $clusterinfo;
	return 0 if $clusterinfo =~ /Cluster nodes: N\/A/ms;
	
	return 1;
}

method getClusterInfo ($cluster) {
	$self->logDebug("Agua::Instance::StarCluster::getClusterInfo(cluster)");
	$self->logDebug("cluster not defined") and return if not defined $cluster;
	$self->logDebug("cluster", $cluster) if defined $cluster;
	$self->logDebug("self->configfile is empty") if not $self->configfile();
	$self->logDebug("self->executable is empty") if not $self->executable();

	my $executable = $self->executable();
	my $configfile = $self->configfile();
	$self->logDebug("executable", $executable);
	$self->logDebug("configfile", $configfile);
	
	#### SET HOME
	$ENV{'HOME'} = "/var/www";
	my $command = "$executable -c $configfile listclusters $cluster 2>&1";
	$self->logError("executable executable not found: $executable") and exit if not -f $executable;
	
	$self->logDebug("command", $command);
	my $result = `$command`;
	$self->logDebug("result", $result);
	return if $result =~ /!!! ERROR - cluster \S+ does not exist/;
	
	return $result;
}

method parseClusterInfo ($clusterinfo) {
	$self->logDebug("Agua::Instance::StarCluster::parseClusterInfo(clusterinfo)");
	$self->logDebug("clusterinfo", $clusterinfo);
	my $cluster = $self->cluster();
	$self->logDebug("cluster", $cluster);

	if ( $clusterinfo =~ /!!! ERROR - cluster \S+ does not exist/ )
	{
		$self->running(0);
		return 0;
	}

	$self->launched($clusterinfo =~ /Launch time: ([^\n]+)/ms);
	$self->uptime($clusterinfo =~ /Uptime: ([^\n]+)/ms);
	$self->zone($clusterinfo =~ /Zone: ([^\n]+)/ms);
	$self->keypair($clusterinfo =~ /Keypair: (\S+)/ms);
	$self->totalnodes($clusterinfo =~ /Total nodes:\s+(\d+)/ms);
	
	my ($ebs) = $clusterinfo =~ /EBS volumes:\s*(.+)\nCluster nodes:/ms;
	return if not defined $ebs;
	
	$self->ebsvolumes([]) if $ebs eq "N/A";	
	my @vols = split "\n\\s*", $ebs if $ebs ne "N/A";
	$self->ebsvolumes(\@vols) if $ebs ne "N/A"; 
	
	my ($nodes) = $clusterinfo =~ /Cluster nodes:\s*(.+)\nTotal nodes:/ms;
	$self->logDebug("nodes", $nodes);
	if ( not defined $nodes or $nodes =~ /^\s*$/ or $nodes eq "N/A" )
	{
		$self->nodes([]);
	}
	else
	{
		my @array = split "\n", $nodes;
		$self->nodes(\@array);
	}
	
	$self->running(1) if defined $self->launched();
	return $self->running();
}


	
}	#### class Agua::Instance::StarCluster
 
