use MooseX::Declare;
#use Method::Signatures::Simple;

=head2	PACKAGE		View
	
=head3 PURPOSE

THIS MODULE ENABLES THE FOLLOWING USE SCENARIOS:

1. USER GENERATES JBROWSE JSON FILES IN OWN FOLDER

	1.1 CREATE FEATURES FOLDER
	
		1.1.1 CREATE WORKFLOW-SPECIFIC FEATURES FOLDER
		
	   users/__username__/__project__/__workflow__/features
	
	   TO HOLD INDIVIDUAL FEATURE JSON FILE DIRECTORIES INPUT FILES, E.G.:
	
	   users/__username__/__project__/__workflow__/features/__feature_name__

	   ... GENERATED FROM INDIVIDUAL FEATURE FILES, E.G.:
	
	   users/__username__/__project__/__workflow__/somedir/__feature_name__.gff


	1.2 SET LOCATION OF refSeqs.json FILE IF NOT DEFINED (E.G., WOULD BE
	
		SPECIFIED BY THE USER IN CASE OF CUSTOM GENOME)
	

	1.3 GENERATE JBrowse FEATURES IN PARALLEL ON A CLUSTER
	
		FOR EACH FEATURE:

			1.2.1 GENERATE A UNIQUE NAME FOR THIS PROJECT
			
				BY ADDING AN INCREMENTED DIGIT TO THE END OF THE FEATURE IN
				
				THE CASE OF DUPLICATE FEATURE NAMES IN THE SAME PROJECT OR
				
				WORKFLOW
				
			1.2.2 REGISTER FEATURE IN features TABLE
			
			1.2.3 GENERATE FEATURE IN FEATURES SUBFOLDER (Agua::JBrowse), E.G.:

			   users/__username__/__project__/__workflow__/features/__feature_name__

2. USER CREATES A NEW VIEW

	2.1 CREATE A NEW USER- AND PROJECT-SPECIFIC FOLDER INSIDE
	
		THE JBROWSE ROOT FOLDER:
		
	   plugins/view/jbrowse/users/__username__/__project__/__viewname__

		THE VIEW location WILL BE USED BY View.js TO LOCATE THE refSeqs.json AND
		
		trackList.json FILES FOR LOADING THE TRACKS.
		
		
	2.2 LINK (ln -s) ALL STATIC FEATURE TRACK SUBFOLDERS TO THE
	
		VIEW FOLDER (STATIC FEATURES ARE STORED IN THE feature TABLE)
	
		NB: LINK AT THE INDIVIDUAL STATIC FEATURE LEVEL, E.G.:
		
		jbrowse/species/__species__/__build__/data/tracks/chr*/FeatureDir 
		
		__NOT__ AT A HIGHER LEVEL BECAUSE WE WANT TO BE ABLE
		
		TO ADD/REMOVE DYNAMIC TRACKS IN THE USER'S VIEW FOLDER WITHOUT
		
		AFFECTING THE PARENT DIRECTORY OF THE STATIC TRACKS.
		
		THE STATIC TRACKS ARE MERELY INDIVIDUALLY 'BORROWED' AS IS.

	2.3	PRINT jbrowse_conf.json FILE STUB
	
		plugins/view/jbrowse/users/__username__/__project__/__view__/jbrowse_conf.json


3. USER ADDS/REMOVES TRACKS TO/FROM VIEW

	3.1 CREATE USER-SPECIFIC VIEW FOLDER:

		plugins/view/jbrowse/users/__username__/__project__/__view__/data

	3.2 ADD/REMOVE FEATURE trackData.json INFORMATION TO/FROM data/trackList.json
	
	3.3 RERUN generate-names.pl AFTER EACH ADD/REMOVE


=head2	SUBROUTINE		createFeaturesDir

=head3 	PURPOSE

CREATE USER-SPECIFIC FEATURES FOLDER:

users/__username__/__project__/__workflow__/features

TO HOLD INDIVIDUAL FEATURE INPUT FILES, E.G.:

users/__username__/__project__/__workflow__/features/_feature_name.gff

=cut


#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

use strict;
use warnings;

class Agua::View extends Agua::JBrowse with (Agua::Cluster::Checker,
	Agua::Cluster::Cleanup,
	Agua::Cluster::Jobs,
	Agua::Cluster::Loop,
	Agua::Cluster::Usage,
	Agua::Cluster::Util,
	Agua::Common::Base,
	Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::SGE,
	Agua::Common::Util,
	Agua::Common::View) {

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use File::Copy::Recursive;
use File::Remove;

#### INTERNAL MODULES
use Agua::Common::Util;
use Agua::DBaseFactory;
use Agua::JBrowse;
use Agua::Common::Exchange;

# Booleans
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 4 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Ints
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sourceid'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'token'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'callback'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'project'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'view'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'tracks'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'chromosome'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'start'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'stop'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'feature'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'workflow'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'viewdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'featuresdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'jbrowsedir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'data'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'json'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	isa 	=> 'Conf::Yaml',
	is 		=>	'rw',
	default	=>	sub { Conf::Yaml->new( {} );	}
);
has 'exchange'	=> ( isa => 'Agua::Common::Exchange', is  => 'rw', required	=>	0, lazy	=> 1, builder => "setExchange" );

