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


	1.2 SET LOCATION OF refSeqs.js FILE IF NOT DEFINED (E.G., WOULD BE
	
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

		THE VIEW location WILL BE USED BY View.js TO LOCATE THE refSeqs.js AND
		
		trackInfo.json FILES FOR LOADING THE TRACKS.
		
		
	2.2 LINK (ln -s) ALL STATIC FEATURE TRACK SUBFOLDERS TO THE
	
		VIEW FOLDER (STATIC FEATURES ARE STORED IN THE feature TABLE)
	
		NB: LINK AT THE INDIVIDUAL STATIC FEATURE LEVEL, E.G.:
		
		jbrowse/species/__species__/__build__/data/tracks/chr*/FeatureDir 
		
		__NOT__ AT A HIGHER LEVEL BECAUSE WE WANT TO BE ABLE
		
		TO ADD/REMOVE DYNAMIC TRACKS IN THE USER'S VIEW FOLDER WITHOUT
		
		AFFECTING THE PARENT DIRECTORY OF THE STATIC TRACKS.
		
		THE STATIC TRACKS ARE MERELY INDIVIDUALLY 'BORROWED' AS IS.


3. USER ADDS/REMOVES TRACKS TO/FROM VIEW

	3.1 CREATE USER-SPECIFIC VIEW FOLDER:

		plugins/view/jbrowse/users/__username__/__project__/__view__/data

	3.2 ADD/REMOVE FEATURE trackData.json INFORMATION TO/FROM data/trackInfo.js
	
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
	Agua::Common::Util,
	Agua::Common::View,
	Agua::Common::Privileges) {
#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use File::Copy::Recursive;
use File::Remove;

#### INTERNAL MODULES
use Agua::Common::Util;
use Agua::DBaseFactory;
use Agua::JBrowse;

# Booleans
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );

# Ints
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'conffile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'project'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'view'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'feature'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'workflow'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'viewdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'featuresdir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'jbrowsedir'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'json'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

####/////}

method BUILD ($hash) {
	#$self->initialise();
}

