use MooseX::Declare;

class Test::Agua::View extends Agua::View with (Test::Agua::Common, Agua::Common) {
	
use Data::Dumper;
use Test::More;
use DBI;
use Test::DatabaseRow;
use Agua::DBaseFactory;

# INTS
has 'LOG'			=>  ( isa => 'Int', is => 'rw', default => 3 );

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'view'  		=>  ( isa => 'Str', is => 'rw' );


#### HOOKS FOR ADD/REMOVE VIEW FEATURES
has 'htmlroot'  	=>  ( isa => 'Str', is => 'rw' );
has 'location'  	=>  ( isa => 'Str', is => 'rw' );

# OBJECTS
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'views'		=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'viewobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new( backup	=>	1 );	}
);

######///}}}

method BUILD ($hash) {
}

method initialise ($json) {

	$self->setUpTestDatabase();
	$self->setDbh();
	my $dumpfile = $self->dumpfile();
	$self->reloadTestDatabase($dumpfile);
    $Test::DatabaseRow::dbh = $self->db()->dbh();
}

method testAddTrack ($originalfile, $inputfile, $addtrack, $addedfile) {
	diag("Test addTrack");

    $self->setUpFile($originalfile, $inputfile);
    $self->addTrack($addtrack, $inputfile);
    ok( -f $inputfile, "addTrack    file present after addTrack");
	ok(File::Compare::compare($addedfile, $inputfile) == 0, "addTrack    addTrackData success");    	
}

method testRemoveTrack ($originalfile, $inputfile, $removetrack, $removedfile) {
	diag("Test removeTrack");

    $self->setUpFile($originalfile, $inputfile);
	$self->removeTrack($removetrack, $inputfile);
    ok( -f $inputfile, "removeTrack    file present after addTrack");
	my $result = $self->readJson($inputfile, "trackInfo =");
	my $expected = $self->readJson($removedfile, "trackInfo =");
	is_deeply($result, $expected, "removeTrack    Trackdata successfully removed"); 
}

method testAddRemoveView ($json) {
	diag("Test addRemoveView");

    $self->logDebug("json", $json);

    #### INPUTS
    my $table       	=   "view";
    my $addmethod       =   "_addView";
    my $removemethod    =   "_removeView";
    my $requiredkeys    =   [
        'username',
		'project',
		'view'
    ];
    my $definedkeys =   [
        'username',
		'project',
		'view'
    ];
    my $undefinedkeys =   [
    ];

    $self->logDebug("Doing genericAddRemove(..)");
    $self->genericAddRemove(
        {
            json	        =>	$json,
            table	        =>	$table,
            addmethod	    =>	$addmethod,
            addmethodargs	=>	$json,
            removemethod	=>	$removemethod,
            removemethodargs=>	$json,
            requiredkeys	=>	$requiredkeys,
            definedkeys	    =>	$definedkeys,
            undefinedkeys	=>	$undefinedkeys
        }        
    );
    
}   #### testAddRemoveView