####/////}

method BUILD ($hash) {
	#$self->initialise();
}

method initialise ($json) {
#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	$self->json($json);
	if ( $self->json() ) {
		foreach my $key ( keys %{$self->{json}} ) {
			next if not defined $json->{$key};
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($self->{json}->{$key}) if $self->can($key);

			if ( $key eq "data" ) {
				foreach my $subkey ( keys %{$self->{json}->{data}} ) {
					next if not defined $json->{data}->{$subkey};
					$json->{data}->{$subkey} = $self->unTaint($json->{data}->{$subkey});
					$self->$subkey($self->{json}->{data}->{$subkey}) if $self->can($subkey);
				}
			}
			
		}
	}
	$self->logDebug("json", $self->json());

	#### GET ENVIRONMENT VARIABLES
	my $envars = $self->getEnvars();
	$self->logDebug("envars", $envars);
	$self->username($envars->{username}) if defined $envars->{username};
	$self->project($envars->{project}) if defined $envars->{project};
	$self->workflow($envars->{workflow}) if defined $envars->{workflow};

	#### SET LOG
	my $username 	=	$self->username() || $self->json()->{username};
	my $logfile 	= 	$self->logfile();
	$self->logDebug("logfile", $logfile);
	my $mode		=	$json->{mode};
	$self->logDebug("mode", $mode);

	if ( not defined $logfile or not $logfile ) {
		my $identifier 	= 	"view";
		$self->setUserLogfile($username, $identifier, $mode);
		$self->appendLog($logfile);
	}

	#### SET CONF LOG (IN CASE View IS CALLED AS A COMPONENT
	#### I.E., NOT VIA view.cgi)
	$self->conf()->logfile($logfile) if not defined $self->conf()->logfile();
	$self->conf()->showlog($self->showlog()) if not defined $self->conf()->showlog();
	$self->conf()->printlog($self->printlog()) if not defined $self->conf()->printlog();
	
	#### SET DATABASE HANDLE
	$self->setDbh();

    #### VALIDATE IF ACCESSED FROM WEB
	$self->logError('User session not validated for username: $username') and exit if not $self->validate($username);

	#### SET Conf::Yaml INPUT FILE IF DEFINED
	if ( $self->conffile() ) {
		$self->conf()->inputfile($self->conffile());
	}

	#### SET Conf::StarCluster INPUT FILE IF DEFINED
	if ( $self->configfile() ) {
		$self->config()->inputfile($self->configfile());
	}

	#### LINK TO JBROWSE DATA species DIRECTORY
	$self->linkSpeciesDir();
}

method setExchange () {
	$self->logDebug("");
	
	my $exchange	=	Agua::Common::Exchange->new({
		logfile		=>	$self->logfile(),
		showlog		=>	$self->showlog(),
		printlog	=>	$self->printlog(),
		conf		=>	$self->conf()
	});
	$self->logDebug("exchange", $exchange);
	
	$self->exchange($exchange);
}

method setUserLogfile ($username, $identifier, $mode) {
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	
	return "$installdir/log/$username.$identifier.$mode.log";
}

method refreshView {
	my $json = $self->json();
	$self->logDebug("json", $json);

	#### CHECK INPUTS
	$self->checkInputs($json, ["username", "project", "view"]);
	$self->setViewStatus($json, "ready");
	my $views = $self->getViews();
	my $viewfeatures = $self->getViewFeatures();
	my $object = {};
	$object->{views} = $views;
	$object->{viewfeatures} = $viewfeatures;
	my $parser = $self->jsonparser();
	my $output = $parser->encode($object);
	$self->logDebug("output", $output);
	$self->logDebug("$output");
}

method addView {
	my $json = $self->json();
	$self->logDebug("json", $json);

	#### CHECK INPUTS
	$self->checkInputs($json, ["username", "project", "view", "species", "build"]);

	#### CHECK HTMLDIR (NEEDED LATER FOR DEFINING FILEPATHS)
	$self->checkHtmlRoot();
	
	#### IF EXISTS, REPORT AND QUIT
	if ( $self->_isView($json) ) {
		$self->logError("View already exists: $json->{view}");
		return;
	}
	
	#### ADD VIEW TO view TABLE
	$self->logError("Could not add view: $json->{view}") and exit if not $self->_addView($json);
	
	#### REPORT STATUS AND FAKE CGI TERMINATION
	$self->logStatus("Activating view: $json->{view}");

	#### LINK ALL STATIC FEATURE TRACKS TO VIEW DIR 
	$self->activateView(); 	
}

