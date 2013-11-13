use MooseX::Declare;

=head2

	PACKAGE		SCInstance

    PURPOSE
    
        1. REPRESENT A StarCluster INSTANCE
		
		2. DETECT WHETHER INSTANCE IS RUNNING BASED ON listclusters OUTPUT

=cut

class Agua::SCInstance with (Agua::Common::Util, Agua::Common::Logger) {
#### EXTERNAL MODULES
use File::Path;
use Data::Dumper;

# Booleans
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 0 );
has 'running'		=> ( isa => 'Bool|Undef', is => 'rw', default => undef );

# Strings
has 'starcluster'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
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
	$self->initialise();
}

method initialise () {
	$self->logDebug("Agua::SCInstance::initialise()");
	
	##### OPEN LOGFILE IF DEFINED
	#$self->openLogfile($self->logfile()) if $self->logfile();
}

method isRunning {
	if ( not defined $self->running() )
	{
		my $clusterinfo = $self->getClusterInfo($self->cluster());

		return 0 if not defined $clusterinfo or not $clusterinfo;
		$self->parseClusterInfo($clusterinfo);
	}

	return $self->running();
}

method getClusterInfo ($cluster) {
	$self->logDebug("Agua::SCInstance::getClusterInfo($cluster)");
	$self->logDebug("cluster", $cluster);
	
	$self->logDebug("self->configfile is empty") if not $self->configfile();
	$self->logDebug("self->starcluster is empty") if not $self->starcluster();

	my $starcluster = $self->starcluster();
	my $configfile = $self->configfile();
	$self->logDebug("starcluster", $starcluster);
	$self->logDebug("configfile", $configfile);
	
	#### SET HOME
	$ENV{'HOME'} = "/var/www";
	my $command = "$starcluster -c $configfile listclusters $cluster 2>&1";
	$self->logError("starcluster executable not found: $starcluster") and exit if not -f $starcluster;
	
	$self->logDebug("command", $command);
	my $result = `$command`;
	$self->logDebug("result", $result);
	
	return $result;
}

method parseClusterInfo ($clusterinfo) {
	$self->logDebug("clusterinfo", $clusterinfo);
	my $cluster = $self->cluster();
	$self->logDebug("cluster", $cluster);
	return if not defined $clusterinfo;
	return if not defined $cluster;
	
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
	$self->ebsvolumes([]) if $ebs eq "N/A";
	my @vols = split "\n\\s*", $ebs if $ebs ne "N/A";
	$self->ebsvolumes(\@vols) if $ebs ne "N/A"; 
	
	my ($nodes) = $clusterinfo =~ /Cluster nodes:\s*(.+)\nTotal nodes:/ms;
	$self->logDebug("nodes", $nodes);
	if ( $nodes =~ /^\s*$/ or $nodes eq "N/A" )
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


	
}	#### class Agua::SCInstance
 