method initialise ($json) {
	#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	$self->json($json);
	if ( $self->json() ) {
		foreach my $key ( keys %{$self->{json}} ) {
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($self->{json}->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("json", $self->json());

	#### SET LOG
	my $username 	=	$self->username() || $self->json()->{username};
	my $logfile 	= 	$self->logfile();
	$self->logDebug("logfile", $logfile);
	my $mode		=	$self->mode();
	$self->logDebug("mode", $mode);

	if ( not defined $logfile or not $logfile ) {
		my $identifier 	= 	"view";
		$self->setUserLogfile($username, $identifier, $mode);
		$self->appendLog($logfile);
	}

	#### SET CONF LOG (IN CASE View IS CALLED AS A COMPONENT
	#### I.E., NOT VIA view.cgi)
	$self->conf()->logfile($logfile) if not defined $self->conf()->logfile();
	$self->conf()->SHOWLOG($self->SHOWLOG()) if not defined $self->conf()->SHOWLOG();
	$self->conf()->PRINTLOG($self->PRINTLOG()) if not defined $self->conf()->PRINTLOG();
	
	#### SET DATABASE HANDLE
	$self->setDbh();

    #### VALIDATE IF ACCESSED FROM WEB
    $self->logError('User session not validated for username: $username') and exit if $self->json() and not $self->validate();

	#### GET ENVIRONMENT VARIABLES
	my $envars = $self->getEnvars();
	$self->logDebug("envars", $envars);
	$self->username($envars->{username}) if defined $envars->{username};
	$self->project($envars->{project}) if defined $envars->{project};
	$self->workflow($envars->{workflow}) if defined $envars->{workflow};

	#### SET Conf::Agua INPUT FILE IF DEFINED
	if ( $self->conffile() ) {
		$self->conf()->inputfile($self->conffile());
	}

	#### SET Conf::StarCluster INPUT FILE IF DEFINED
	if ( $self->configfile() )
	{
		$self->config()->inputfile($self->configfile());
	}

	#### LINK TO JBROWSE DATA species DIRECTORY
	$self->linkSpeciesDir();
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
	my $parser = $self->setJsonParser();
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
	$self->fakeTermination();	

	#### LINK ALL STATIC FEATURE TRACKS TO VIEW DIR 
	$self->activateView($json); 	
}

method activateView {
	my $json = $self->json();
	$self->logDebug("json", $json);

	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "activating");
	
	##### GET VIEWDIR (TO BE RETURNED)
	my $viewdir = $self->setViewDir($json);
	
	#### CREATE TARGET tracks DIR IF NOT EXISTS
	my $target_tracksdir = $self->getTargetTracksdir();
	$self->logDebug("target_tracksdir", $target_tracksdir);
	File::Path::mkpath($target_tracksdir) if not -d $target_tracksdir;
	$self->logError("Can't create target_tracksdir: $target_tracksdir") and exit if not -d $target_tracksdir;
	
	#### SET SOURCE tracks DIR
	my $species	=	$json->{species};
	my $build	=	$json->{build};
	my $source_tracksdir 	=	$self->getSourceTracksdir($species, $build);
	$self->logDebug("source_tracksdir", $source_tracksdir);
	
	#### LINK STATIC SEQ TO VIEW
	my $source_seqdir = $source_tracksdir;
	$source_seqdir =~ s/tracks$/seq/;
	my $target_seqdir = $target_tracksdir;
	$target_seqdir =~ s/tracks$/seq/;
	$self->logDebug("source_seqdir", $source_seqdir);
	$self->logDebug("target_seqdir", $target_seqdir);
	$self->linkSeq($source_seqdir, $target_seqdir);

	#### LINK STATIC TRACKS TO VIEW 
	$self->linkTracks($source_tracksdir, $target_tracksdir);	
	
	#### ADD STATIC refSeq.js AND trackInfo.js FILES TO VIEW DIR
	$self->addRefseqsFile($viewdir, $species, $build);
	
	$self->addTrackinfoFile($viewdir, $species, $build);

	#### COPY names DIR TO data DIR IN VIEW DIR
	$self->copyNames($viewdir, $species, $build);	

	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "ready");
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
	if ( not $self->_isView($json) ) {
		$self->setViewStatus($json, "error");
		$self->logError("View does not exist: $json->{view}");
		return;
	}

	#### REMOVE VIEW FROM view TABLE
	$self->logError("Could not remove view: $json->{view}") and exit if not $self->_removeView();

	#### REPORT STATUS AND FAKE CGI TERMINATION
	$self->logStatus("Deleting view: $json->{view}");
	#$self->fakeTermination();

	#### DELETE THE FILE SYSTEM
	$self->deleteViewDirs();

	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "ready");
}

method deleteViewDirs {
	my $viewdir = $self->setViewDir($self->json());
 	$self->logDebug("viewdir", $viewdir);
	
	if ( not File::Remove::rm(\1, $viewdir) ) {
		$self->logError("Could not remove viewdir: $viewdir");
		exit;    
	}
}

method addViewFeature {
	my $json = $self->json();
	$self->logDebug("json", $json);

	#### CHECK INPUTS
	$self->checkInputs($json, ["username", "project", "view", "feature", "sourceproject", "sourceworkflow", "species", "build"]);

	#### GET LOCATION 
	my $location = $self->getFeatureLocation();
	$json->{location}	= 	$location;
	
	#### IF HAS FEATURE, REPORT AND QUIT
	$self->logStatus("Feature already present in view: $json->{feature}") and exit if $self->_isViewFeature($json);
	
	$self->logDebug("BEFORE this->getViewStatus");
	my $status = $self->getViewStatus(); 
	if ( $status ne "ready" ) {
		$self->logError("Quit add feature due to current status: $status");
		return;
	}
	
	$self->logDebug("BEFORE this->_addViewFeature()");
	if ( not $self->_addViewFeature($json) ) {
		$self->setViewStatus($json, "error");
		$self->logError("Failed to add feature: $json->{feature}");
		return;
	}
	
	#### UPDATE VIEW STATUS
	$self->setViewStatus($json, "adding");
	
	#### REPORT STATUS AND FAKE CGI TERMINATION
	$self->logStatus("Adding feature: $json->{feature}");
	$self->fakeTermination();
	
	#### ENSURE DB HANDLE STAYS ALIVE
	$self->setDbh() if not defined $self->db()->dbh();
	
	#### SET LOCATION OF SOURCE FEATURE DIR
	my $inputdir = $json->{sourceproject} . "/" . $json->{sourceworkflow};
	$self->setFeaturesDir($json->{username}, $inputdir);

	#### LINK DYNAMIC FEATURE TRACK TO VIEW DIR
	$self->linkDynamicFeature($location);
	$self->logDebug("AFTER linkDynamicFeature");

	#### UPDATE trackInfo.js
	$self->updateTrackinfo($location);
	$self->logDebug("AFTER updateTrackInfo");

	#### UPDATE VIEW STATUS
	$self->logDebug("DOING setViewStatus(json, ready)");
	$self->setViewStatus($json, "ready");
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

	#### UPDATE trackInfo.js
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
	return "$location/data/trackInfo.js";
}