method activateView  {
	my $data	=	$self->json();
	$self->logDebug("data", $data);

	#### UPDATE VIEW STATUS
	$self->setViewStatus($data, "activating");
	
	##### GET VIEWDIR (TO BE RETURNED)
	my $viewdir = $self->setViewDir($data);
	
	#### CREATE TARGET tracks DIR IF NOT EXISTS
	my $target_tracksdir = $self->getTargetTracksdir();
	$self->logDebug("target_tracksdir", $target_tracksdir);
	File::Path::mkpath($target_tracksdir) if not -d $target_tracksdir;
	$self->logError("Can't create target_tracksdir: $target_tracksdir") and exit if not -d $target_tracksdir;
	
	#### SET SOURCE tracks DIR
	my $species	=	$data->{species};
	my $build	=	$data->{build};
	my $source_tracksdir 	=	$self->getSourceTracksdir($species, $build);
	$self->logDebug("source_tracksdir", $source_tracksdir);
	
	#### SET SEQUENCE DIR
	my $source_seqdir = $source_tracksdir;
	$source_seqdir =~ s/tracks$/seq/;
	my $target_seqdir = $target_tracksdir;
	$target_seqdir =~ s/tracks$/seq/;
	$self->logDebug("source_seqdir", $source_seqdir);
	$self->logDebug("target_seqdir", $target_seqdir);
	
	#### LINK SEQUENCE TRACKS
	$self->linkSeq($source_seqdir, $target_seqdir);
	
	#### LINK STATIC TRACKS TO VIEW 
	$self->linkTracks($source_tracksdir, $target_tracksdir);	
	
	#### ADD STATIC refSeq.js AND trackList.json FILES TO VIEW DIR
	$self->addRefseqsFile($viewdir, $species, $build);
	
	$self->addTrackListFile($viewdir, $species, $build);
	
	#### COPY names DIR TO data DIR IN VIEW DIR
	$self->copyNames($viewdir, $species, $build);	
	
	#### UPDATE VIEW STATUS
	$self->setViewStatus($data, "ready");

	#### NOTIFY CLIENT OF STATUS
	my $token 		=	$self->token();
	my $sourceid 	=	$self->sourceid();
	my $callback 	=	$self->callback();
	$self->logDebug("token", $token);
	$self->logDebug("sourceid", $sourceid);
	$self->logDebug("callback", $callback);

	$self->notifyStatus({
		sourceid	=> 	$sourceid,
		callback	=> 	$callback,
		token		=>	$token,
		queue		=> 	"routing",
		status		=> 	"ready",
		viewobject	=>	$data
	});
}

method notifyStatus ($data) {
	
	$self->logDebug("DOING self->openConnection() with data", $data);
	$self->logDebug("self->exchange", $self->exchange());
	
	my $connection = $self->exchange()->openConnection();
	$self->logDebug("connection", $connection);
	sleep(1);
	
	$self->logDebug("DOING self->exchange()->sendData(data)");
	return $self->exchange()->sendData($data);
}

method removeView {
	my $json = $self->json();
	$self->logDebug("json", $json);

	#### CHECK INPUTS
	$self->checkInputs($json, ["username", "project", "view"]);

	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "removing");

	#### CHECK HTMLDIR (NEEDED LATER FOR DEFINING FILEPATHS)
	$self->checkHtmlRoot();
	
	#### IF DOES NOT EXIST, REPORT AND QUIT
	$self->logError("View does not exist: $json->{view}") and return if not $self->_isView($json);

	#### REMOVE VIEW FROM view TABLE
	$self->logError("Could not remove view: $json->{view}") and return if not $self->_removeView($json);

	#### DELETE THE FILE SYSTEM
	$self->deleteViewDirs();

	#### REPORT STATUS AND FAKE CGI TERMINATION
	$self->logStatus("Deleted view: $json->{view}");
}

method deleteViewDirs {
	my $viewdir = $self->setViewDir($self->json());
 	$self->logDebug("viewdir", $viewdir);
	
	`rm -fr $viewdir`;
	#if ( not File::Remove::rm(\1, $viewdir) ) {
	#	$self->logError("Could not remove viewdir: $viewdir");
	#	exit;    
	#}

	$self->logError("Could not remove viewdir: $viewdir") and exit if -d $viewdir;
}

