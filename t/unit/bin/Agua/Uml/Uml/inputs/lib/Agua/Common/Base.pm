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
#use lib "$Bin/../../external";
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
    my $json         	= $self->json();
    my $username 		= $json->{username};
	my $isadmin 		= $self->isAdminUser($username);

	#### GET OUTPUT
	my $output;

	#### GET ADMIN-ONLY
	$output->{users} 			= $self->getUsers();
	$output->{packages} 		= $self->getPackages() if $isadmin;
	
	#### GET GENERAL
	$output->{projects} 		= $self->getProjects();
	$output->{workflows} 		= $self->getWorkflows();
	$output->{groupmembers} 	= $self->getGroupMembers();
    $output->{adminheadings}    = $self->getAdminHeadings();
    $output->{sharingheadings}  = $self->getSharingHeadings();
    $output->{access} 			= $self->getAccess();
	$output->{groups} 			= $self->getGroups();
	$output->{sources} 			= $self->getSources();
	$output->{apps} 			= $self->getApps();
	$output->{parameters} 		= $self->getParameters();
	$output->{stages} 			= $self->getStages();
	$output->{stageparameters} 	= $self->getStageParameters();
	$output->{views} 			= $self->getViews();
	$output->{viewfeatures} 	= $self->getViewFeatures();
	$output->{features} 		= $self->getFeatures();

	#### AMAZON INFO
	$output->{aws} 				= $self->getAws();
	$output->{regionzones} 		= $self->getRegionZones();

	#### REPO INFO
	$output->{hub} 		= $self->getHub();
	
	#### CLUSTER INFO
	$output->{amis} 			= $self->getAmis();
	$output->{clusters} 		= $self->getClusters();
	$output->{clusterworkflows} = $self->getClusterWorkflows();

	#### SHARED DATA
	$output->{sharedapps} 		= $self->getSharedApps();
	$output->{sharedparameters} = $self->getSharedParameters();
	$output->{sharedprojects} 	= $self->getSharedProjects();
	$output->{sharedsources} 	= $self->getSharedSources();
	$output->{sharedworkflows} 	= $self->getSharedWorkflows();
	$output->{sharedstages} 	= $self->getSharedStages();
	$output->{sharedstageparameters} = $self->getSharedStageParameters();
	$output->{sharedviews} 		= $self->getSharedViews();
	$output->{sharedviewfeatures} = $self->getSharedViewFeatures();

	#### CACHES
	$output->{filecaches}		= $self->getFileCaches();
	
	#### PRINT JSON AND EXIT
	use JSON -support_by_pp; 
	my $jsonParser = JSON->new();
	#my $jsonText = $jsonParser->encode->allow_nonref->pretty->get_utf8->($output);
    #my $jsonText = $jsonParser->pretty->indent->encode($output);
    my $jsonText = $jsonParser->encode($output);

	#### TO AVOID HIJACKING --- DO NOT--- PRINT AS 'json-comment-optional'
	print "{}&&$jsonText";
	return;
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

sub _updateTable {
=head2

	SUBROUTINE		_updateTable
	
	PURPOSE

		UPDATE ONE OR MORE ENTRIES IN A TABLE
        
	INPUTS
		
		1. NAME OF TABLE      

		2. HASH CONTAINING OBJECT TO BE UPDATED

		3. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
        
=cut
	my $self		=	shift;
	my $table		=	shift;
	my $hash		=	shift;
	my $required_fields		=	shift;
	my $set_hash	=	shift;
	my $set_fields	=	shift;
 	$self->logNote("Common::_updateTable(table, hash, required_fields, set_fields)");
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("set_hash not defined") and return if not defined $set_hash;
    $self->logError("set_fields not defined") and return if not defined $set_fields;
    $self->logError("table not defined") and return if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### GET WHERE
	my $where = $self->db()->where($hash, $required_fields);

	#### GET SET
	my $set = $self->db()->set($set_hash, $set_fields);
	$self->logError("set values not defined") and return if not defined $set;

	##### UPDATE TABLE
	my $query = qq{UPDATE $table $set $where};           
	$self->logNote("$query");
	my $result = $self->db()->do($query);
	$self->logNote("result", $result);
}

