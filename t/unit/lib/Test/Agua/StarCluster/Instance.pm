use MooseX::Declare;

=head2

	PACKAGE		Test::Agua::StarCluster::Instance

    PURPOSE
    
        TEST Agua::StarCluster::Instance METHODS

=cut

class Test::Agua::StarCluster::Instance extends Agua::StarCluster::Instance {

use FindBin qw($Bin);
use Test::More;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Conf::Yaml;
use Conf::StarCluster;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Getopt::Simple;

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub {
		Conf::Yaml->new( backup	=>	1 );
	}
);

####/////}}

method BUILD ($hash) {
    $self->logDebug("");
}

#### TEST PARSE INFO
method testParseClusterInfo {
	
	my $executable = $self->conf()->getKey("agua", "STARCLUSTER");
	$self->executable($executable);
	$self->logDebug("executable", $executable);
	
	my $cluster = "syoung-smallcluster";
	$self->cluster($cluster);

	my $clusterlist = qq{-------------------------------------------------------------
	syoung-smallcluster (security group: \@sc-syoung-smallcluster)
	-------------------------------------------------------------
	Launch time: 2011-06-22 02:02:41
	Uptime: 21:09:31
	Zone: us-east-1a
	Keypair: id_rsa-admin-key
	EBS volumes: N/A
	Cluster nodes:
		 master running i-554b143b ec2-174-129-112-77.compute-1.amazonaws.com
	Total nodes: 1};
	
	diag("Test parseClusterList");
	my $parsed = $self->parseClusterList($clusterlist);
	$self->logDebug("parsed", $parsed);
	ok($parsed, "retrieved cluster info from cluster list");

	ok($self->launched() eq "2011-06-22 02:02:41", "launched");
	ok($self->uptime() eq "21:09:31", "uptime");
	ok($self->zone() eq "us-east-1a", "zone");
	ok($self->keypair() eq "id_rsa-admin-key", "keypair");
	ok($self->totalnodes() == "1", "total nodes");
	is_deeply($self->nodes(), ["master running i-554b143b ec2-174-129-112-77.compute-1.amazonaws.com"], "nodes");
	
}


}	#### class Test::Agua::StarCluster::Instance