method addViewFeature {
	my $data = $self->data();
	$self->logDebug("data", $data);

	#### CHECK INPUTS
	$self->checkInputs($data, ["username", "project", "view", "feature", "sourceproject", "sourceworkflow", "species", "build"]);

	#### GET LOCATION 
	my $location = $self->getFeatureLocation();
	$data->{location}	= 	$location;
	
	#### IF HAS FEATURE, REPORT AND QUIT
	$self->logStatus("Feature already present in view: $data->{feature}") and exit if $self->_isViewFeature($data);
	
	$self->logDebug("BEFORE this->getViewStatus");
	my $status = $self->getViewStatus(); 
	if ( $status ne "ready" ) {
		$self->logError("Quit add feature due to current status: $status");
		return;
	}
	
	$self->logDebug("BEFORE this->_addViewFeature()");
	if ( not $self->_addViewFeature($data) ) {
		$self->setViewStatus($data, "error");
		$self->logError("Failed to add feature: $data->{feature}");
		return;
	}
	
	#### UPDATE VIEW STATUS
	$self->setViewStatus($data, "adding");
	
	#### ENSURE DB HANDLE STAYS ALIVE
	$self->setDbh() if not defined $self->db()->dbh();
	
	#### SET LOCATION OF SOURCE FEATURE DIR
	my $inputdir = $data->{sourceproject} . "/" . $data->{sourceworkflow};
	$self->setFeaturesDir($data->{username}, $inputdir);

	#### LINK DYNAMIC FEATURE TRACK TO VIEW DIR
	$self->linkDynamicFeature($location);
	$self->logDebug("AFTER linkDynamicFeature");

	#### UPDATE trackList.data
	$self->updateTrackinfo($location);
	$self->logDebug("AFTER updateTrackInfo");

	#### UPDATE VIEW STATUS
	$self->logDebug("DOING setViewStatus(data, ready)");
	$self->setViewStatus($data, "ready");

	#### NOTIFY CLIENT OF STATUS
	my $token 		=	$self->token();
	my $sourceid 	=	$self->sourceid();
	my $callback 	=	$self->callback();
	$self->logDebug("data", $data);
	$self->logDebug("token", $token);
	$self->logDebug("sourceid", $sourceid);
	$self->logDebug("callback", $callback);

	$self->notifyStatus({
		sourceid	=> 	$sourceid,
		callback	=> 	$callback,
		token		=>	$token,
		queue		=> 	"routing",
		status		=> 	"ready",
		featureobject	=>	$data
	});
}

method removeViewFeature {
	my $json = $self->json();
	$self->logDebug("json", $json);
	
	#### CHECK INPUTS
	$self->checkInputs($json, ["username", "project", "view", "feature"]);

	#### IF HAS FEATURE, REPORT AND QUIT
	$self->logError("Feature not present in view: $json->{feature}") and exit if not $self->_isViewFeature($json);
	
	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "removing");
	
	##### REPORT STATUS AND FAKE CGI TERMINATION
	#$self->logStatus("Removing feature", $json->{feature});
	##$self->fakeTermination();

	#### REMOVE TRACK DATA DIRECTORIES
	$self->removeTrackDirs();

	#### UPDATE trackList.json
	my $view_infofile = $self->getViewInfofile($self->species(), $self->build());
	$self->logDebug("view_infofile", $view_infofile);

	my $featureinfo;
	$featureinfo->{label} =  $self->feature();
	$featureinfo->{key} =  $self->feature();

	$self->removeTrackinfo($featureinfo, $view_infofile);
	
	my $success = $self->_removeViewFeature($json);
	$self->logDebug("_removeViewFeature success", $success);
	if ( not defined $success or not $success ) {
		$self->setViewStatus($json, "error");
		$self->logError("Can't remove feature", $json->{feature});
		return;
	}

	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "ready");
	$self->logStatus("Removed feature", $json->{feature});
}

method viewStatus {
	my $json = $self->json();
	$self->logDebug("json", $json);

	#### CHECK INPUTS
	$self->checkInputs($json, ["username", "project", "view"]);

	##### REPORT STATUS 
	my $status = $self->_viewStatus($json);
	if ( defined $status and $status ) {
		$self->logStatus($status);
	}
	else {
		$self->logStatus("none");
	}
}

method _viewStatus ($json) {
	$self->logDebug("");

	my $required = ["username", "project", "view"];
	my $where = $self->db()->where($json, $required);
	my $query = qq{SELECT status FROM view
$where};
	$self->logDebug("query", $query);
	return $self->db()->query($query);
}

method checkInputs ($hash, $required) {
	my $undefined 	= $self->db()->notDefined($hash, $required);
	$self->logError("Undefined inputs: @$undefined") and exit if @$undefined;
	foreach my $key ( keys %$hash ) {
		$self->$key($hash->{$key}) if $self->can($key);
	}
}

method checkHtmlRoot {
	my $htmldir		=	$self->conf()->getKey("agua", 'HTMLDIR');
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');
	my $htmlroot 	=	"$htmldir/$urlprefix"; 
	$self->logError("htmlroot not defined") and exit if not defined $htmlroot;	
}

method setViewStatus ($json, $status) {
	$self->logDebug("status", $status);
	$json->{status} 	= $status;
	my $query = qq{UPDATE view
SET status='$status'
WHERE username='$json->{username}'
AND project='$json->{project}'
AND view='$json->{view}'};
	$self->logDebug("query", $query);
	
	return $self->db()->do($query);
}

