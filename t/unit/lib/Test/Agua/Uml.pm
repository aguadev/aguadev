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

class Test::Agua::Uml extends Agua::Uml {
#with (Test::Agua::Common::Util) 
if ( 1 ) {

use FindBin qw($Bin);
use Test::More;

# Objects
has 'classes'	=> ( isa => 'HashRef', is => 'rw', required => 0 );

#use Test::Agua::Uml::Role;
#use Test::Agua::Uml::Class;

}

####/////}}}

method testRoleUser {
	diag("roleUser");
	my $sourcefile	=	"$Bin/inputs/lib/Agua/Common/Cluster.pm";
	my $targetfile	=	"$Bin/inputs/lib/Agua/Workflow.pm";
	my $outputfile	=	"$Bin/outputs/roleuser--Agua-Workflow.tsv";

	$self->sourcefile($sourcefile);
	$self->targetfile($targetfile);
	$self->outputfile($outputfile);
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("outputfile", $outputfile);

	my $roleuser= $self->_roleUser($sourcefile, $targetfile, $outputfile);
	$self->logDebug("roleuser", $roleuser);
	my $expected = $self->getExpected("roleUser");
	$self->logDebug("expected", $expected);
	ok($roleuser eq $expected, "roleUser");
}

method testRoleUsers {
	diag("roleUsers");
	my $sourcefile	=	"$Bin/inputs/lib/Agua/Common/Cluster.pm";
	my $targetdir	=	"$Bin/inputs/lib/Agua";
	my $outputfile	=	"$Bin/outputs/Agua-Common-Cluster/roleuser--Agua-Workflow.tsv";

	$self->sourcefile($sourcefile);
	$self->targetdir($targetdir);
	$self->outputfile($outputfile);
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetdir", $targetdir);
	$self->logDebug("outputfile", $outputfile);

	my $roleusers	= $self->_roleUsers($sourcefile, $targetdir, $outputfile);
	$self->logDebug("roleusers", $roleusers);
	my $expected = $self->getExpected("roleUsers");
	$self->logDebug("expected", $expected);
	ok($roleusers eq $expected, "roleUsers");
}


method testUserRoles {
	diag("userRoles");
	my $targetfile	=	"$Bin/inputs/lib/Agua/Workflow.pm";
	my $outputfile	=	"$Bin/outputs/Agua-Workflow/userroles";

	$self->targetfile($targetfile);
	$self->outputfile($outputfile);
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("outputfile", $outputfile);

	my $roles = $self->_userRoles($targetfile, $outputfile);
	$self->logDebug("roles", $roles);
}

method getExpected ($key) {

my $expecteds = {
roleUser	=>	qq{Agua::Workflow
	external_calls
		*Agua::Workflow	*Agua::Common::Cluster
		addCluster	_addCluster	
		_createConfigFile	_createPluginsDir	
		addCluster	_removeCluster	
		setStarClusterObject	clusterInputs	
		runOnCluster	clusterIsBusy	
		setClusterCompleted	clusterIsBusy	
		_createConfigFile	getAdminKey	
		createQueue	getAdminKey	
		deleteQueue	getAdminKey	
		_createConfigFile	getCluster	
		createQueue	getCluster	
		setStarClusterObject	getCluster	
		getStatus	getClusterByWorkflow	
		runOnCluster	getClusterStatus	
		setStarClusterObject	getClusterStatus	
		_createConfigFile	getConfigFile	2	
		clusterStatus	getConfigFile	
		createQueue	getConfigFile	2	
		deleteQueue	getConfigFile	2	
		getStatus	getConfigFile	
		startStarCluster	getConfigFile	
},
	roleUsers	=>	qq{
}

};

	return $expecteds->{$key};
}	#### getExpected


}	#### Agua::Uml