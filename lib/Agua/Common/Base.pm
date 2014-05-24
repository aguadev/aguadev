package Agua::Common::Base;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Base
	
	PURPOSE
	
		BASE METHODS FOR Agua::Common
		
=cut

has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../../";
use Data::Dumper;

##############################################################################
#				DATABASE TABLE METHODS
=head2

	SUBROUTINE		getData
	
	PURPOSE

		RETURN JSON STRING OF ALL WORKFLOWS FOR EACH
		
		PROJECT IN THE application TABLE BELONGING TO
		
		THE USER

	INPUT
	
		1. USERNAME
		
		2. SESSION ID
		
	OUTPUT
		
		1. JSON HASH { "projects":[ {"project": "project1","workflow":"...}], ... }

=cut

sub getData {
#### GET DATA OBJECT
	my $self		=	shift;
	$self->logNote("Common::getData()");
	
	#### DETERMINE IF USER IS ADMIN USER
    my $username 		= $self->username();
	my $isadmin 		= $self->isAdminUser($username);

	#### GET OUTPUT
	my $output;

	### ADMIN-ONLY
	$output->{users} 			= $self->getUsers();

	$output->{packages} 		= $self->getPackages() if $isadmin;
    $output->{appheadings}    	= $self->getAppHeadings();
	$output->{apps} 			= $self->getApps();
	$output->{parameters} 		= $self->getParameters();
	
	#### GENERAL
	$output->{projects} 		= $self->getProjects();
	$output->{workflows} 		= $self->getWorkflows();
	$output->{groupmembers} 	= $self->getGroupMembers();
    $output->{cloudheadings}    = $self->getCloudHeadings();

	#### SHARING
    $output->{sharingheadings}  = $self->getSharingHeadings();
    $output->{access} 			= $self->getAccess();
	$output->{groups} 			= $self->getGroups();
	$output->{sources} 			= $self->getSources();
	#$output->{aguaapps} 		= $self->getAguaApps();
	#$output->{aguaparameters} 	= $self->getAguaParameters();
	#$output->{adminapps} 		= $self->getAdminApps();
	#$output->{adminparameters} 	= $self->getAdminParameters();
	$output->{stages} 			= $self->getStages();
	$output->{stageparameters} 	= $self->getStageParameters();
	$output->{views} 			= $self->getViews();
	$output->{viewfeatures} 	= $self->getViewFeatures();
	$output->{features} 		= $self->getFeatures();
	
	#### AMAZON INFO
	$output->{aws} 				= $self->getAws();
	$output->{regionzones} 		= $self->getRegionZones();

	#### REPO INFO
	$output->{hub} 				= $self->getHub();
	
	#### CONF ENTRIES
	$output->{conf} 			= $self->getConf();

	#### CLUSTER INFO
	$output->{amis} 			= $self->getAmis();
	$output->{clusters} 		= $self->getClusters();
	$output->{clusterworkflows} = $self->getClusterWorkflows();

	#### SHARED DATA
	$output->{sharedprojects} 	= $self->getSharedProjects();
	$output->{sharedsources} 	= $self->getSharedSources();
	$output->{sharedworkflows} 	= $self->getSharedWorkflows();
	$output->{sharedstages} 	= $self->getSharedStages();
	$output->{sharedstageparameters} = $self->getSharedStageParameters();
	$output->{sharedviews} 		= $self->getSharedViews();
	$output->{sharedviewfeatures} = $self->getSharedViewFeatures();

	#### CACHES
	$output->{filecaches}		= $self->getFileCaches();

	#### REQUEST
	$output->{queries}			= $self->getQueries();
	$output->{downloads}		= $self->getDownloads();

	$self->logDebug("DOING self->exchange()->sendSocket(data)");
	return $self->notifyStatus($output);
}

sub getConf {
	my $self		=	shift;
	
	my $conf;
	$conf->{agua}->{opsrepo} 	=	$self->conf()->getKey("agua", "OPSREPO");
	$conf->{agua}->{privateopsrepo} =	$self->conf()->getKey("agua", "PRIVATEOPSREPO");
	$conf->{agua}->{appsdir} 	=	$self->conf()->getKey("agua", "APPSDIR");
	$conf->{agua}->{installdir}	=	$self->conf()->getKey("agua", "INSTALLDIR");
	$conf->{agua}->{reposubdir}	=	$self->conf()->getKey("agua", "REPOSUBDIR");
	$conf->{agua}->{repotype}	=	$self->conf()->getKey("agua", "REPOTYPE");
	$conf->{agua}->{aguauser}	=	$self->conf()->getKey("agua", "AGUAUSER");
	$conf->{agua}->{adminuser}	=	$self->conf()->getKey("agua", "ADMINUSER");

	#### SET LOGIN
	my $username = $self->username();
	my $query = qq{SELECT login FROM hub WHERE username='$username'};
	my $login = $self->db()->query($query);
	$self->logDebug("login", $login);
	$conf->{agua}->{login}	=	$login;
	
	return $conf;	
}

sub getTable {
=head2

	SUBROUTINE		getTable
	
	PURPOSE

		RETURN THE JSON STRING FOR ALL USER-RELATED ENTRIES IN
        
        THE DESIGNATED TABLE PROXY NAME (NB: ACTUAL TABLE NAMES
        
        DIFFER -- SOME ARE MISSING THE LAST 'S')

	INPUT
	
		1. USERNAME
		
		2. SESSION ID
        
        3. TABLE PROXY NAME, E.G., "stageParameters" RETURNS RELATED
        
            'stageparameter' TABLE ENTRIES
		
	OUTPUT
		
		1. JSON HASH { "projects":[ {"project": "project1","workflow":"...}], ...}

=cut

	my $self		=	shift;
	$self->logDebug("self->json", $self->json());

    #### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

    my $username = $self->json()->{username};
    my $tablestring = $self->json()->{table};

	my @tables = split ",", $tablestring;
    my $data = {};
	foreach my $table ( @tables )
	{
		#### CONVERT TO get... COMMAND
		my $get = "get" . $self->cowCase($table);
		$self->logNote("get", $get);
		
		#### QUIT IF TABLE PROXY NAME IS INCORRECT
		$self->logError("method $get not defined") and return unless defined $self->can($get);
	
		my $output = $self->$get();
		#$self->logDebug("output", $output);

	    $data->{lc($table)} = $output;
	}
    
	#### PRINT JSON AND EXIT
	use JSON -support_by_pp; 

	my $jsonParser = JSON->new();
    #my $jsonText = $jsonParser->objToJson($data, {pretty => 1, indent => 4});


    my $jsonText = $jsonParser->pretty->indent->encode($data);
    #my $jsonText = $jsonParser->encode($data);

	#### THIS ALSO WORKS
	#my $jsonText = $jsonParser->encode->allow_nonref->pretty->get_utf8->($output);
	####my $apps = $jsonParser->allow_singlequote(1)->allow_nonref->loose(1)->encode($output);

	#### TO AVOID HIJACKING --- DO NOT--- PRINT AS 'json-comment-optional'
	print "$jsonText\n";
	return;
}

##############################################################################
#				FILESYSTEM METHODS
=head2

	SUBROUTINE		getFileroot
	
	PURPOSE
	
		RETURN THE FULL PATH TO THE agua FOLDER WITHIN THE USER'S HOME DIR

=cut

sub getFileroot {
	my $self		=	shift;
	my $username	=	shift;
	$self->logNote("username", $username);

	#### RETURN FILE ROOT FOR THIS USER IF ALREADY DEFINED
	return $self->fileroot() if $self->fileroot() and not defined $username;
	
	#### OTHERWISE, GET USERNAME FROM JSON IF NOT PROVIDED
	if ( $self->can('json') ) {
		$username = $self->json()->{username} if not defined $username;
	}
	return if not defined $username;

	my $userdir = $self->conf()->getKey('agua', 'USERDIR');
	my $aguadir = $self->conf()->getKey('agua', 'AGUADIR');
	my $fileroot = "$userdir/$username/$aguadir";

	##### USE TEST FILE ROOT IF TEST USER
	#$fileroot = $self->getTestFileroot() if $self->isTestUser($username);
	#$self->logDebug("fileroot", $fileroot);

	$self->fileroot($fileroot);
	
	return $fileroot;	
}

sub isTestUser {
	my $self		=	shift;
	my $username	=	shift;
	#$self->logCaller("");
	$self->logNote("username", $username);


	$username		=	$self->username() if not defined $username;
	if ( $self->can('requestor') ) {
		$username		=	$self->requestor() if $self->requestor();
	}
	$self->logNote("username", $username);

	my $testuser	=	$self->conf()->getKey("database", "TESTUSER");
	$self->logNote("testuser", $testuser);

	return 0 if not defined $testuser;
	return 1 if defined $testuser and defined $username and $testuser eq $username;
	return 0;
}

#sub getTestFileroot {
#	my $self		=	shift;
#
#	my $testuser	=	$self->conf()->getKey("database", "TESTUSER");
#	$self->logDebug("testuser", $testuser);
#	my $aguadir = $self->conf()->getKey('agua', 'AGUADIR');
#	my $installdir = $self->conf()->getKey('agua', 'INSTALLDIR');
#	
#	return "$installdir/t/nethome/$testuser/$aguadir";
#}


1;