method getViewStatus {
	my $json 			= $self->json();
	my $query = qq{SELECT status FROM view
WHERE username='$json->{username}'
AND project='$json->{project}'
AND view='$json->{view}'};
	$self->logDebug("query", $query);
	
	return $self->db()->query($query);
}

method getFeatureLocation {
	my $json 	=	$self->json();
	my $query = qq{SELECT location
FROM feature
WHERE username='$json->{username}'
AND project='$json->{sourceproject}'
AND workflow='$json->{sourceworkflow}'
AND feature='$json->{feature}'
AND species='$json->{species}'
AND build='$json->{build}'};
	$self->logDebug("query", $query);
	my $location = $self->db()->query($query);
	if ( not defined $location or not $location ) {
		$self->setViewStatus($json, "error");
		$self->logError("No location for feature: $json->{feature}");
		exit;
	}
	
	return $location;	
}

method updateTrackinfo ($location) {
	$self->logDebug("");

	my $source_tracksdir = $self->getSourceTracksdir($self->species(), $self->build());
	$self->logDebug("source_tracksdir", $source_tracksdir);
	my $view_infofile = $self->getViewInfofile($self->species(), $self->build());
	$self->logDebug("view_infofile", $view_infofile);
	my $feature_infofile = $self->getFeatureInfofile($location);
	$self->logDebug("feature_infofile", $feature_infofile);

	$self->addTrackinfo($feature_infofile, $view_infofile);
}

method linkDynamicFeature ($location) {
	my $feature = $self->feature();
	$self->logDebug("Linking directories for dynamic feature", $feature);
	
	#### GET TARGET TRACKSDIR
	my $target_tracksdir = $self->getTargetTracksdir();
	$self->logDebug("target_tracksdir", $target_tracksdir);

	#### CREATE TARGET TRACKSDIR IF NOT EXISTS
	`mkdir -p $target_tracksdir` if not -d $target_tracksdir;
	$self->logDebug("AFTER created target_trackdir", $target_tracksdir);

	#### LIST OF CHROMOSOME SUBDIRS INSIDE 
	my $chromodirs = $self->getChromoDirs();

	#### LINK FEATURES TO TARGET TRACKSDIR
	foreach my $chromodir ( @$chromodirs )
	{
		my $chromopath = "$target_tracksdir/$chromodir";
		next if $chromodir =~ /^\./ or not -d $chromopath;
		$self->addLink("$location/data/tracks/$chromodir/$feature", "$target_tracksdir/$chromodir/$feature");
	}
}

method getChromoDirs {
	my $target_tracksdir = $self->getTargetTracksdir();
	$self->logDebug("target_tracksdir", $target_tracksdir);
	my $chromodirs = $self->getDirs($target_tracksdir);
	$self->logDebug("chromodirs: @$chromodirs");
	
	return $chromodirs;
}

method getHtmlRoot {
	#### CHECK HTMLDIR - NEED FOR DEFINING FILEPATHS
	my $htmldir		=	$self->conf()->getKey("agua", 'HTMLDIR');
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');
	my $htmlroot 	=	"$htmldir/$urlprefix"; 
	$self->logError("htmlroot not defined") and exit if not defined $htmlroot;
	return $htmlroot;	
}
method getTestHtmlRoot {
	#### CHECK HTMLDIR - NEED FOR DEFINING FILEPATHS
	my $htmldir		=	$self->conf()->getKey("agua", 'TESTHTMLDIR');
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');
	my $htmlroot 	=	"$htmldir/$urlprefix"; 
	$self->logError("htmlroot not defined") and exit if not defined $htmlroot;
	return $htmlroot;	
}

method removeTrackDirs {
	my $chromodirs;
	my $feature = $self->feature();
	my $target_tracksdir = $self->getTargetTracksdir();
	$self->logDebug("target_tracksdir", $target_tracksdir);

	opendir(DIR, $target_tracksdir)
		or die "Can't open target_tracksdir: $target_tracksdir\n";
	@$chromodirs = readdir(DIR);
	closedir(DIR) or die "Can't close target_tracksdir: $target_tracksdir";
	foreach my $chromodir ( @$chromodirs )
	{
		my $chromopath = "$target_tracksdir/$chromodir";
		next if $chromodir =~ /^\./ or not -d $chromopath;
		#File::Path::mkpath($chromopath) if not -d $chromopath;
		$self->logDebug("Removing link for feature in chromodir", $chromodir);
		$self->removeLink("$target_tracksdir/$chromodir/$feature");
	}	
}

method getFeatureInfofile (Str $location) {
	return "$location/data/trackList.json";
}