sub _addToTable {
=head2

	SUBROUTINE		_addToTable
	
	PURPOSE

		ADD AN ENTRY TO A TABLE
        
	INPUTS
		
		1. NAME OF TABLE      

		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
        
=cut

	my $self			=	shift;
	my $table			=	shift;
	my $hash			=	shift;
	my $required_fields	=	shift;
	my $inserted_fields	=	shift;
	
	#### CHECK FOR ERRORS
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("table not defined") and return if not defined $table;
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### GET ALL FIELDS BY DEFAULT IF INSERTED FIELDS NOT DEFINED
	$inserted_fields = $self->db()->fields($table) if not defined $inserted_fields;

	$self->logError("fields not defined") and return if not defined $inserted_fields;
	my $fields_csv = join ",", @$inserted_fields;
	
	##### INSERT INTO TABLE
	my $values_csv = $self->db()->fieldsToCsv($inserted_fields, $hash);
	my $query = qq{INSERT INTO $table ($fields_csv)
VALUES ($values_csv)};           
	$self->logDebug("$query");
	my $result = $self->db()->do($query);
	$self->logDebug("result", $result);
	
	return $result;
}

sub _removeFromTable {
=head2

	SUBROUTINE		_removeFromTable
	
	PURPOSE

		REMOVE AN ENTRY FROM A TABLE
        
	INPUTS
		
		1. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
		
		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. NAME OF TABLE      
=cut

	my $self		=	shift;	
	my $table		=	shift;
	my $hash		=	shift;
	my $required_fields		=	shift;
 	
    #### CHECK INPUTS
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("table not defined") and return if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### DO DELETE 
	my $where = $self->db()->where($hash, $required_fields);
	my $query = qq{DELETE FROM $table
$where};
	$self->logNote("\n$query");
	my $result = $self->db()->do($query);
	$self->logNote("Delete result", $result);		;
	
	return 1 if defined $result;
	return 0;
}


sub arrayToArrayhash {
=head2

    SUBROUTINE:     arrayToArrayhash
    
    PURPOSE:

        CONVERT AN ARRAY INTO AN ARRAYHASH, E.G.:
		
		{
			key1 : [ entry1, entry2 ],
			key2 : [ ... ]
			...
		}

=cut

	my $self		=	shift;
	my $array 		=	shift;
	my $key			=	shift;
	
	#$self->logNote("Common::arrayToArrayhash(array, key)");
	#$self->logNote("array: @$array");
	#$self->logNote("key", $key);

	my $arrayhash = {};
	for my $entry ( @$array )
	{
		if ( not defined $entry->{$key} )
		{
			$self->logNote("entry->{$key} not defined in entry. Returning.");
			return;
		}
		$arrayhash->{$entry->{$key}} = [] if not exists $arrayhash->{$entry->{$key}};
		push @{$arrayhash->{$entry->{$key}}}, $entry;		
	}
	
	#$self->logNote("returning arrayhash", $arrayhash);
	return $arrayhash;
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

	#### USE TEST FILE ROOT IF TEST USER
	$fileroot = $self->getTestFileroot() if $self->isTestUser($username);
	$self->logDebug("fileroot", $fileroot);

	$self->fileroot($fileroot);
	
	return $fileroot;	
}

sub isTestUser {
	my $self		=	shift;
	my $username	=	shift;
	$self->logCaller("");
	$self->logDebug("username", $username);


	$username		=	$self->username() if not defined $username;
	if ( $self->can('requestor') ) {
		$username		=	$self->requestor() if $self->requestor();
	}
	$self->logDebug("username", $username);

	my $testuser	=	$self->conf()->getKey("database", "TESTUSER");
	$self->logDebug("testuser", $testuser);

	return 0 if not defined $testuser;
	return 1 if defined $testuser and $testuser eq $username;
	return 0;
}

sub getTestFileroot {
	my $self		=	shift;

	my $testuser	=	$self->conf()->getKey("database", "TESTUSER");
	$self->logDebug("testuser", $testuser);
	my $aguadir = $self->conf()->getKey('agua', 'AGUADIR');
	my $installdir = $self->conf()->getKey('agua', 'INSTALLDIR');
	
	return "$installdir/t/nethome/$testuser/$aguadir";
}

1;