method testAddViewFeature {

=head2

#### PRODUCTION SOURCE
/nethome/ @@@@@ syoung/agua/Project1/Workflow9/jbrowse/test1/data

#### TEST SOURCE
/agua/t/cgi-bin/view/inputs/nethome/ @@@@@ syoung/agua/Project1/Workflow9/jbrowse/test1/data

#### PRODUCTION TARGET
/agua/html/plugins/view/jbrowse//users/ @@@@@@ admin/Project1/View1/data/tracks/chr22

#### TEST TARGET
/agua/t/cgi-bin/view/outputs/data/plugins/view/jbrowse/users/ @@@@@ admin/Project1/View1/data/tracks/chr22

#### CREATE TEST DIRS
mkdir -p /agua/t/cgi-bin/view/inputs/nethome/syoung/agua/Project1/Workflow9/jbrowse/test1/data
mkdir -p /agua/t/cgi-bin/view/outputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/tracks/chr22

#### CREATE TARGET trackInfo.js
emacs -nw /agua/t/cgi-bin/view/outputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/trackInfo.js

trackInfo = [
   {
      "url" : "data/tracks/{refseq}/control2/trackData.json",
      "type" : "FeatureTrack",
      "label" : "control2",
      "key" : "control2"
   }
]

#### BACKUP TARGET trackInfo.js
cp /agua/t/cgi-bin/view/outputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/trackInfo.js \
/agua/t/cgi-bin/view/outputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/trackInfo.bkp.js

#### COPY PRODUCTION SOURCE TO TEST SOURCE
cp -r /nethome/syoung/agua/Project1/Workflow9/jbrowse/test1/data/* \
/agua/t/cgi-bin/view/inputs/nethome/syoung/agua/Project1/Workflow9/jbrowse/test1/data


ll /agua/t/cgi-bin/view/inputs/nethome/syoung/agua/Project1/Workflow9/jbrowse/test1/data

	drwxrwxr-x 3 syoung syoung 4096 2011-12-06 15:46 ./
	drwxrwxr-x 3 syoung syoung 4096 2011-12-06 15:43 ../
	-rw-r--r-- 1 syougung syoung  164 2011-12-06 15:46 trackInfo.js
	drwxr-xr-x 3 syoung syoung 4096 2011-12-06 15:46 tracks/

=cut
	

	diag("Test addViewFeature");

	#### FILES
	my $originalinfofile    =   "$Bin/inputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/trackInfo.bkp.js";
	my $addedinfofile       =   "$Bin/inputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/trackInfo-added.js";
	my $infofile            =   "$Bin/outputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/trackInfo.js";
	my $sourcetracksdir		=	"$Bin/inputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/tracks";
	my $targettracksdir		=	"$Bin/outputs/data/plugins/view/jbrowse/users/admin/Project1/View1/data/tracks";

	my $json	=	{	
		$originalinfofile,
		$addedinfofile,
		$infofile,
		$sourcetracksdir,
		$targettracksdir,
		{
			username	=>	"admin",
			sessionId	=>	"9999999999.9999.999",
			mode		=>	"addViewFeature",
			sourceid	=>	"plugins_view_View_0",
			callback	=>	"_handleAddViewFeature",
			status		=>	"ready",
			token		=>	"abcdefghijklmnop",
			data 		=>	{
				sourceproject	=>	"Project1",
				sourceworkflow	=>	"Workflow9",
				feature			=>	"test1",
				project			=>	"Project1",
				view			=>	"View1",
				species			=>	"human",
				build			=>	"hg19",
			}
		}
	);
	
	#### START LOG
	$self->startLog($self->logfile());
	
	#### SET UP DIRS
	`mkdir -p $targettracksdir` if not -d $targettracksdir;
	`cp -r $sourcetracksdir/* $targettracksdir`;

	#### SET UP FILES
	$self->setUpFile($originalinfofile, $infofile);
	$self->setUpDirs("$Bin/inputs/data", "$Bin/outputs/data");

	#### ENSURE FEATURE DOES NOT EXIST IN viewfeature TABLE
	$self->data($data);
	$self->logDebug("BEFORE _removeViewFeature()");
	$self->_removeViewFeature($data);

	#### ADD VIEW FEATURE
	$self->logDebug("BEFORE addViewFeature()");
	$self->addViewFeature($json);
	
	#### TESTS
	ok(-f $infofile, "addViewFeature    infofile still present after addViewTrack");
	ok(File::Compare::compare($addedinfofile, $infofile) == 0, "addViewFeature    infofile correct");
	
	my $location = $self->getFeatureLocation();
	$self->checkFeatureLinks($location);
}

method checkFeatureLinks ($location) {

	my $feature = $self->feature();
	$self->logDebug("Linking directories for dynamic feature", $feature);
	my $chromodirs = $self->getChromoDirs();
	$self->logDebug("chromodirs: @$chromodirs");
	
	my $target_tracksdir = $self->getTargetTracksdir();
	foreach my $chromodir ( @$chromodirs )
	{
		my $chromopath = "$target_tracksdir/$chromodir";
		next if $chromodir =~ /^\./ or not -d $chromopath;
		$self->logDebug("Linking chromodir", $chromodir);

		my $sourcedir = "$location/data/tracks/$chromodir/$feature";
		$self->logDebug("Skipping because can't find sourcedir", $sourcedir) if not -d $sourcedir;
		next if not -d $sourcedir;
		
		my $targetdir = "$target_tracksdir/$chromodir/$feature";
		$self->logDebug("Checking link for chromosome", $chromodir);
		ok( -d $targetdir, "featureLinks    link found for chromosome: $chromodir") if -d $sourcedir;
		my $trackdatafile = "$targetdir/trackData.json";
		$self->logDebug("trackdatafile", $trackdatafile);
		my $pattern = qq{\\"label\\":\\"test1\\"};
		my $grep = qq{grep "$pattern" $trackdatafile};
		#$self->logDebug("grep", $grep);
		my $labelfound = ``;
		ok(defined $labelfound, "featureLinks    trackData.json file has label for feature: $feature");
	}
}

method getFeatureLocation () {
	#$self->logDebug("Returning location: " . $self->location());
	return $self->location();
}

method fakeTermination () {
	#$self->logDebug("");
}

method getHtmlRoot {
	#$self->logDebug("Returning htmlroot: " . $self->htmlroot());
	return $self->htmlroot();	
}

method testRemoveViewFeature ($json) {
	diag("Test removeViewFeature");

    #### INPUTS
    my $table       =   "viewfeature";
    my $addmethod       =   "_addViewFeature";
    my $removemethod    =   "_removeViewFeature";
    my $requiredkeys    =   [
        'username',
		'project',
		'view',
		'feature'
    ];
    my $definedkeys =   [
        'username',
		'project',
		'view',
		'feature'
    ];
    my $undefinedkeys =   [
    ];

	#### SET UP DATABASE
	$self->setUpTestDatabase();
    $Test::DatabaseRow::dbh = $self->db()->dbh();
	
    $self->logDebug("Doing genericRemove(..)");
    $self->genericRemove(
        {
            json	        =>	$json,
            table	        =>	$table,
            removemethod	=>	$removemethod,
            requiredkeys	=>	$requiredkeys,
            definedkeys	    =>	$definedkeys,
            undefinedkeys	=>	$undefinedkeys
        }        
    );
    
}   #### testRemoveViewFeature

method testAddRemoveViewFeature ($json) {
	diag("Test addRemoveViewFeature");

    #### INPUTS
    my $table       =   "viewfeature";
    my $addmethod       =   "_addViewFeature";
    my $removemethod    =   "_removeViewFeature";
    my $requiredkeys    =   [
        'username',
		'project',
		'view',
		'feature'
    ];
    my $definedkeys =   [
        'username',
		'project',
		'view',
		'feature'
    ];
    my $undefinedkeys =   [
    ];

    $self->logDebug("Doing genericAddRemove(..)");
    $self->genericAddRemove(
        {
            json	        =>	$json,
            table	        =>	$table,
            addmethod	    =>	$addmethod,
            addmethodargs	=>	$json,
            removemethod	=>	$removemethod,
            requiredkeys	=>	$requiredkeys,
            definedkeys	    =>	$definedkeys,
            undefinedkeys	=>	$undefinedkeys
        }        
    );
    
}   #### testAddRemoveViewFeature



}