method getViewInfofile (Str $species, Str $build) {
	my $target_tracksdir = $self->getTargetTracksdir();
	return	"$target_tracksdir/../trackList.json"; 
}

method getTargetTracksdir {
	my $viewdir = $self->setViewDir($self->json());
	return "$viewdir/data/tracks";
}

method getSourceTracksdir (Str $species, Str $build) {
	my $htmldir		=	$self->conf()->getKey("agua", 'HTMLDIR');
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');
	my $htmlroot 	=	"$htmldir/$urlprefix"; 
	$self->logDebug("htmlroot not defined") and exit if not defined $htmlroot;
	$self->logDebug("htmlroot", $htmlroot);	;
	my $source_tracksdir 	=	"$htmlroot/plugins/view/jbrowse/species/$species/$build/data/tracks";

	return $source_tracksdir;
}

method setJbrowseDir (Str $species, Str $build) {
	$self->logDebug("species", $species);
	$self->logDebug("build", $build);

	return $self->jbrowsedir() if $self->jbrowsedir();

	$self->logDebug("species not defined or empty")
		and return if not defined $species or not $species;
	$self->logDebug("build not defined or empty")
		and return if not defined $build or not $build;

	#### STATICALLY RETRIEVE 'DATA' KEY FROM *.conf FILE
	my $datakey = $self->conf()->getKey("agua", "DATA");
	$self->logDebug("datakey", $datakey);
	my $jbrowsedata = $self->conf()->getKey("data:$datakey", 'JBROWSEDATA');
	$self->logDebug("jbrowsedata not defined or empty")
		and return if not defined $jbrowsedata or not $jbrowsedata;
	$self->logDebug("jbrowsedata", $jbrowsedata);
	
	return $self->jbrowsedir("$jbrowsedata/$species/$build");
}

method addLink (Str $source, Str $target) {
	$self->logDebug("(source, target)");
	$self->logDebug("source", $source);
	$self->logDebug("target", $target);
	
	#### REMOVE LINK IF EXISTS
	$self->removeLink($target) if -l $target;
	
	#### ADD LINK
	my $command = "ln -s $source $target";
	`$command`;
	
	$self->logDebug("link exists") if -l $target;
	$self->logDebug("link DOES NOT exist") if not -l $target;

	return 1 if -l $target;
	return 0;
}

method removeLink (Str $target) {
	$self->logDebug("(source, target)");
	$self->logDebug("target", $target);
	my $command = "unlink $target";
	`$command`;
	
	$self->logDebug("link removed") if not -l $target;
	$self->logDebug("link not removed ") if -l $target;

	return 1 if not-l $target;
	return 0;
}

method copyNames (Str $viewdir, Str $species, Str $build) {
	#### COPY names DIR TO data DIR IN VIEW DIR
	$self->logDebug("()");

	#### SET SOURCE DIRECTORY
	my $datakey = $self->conf()->getKey("agua", "DATA");
	$self->logDebug("datakey", $datakey);
	my $jbrowsedata = $self->conf()->getKey("data:$datakey", 'JBROWSEDATA');
	$self->logError("Cannot find jbrowsedata directory: $jbrowsedata") if not -d $jbrowsedata;
	my $sourcedir = "$jbrowsedata/$species/$build/data/names";
	
	my $targetdir = "$viewdir/data/names";

	$self->logDebug("sourcedir", $sourcedir);
	$self->logDebug("targetdir", $targetdir);
	$self->logDebug("Returning because linked targetdir already exists", $targetdir) if -l $targetdir;

	$self->logDebug("Doing copy sourcedir:\n\n$sourcedir\n\nto:\n\n$targetdir\n");

	File::Copy::Recursive::rcopy($sourcedir, $targetdir);
	my $success = 1;
	$success = 0 if not -d $targetdir;
	$self->logDebug("success", $success);
	$self->logError("Failed to copy target:\n\n$sourcedir\n\nto:\n\n$targetdir") and exit if not $success;
}

method updateNames (Str $project, Str $view, Str $species, Str $build) {
	$self->logDebug("(viewdir, species, build)");
	my $jbrowse = $self->conf()->getKey("applications", 'JBROWSE');
	$self->logDebug("jbrowse", $jbrowse);
	my $executable = "$jbrowse/generate-names.pl";
	my $dir = $self->setViewDir($self->json());
	$dir.= "/data";
	
	my $command = "$executable --dir $dir";
	$self->logDebug("command", $command);
	print `$command`;
}

method addRefseqsFile (Str $viewdir, Str $species, Str $build) {
	$self->logDebug("viewdir", $viewdir);
	$self->logDebug("species", $species);
	$self->logDebug("build", $build);
	my $jbrowsedir = $self->setJbrowseDir($species, $build);
	my $refseqfile = "$jbrowsedir/data/seq/refSeqs.json";
	my $trackinfofile = "$jbrowsedir/data/seq/trackList.json";
	$self->logDebug("Doing copy $refseqfile to $viewdir/data/seq");
	my $copy_refseq = File::Copy::Recursive::rcopy($refseqfile, "$viewdir/data/seq");
	$self->logDebug("copy_refseq", $copy_refseq);
	$self->logError("Failed to copy refSeqs.json file: $refseqfile") and exit if not $copy_refseq;	
}

