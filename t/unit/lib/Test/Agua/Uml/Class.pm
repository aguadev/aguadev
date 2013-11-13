use MooseX::Declare;

=head2

PACKAGE		Test::Agua::Uml::Class

		1. CALCULATE AND CONTAIN THE ROLE USAGES AND INHERITANCES
		
			OF A CLASS
		
NOTES

		1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
		
		2. ROLES ARE INHERITED
		
			I.E., IF A INHERITS B WHICH USES C THEN A USES C
		
EXAMPLES

./uml.pl \
--role Test::Agua::Common::Cluster \
--targetfile /agua/lib/Agua/Common/Cluster.pm \
--sourcedir /agua/lib/Agua \
--outputfile /agua/log/uml.tsv \
--mode users

=cut

use strict;
use warnings;
use Carp;

class Test::Agua::Uml::Class with (Test::Agua::Common::Util) extends Agua::Uml::Class {

use FindBin qw($Bin);
use Test::More;

# Strings
has 'stringindent'	=> ( isa => 'Str|Undef', is => 'rw', default => ''	);
has 'classname'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'targetdir'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

# Objects
has 'slots'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'methods'	=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'roles'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'internals'	=> ( isa => 'HashRef|Undef', is => 'rw', default	=>	sub {{}} );
has 'externals'	=> ( isa => 'HashRef|Undef', is => 'rw', default	=>	sub {{}}	);

####/////}}}


#### INITIALISE
method initialise {
	$self->logDebug("");
	my $modulename	=	$self->modulename();
	$self->logDebug("BEFORE self->targetfile");
	my $targetfile	=	$self->targetfile();
	$self->logDebug("BEFORE self->targetdir");
	my $targetdir	=	$self->targetdir();
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("targetdir", $targetdir);
	
	return if not defined $targetfile;

	#### GET FILE CONTENTS
	my $contents = $self->getContents($targetfile);
	return if not defined $contents;
	
	#### SET CLASS NAME
	$self->setClassName($contents);
	$self->logDebug("MUST BE SET modulename", $modulename);
	return if not defined $self->modulename();
	
	#### SET BASE DIR
	my $basedir = $self->setBaseDir($targetfile);
	$self->logDebug("basedir", $basedir);

	#### SET ROLES
	$self->setRoles($contents, $basedir);
	
	#### SET ROLE NAMES
	$self->setRoleNames();
	
	#### SET SLOTS
	$self->setSlots($contents);

	#### SET METHODS
	$self->setMethods($contents);
	
	#### SET INTERNAL AND EXTERNAL CALLS
	$self->setCalls($contents);
}

method testSetRoles {
	diag("Class.t    DOING testSetRoles()\n");

	my $targetfile	=	"$Bin/inputs/lib/Agua/StarCluster.pm";

	#### GET FILE CONTENTS
	my $contents = $self->getContents($targetfile);
	return if not defined $contents;
	
	#### SET CLASS NAME
	$self->setClassName($contents);

	$self->targetfile($targetfile);
	$self->logDebug("targetfile", $targetfile);
	
	my $basedir = $self->setBaseDir($targetfile);
	
	#### SET ROLES
	$self->setRoles($contents, $basedir);
	
	my $roles = $self->rolesToString();
	$self->logDebug("roles", $self->rolesToString());
	my $expected = $self->rolesToString();
	ok($roles eq $expected, "rolesToString");
}

method testSetCalls {
	my $targetfile	=	"$Bin/inputs/lib/Agua/StarCluster.pm";
	$self->targetfile($targetfile);
	$self->logDebug("targetfile", $targetfile);
	
	#### GET FILE CONTENTS
	my $contents = $self->getContents($targetfile);
	
	#### SET ROLES
	$self->setCalls($contents);

	#### TEST
	my $externals = $self->externalsToString();
	$self->logDebug("externals", $self->externalsToString());
	my $expected = $self->getExpected("externalsToString");
	ok($externals eq $expected, "externalsToString");

	#### TEST
	my $internals = $self->internalsToString();
	$self->logDebug("internals", $self->internalsToString());
	$expected = $self->getExpected("internalsToString");
	ok($internals eq $expected, "internalsToString");
}

method testSetClassName {
	my $targetfile	=	$self->targetfile();
	my $targetdir	=	$self->targetdir();
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("targetdir", $targetdir);

	#### GET FILE CONTENTS
	my $contents = $self->getContents($targetfile);

	#### CHECK CLASS IN FILE AND SET CLASS IF ABSENT
	my $modulename = $self->setClassName($contents);
	$self->logDebug("modulename", $modulename);
	my $expected = $self->getExpected("modulename");
	ok($modulename eq $expected, "modulename");
}
	
method testSetMethods {
	my $targetfile	=	$self->targetfile();
	my $targetdir	=	$self->targetdir();
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("targetdir", $targetdir);

	my $contents = $self->getContents($targetfile);

	#### SET INTERNAL METHODS
	$self->setMethods($contents);
	
	my $methods = $self->methodsToString();
	$self->logDebug("methods", $self->methodsToString());
	my $expected = $self->getExpected("methodsToString");
	ok($methods eq $expected, "methodsToString");
}

method getExpected ($key) {

my $expecteds = {

modulename	=>	"Agua::StarCluster",
rolesToString	=>	qq{	Agua::Common::Database
	Agua::Common::Base
	Agua::Common::Cluster
	Agua::Common::Aws
	Agua::Common::Util
	Agua::Common::Ssh
	Agua::Common::Balancer
	Agua::Common::Logger
	Agua::Common::SGE
},
methodsToString => qq{	launchCluster
	dump
	getMonitor
	args
	deleteKeypair
	addKeypair
	_createVolume
	getopts
	setPE
	load
	isRunning
	stop
	writeConfigfile
	unsetQueue
	generateKeypair
	terminateCluster
	setQueue
	BUILD
	shortenString
	initialise
	start
},
internalsToString =>	qq{	launchCluster
	shortenString
	getopts
	args
	deleteKeypair
	terminateCluster
	initialise
	addKeypair
},

externalsToString => qq{	getAws
	keypairfile
	configfile
	db
	setSlots
	balancerRunning
	clusterIsRunning
	meta
	getConfigFile
	captureStderr
	addPEToQueue
	privatekey
	executable
	setKeypairfile
	instancetype
	availzone
	_removeQueue
	instance
	getQueuefile
	publiccert
	devices
	username
	workflow
	devs
	sources
	fileTail
	getBalancerOutputdir
	_addQueue
	clustertype
	awssecretaccesskey
	amazonuserid
	nodes
	getSgePorts
	_createConfigFile
	logError
	logDebug
	addPE
	plugins
	launchBalancer
	project
	getCluster
	monitor
	clusteruser
	unTaint
	help
	terminateBalancer
	sleepinterval
	cluster
	queueExists
	setDbh
	accesskeyid
	conf
	can
	sgeroot
	mountpoints
	outputdir
	fields
	nodeimage
	keyname
	config
	mounts
	sourcedirs
}

};
	return $expecteds->{$key};
	
}	#### getExpected



}	#### Test::Agua::Uml::Class