method getViewInfofile (Str $species, Str $build) {
	my $target_tracksdir = $self->getTargetTracksdir();
	return	"$target_tracksdir/../trackInfo.js"; 
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
	my $refseqfile = "$jbrowsedir/data/refSeqs.js";
	my $trackinfofile = "$jbrowsedir/data/trackInfo.js";
	$self->logDebug("Doing copy $refseqfile to $viewdir/data");
	my $copy_refseq = File::Copy::Recursive::rcopy($refseqfile, "$viewdir/data");
	$self->logDebug("copy_refseq", $copy_refseq);
	$self->logError("Failed to copy refSeqs.js file: $refseqfile") and exit if not $copy_refseq;	
}

method addTrackinfoFile (Str $viewdir, Str $species, Str $build) {
	$self->logDebug("(viewdir, species, build)");
	my $jbrowsedir = $self->setJbrowseDir($species, $build);
	my $refseqfile = "$jbrowsedir/data/refSeqs.js";
	my $trackinfofile = "$jbrowsedir/data/trackInfo.js";
	$self->logDebug("Doing copy $trackinfofile to $viewdir/data");
	my $copy_trackinfo = File::Copy::Recursive::rcopy($trackinfofile, "$viewdir/data");
	$self->logDebug("copy_trackinfo", $copy_trackinfo);
	$self->logError("Failed to copy trackInfo.js file: $trackinfofile") and exit if not $copy_trackinfo;
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
	
	my $chromodirs = $self->getDirs($source_tracksdir);
	$chromodirs = $self->sortNaturally($chromodirs);	
	$self->logDebug("chromodirs: @$chromodirs");
	
	foreach my $chromodir ( @$chromodirs ) {
		next if $chromodir !~ /^chr/;

		my $trackdirs = $self->getDirs("$source_tracksdir/$chromodir");
		$trackdirs = $self->sortNaturally($trackdirs);	
		$self->logDebug("trackdirs: @$trackdirs");
		
		#### CREATE TARGET TRACKS/chr* DIR
		my $target_chromodir = "$target_tracksdir/$chromodir";
		File::Path::mkpath($target_chromodir) if not -d $target_chromodir;
		$self->logDebug("Can't create target_chromodir", $target_chromodir) and exit if not -d $target_chromodir;

		foreach my $trackdir ( @$trackdirs )
		{
			next if $trackdir =~ /^\./;
			my $source = "$source_tracksdir/$chromodir/$trackdir";
			my $target = "$target_tracksdir/$chromodir/$trackdir";
			next if not -d $source;

			$self->logDebug("Can't link source to target\nsource: $source\ntarget", $target) and exit if not $self->addLink($source, $target);
		}
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

	return $self->viewdir() if $self->viewdir();
	
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

around jbrowseFeatures {
	$self->logDebug("Agua.View.jbrowseFeatures()");
	$self->logDebug("env | grep SGE");

	$self->logDebug("Doing self->setEnvars()");
	$self->getEnvars();

	#### CHECK INPUTS
	$self->logDebug("username not defined: ") and exit if not $self->username();
	my $username = $self->username();
	$self->logDebug("username", $username);
	
	#### 1.1 CREATE USER-SPECIFIC FEATURES FOLDER
	$self->createFeaturesDir();

	#### SET LOCATION OF refSeqs.js FILE
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