method addTrackListFile (Str $viewdir, Str $species, Str $build) {
	$self->logDebug("(viewdir, species, build)");
	my $jbrowsedir = $self->setJbrowseDir($species, $build);
	my $refseqfile = "$jbrowsedir/data/seq/refSeqs.json";
	my $trackinfofile = "$jbrowsedir/data/trackList.json";
	$self->logDebug("Doing copy $trackinfofile to $viewdir/data");
	my $copy_trackinfo = File::Copy::Recursive::rcopy($trackinfofile, "$viewdir/data");
	$self->logDebug("copy_trackinfo", $copy_trackinfo);
	$self->logError("Failed to copy trackList.json file: $trackinfofile") and exit if not $copy_trackinfo;
}

#### PRINT CONF FILE
method addConfFile ($viewdir) {
	my $contents = qq{// JBrowse JSON-format configuration file
{
    aboutThisBrowser: {
        title: '<i>Agua</i>',
        description: 'Browser for visualization of genomic data produced Agua workflows'
    },
}
};
	my $file	=	$viewdir . "/jbrowse_conf.json";
	$self->writeJson($file, $contents, undef);
}
method linkSeq (Str $source_seqdir, Str $target_seqdir) {
	$self->logDebug("source_seqdir", $source_seqdir);
	$self->logDebug("target_seqdir", $target_seqdir);
	
	#### LINK ALL seq/chr* DIRECTORIES IN SOURCE DIR
	#### TO TARGET seq DIR
	`mkdir -p $target_seqdir` if not -d $target_seqdir;
	$self->logCritical("Can't create target_seqdir: $target_seqdir") and exit if not -d $target_seqdir;
	
	my $chromodirs = $self->getDirs($source_seqdir);
	$chromodirs = $self->sortNaturally($chromodirs);	
	$self->logDebug("chromodirs: @$chromodirs");
	
	foreach my $chromodir ( @$chromodirs ) {
		next if $chromodir !~ /^chr/;
		my $source = "$source_seqdir/$chromodir";
		my $target = "$target_seqdir/$chromodir";

		$self->logCritical("Can't link source to target\nsource: $source\ntarget", $target) and exit if not $self->addLink($source, $target);
	}	
}

method linkTracks (Str $source_tracksdir, Str $target_tracksdir) {
	$self->logDebug("source_tracksdir", $source_tracksdir);
	$self->logDebug("target_tracksdir", $target_tracksdir);
	
	#### LINK ALL FEATURE DIRECTORIES IN SOURCE tracks DIR TO TARGET tracks DIR
	my $featuredirs = $self->getDirs($source_tracksdir);
	$featuredirs = $self->sortNaturally($featuredirs);	
	$self->logDebug("featuredirs: @$featuredirs");
	
	foreach my $featuredir ( @$featuredirs ) {
		#my $trackdirs = $self->getDirs("$source_tracksdir/$featuredir");
		#$trackdirs = $self->sortNaturally($trackdirs);	
		#$self->logDebug("trackdirs: @$trackdirs");

		my $sourcedir = "$source_tracksdir/$featuredir";
		my $targetdir = "$target_tracksdir/$featuredir";
		next if not -d $sourcedir;

		$self->logDebug("Can't link sourcedir to targetdir\nsourcedir: $sourcedir\ntargetdir", $targetdir) and exit if not $self->addLink($sourcedir, $targetdir);
		
		#$trackdirs = $self->sortNaturally($trackdirs);	
		#$self->logDebug("trackdirs: @$trackdirs");
		
		##### CREATE TARGET TRACKS/chr* DIR
		#my $target_featuredir = "$target_tracksdir/$featuredir";
		#File::Path::mkpath($target_featuredir) if not -d $target_featuredir;
		#$self->logDebug("Can't create target_featuredir", $target_featuredir) and exit if not -d $target_featuredir;
		#
		#foreach my $trackdir ( @$trackdirs )
		#{
		#	next if $trackdir =~ /^\./;
		#	#my $source = "$source_tracksdir/$featuredir/$trackdir";
		#	#my $target = "$target_tracksdir/$featuredir/$trackdir";
		#	my $source = "$source_tracksdir/$trackdir/$featuredir";
		#	my $target = "$target_tracksdir/$trackdir/$featuredir";
		#	next if not -d $source;
		#
		#	$self->logDebug("Can't link source to target\nsource: $source\ntarget", $target) and exit if not $self->addLink($source, $target);
		#}
	}	
}

method createFeaturesDir {
	$self->logDebug("");

	$self->setFeaturesDir($self->username(), $self->inputdir());

	my $featuresdir = $self->featuresdir();
	$self->logDebug("featuresdir", $featuresdir);
	
	File::Path::mkpath($featuresdir);
	$self->logDebug("Can't create featuresdir", $featuresdir) and exit if not -d $featuresdir;
}	

method setFeaturesDir ($username, $inputdir) {
	my $userdir = $self->conf()->getKey("agua", 'USERDIR');
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
	$self->logDebug("userdir not defined") and exit if not defined $userdir;
	$self->logDebug("aguadir not defined") and exit if not defined $aguadir;
	
	my $featuresdir = "$inputdir/jbrowse";
	$featuresdir = $self->addEnvars($featuresdir);
	$self->logDebug("featuresdir", $featuresdir);

	$self->featuresdir($featuresdir);
}

method setViewDir ($json) {
	$self->logDebug("json", $json);

	my $userdir = $self->conf()->getKey("agua", 'USERDIR');
	$self->logDebug("userdir not defined") and exit if not defined $userdir;
	my $htmlroot = $self->getHtmlRoot();
	$self->logDebug("htmlroot not defined") and exit if not defined $htmlroot;
	$self->logDebug("htmlroot", $htmlroot);

	my $jbrowseroot;
	my $username = $json->{username};
	if ( $self->isTestUser($username) ) {
		$jbrowseroot = "$htmlroot/t/plugins/view/jbrowse";
	}
	else {
		$jbrowseroot = "$htmlroot/plugins/view/jbrowse";
	}

	my $viewdir = "$jbrowseroot";
	$viewdir .= "/users";
	$viewdir .= "/" . $json->{username};
	$viewdir .= "/" . $json->{project};	
	$viewdir .= "/" . $json->{view};	
	$self->logDebug("viewdir", $viewdir);

	File::Path::mkpath($viewdir) if not -d $viewdir;
	$self->logError("Could not create viewdir: $viewdir") and exit if not -d $viewdir;

	$self->viewdir($viewdir);
	
	return $viewdir;
}

method linkSpeciesDir {
	#### CREATE LINK TO species DIR FROM 'JBROWSEDATA' (E.G., /data/jbrowse/species)
	$self->logDebug("");

	my $datakey = $self->conf()->getKey("agua", "DATA");
	$self->logDebug("datakey", $datakey);
	my $jbrowsedata = $self->conf()->getKey("data:$datakey", 'JBROWSEDATA');
	$self->logError("Cannot find jbrowsedata directory: $jbrowsedata") if not -d $jbrowsedata;

	#### ENSURE HTML ROOT VALUE 
	my $htmldir		=	$self->conf()->getKey("agua", 'HTMLDIR');
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');
	my $htmlroot 	=	"$htmldir/$urlprefix"; 
	$self->logDebug("htmlroot not defined") and exit if not defined $htmlroot;
	my $jbrowseroot = "$htmlroot/plugins/view/jbrowse";
	my $datadir = "$jbrowseroot/species";
	
	#### SKIP IF DATADIR EXISTS ALREADY
	return if -l $datadir;

	#### 
	$self->logDebug("Doing addLink(jbrowsedata, datadir)");
	$self->addLink($jbrowsedata, $datadir);

	$self->logError("Cannot create link to datadir: $datadir") and exit if not -l $datadir;
}

#### GENERATE FEATURES jbrowseFeatures (AROUND)
around jbrowseFeatures {
	$self->logDebug("Agua.View.jbrowseFeatures()");
	$self->logDebug("env | grep SGE");

	$self->logDebug("Doing self->getEnvars()");
	$self->getEnvars();

	#### CHECK INPUTS
	$self->logDebug("username not defined: ") and exit if not $self->username();
	my $username = $self->username();
	$self->logDebug("username", $username);
	
	#### 1.1 CREATE USER-SPECIFIC FEATURES FOLDER
	$self->createFeaturesDir();

	#### SET LOCATION OF refSeqs.json FILE
	$self->setRefseqfile() if not $self->refseqfile();

	#### 1.2 GENERATE FEATURES IN PARALLEL ON CLUSTER (Agua::JBrowse)
	$self->$orig();
}

method registerFeature (Str $feature) {
	$self->logDebug("feature", $feature);
	
	my $location = $self->featuresdir();
	$location .= "/" . $feature;	
	
	my $feature_object;
	$feature_object->{username} = $self->username();
	$feature_object->{project} = $self->project();
	$feature_object->{workflow} = $self->workflow();
	$feature_object->{species} = $self->species();
	$feature_object->{build} = $self->build();
	$feature_object->{feature} = $feature;
	$feature_object->{location} = $location;
	$feature_object->{type} = "dynamic";
	my $success = $self->_addFeature($feature_object);
	$self->logDebug("success", $success);
};


}  #### END
