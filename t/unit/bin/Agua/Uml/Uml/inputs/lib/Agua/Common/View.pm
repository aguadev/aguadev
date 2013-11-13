package Agua::Common::View;

=head2

	PACKAGE		Agua::Common::View
	
	PURPOSE
	
		VIEW METHODS FOR Agua::Common
		
=cut

use Moose::Role;
use Moose::Util::TypeConstraints;

#### EXTERNAL MODULES
use Data::Dumper;
sub getViews {
=head2

    SUBROUTINE     getViews
    
    PURPOSE
        
        RETURN AN ARRAY OF VIEW HASHES FOR THIS USER

=cut

    my $self        =   shift;

	#### VALIDATE USER USING SESSION ID	
	$self->logError("User not validated") and exit unless $self->validate();

	#### GET VIEWS    
    my $username = $self->username();
	$self->logDebug("username", $username);

    my $query = qq{SELECT * FROM view
WHERE username = '$username'};
    $self->logDebug("$query");
    my $views = $self->db()->queryhasharray($query);    

	#### GENERATE DEFAULT VIEWS IF EMPTY
	$views = $self->_defaultViews() if not defined $views;
    $self->logDebug("views", $views);
	
	return $views;
}

sub _defaultViews {
	my $self		=	shift;
	
    #### VALIDATE    
    $self->logError("User session not validated") and exit unless $self->validate();

	#### SET DEFAULT WORKFLOW
    my $data         	=	{};
	$data->{username} 	= $self->username();
	$data->{project} 	= "Project1";
	$data->{view} 		= "View1";
	$data->{species} 	= "human";
	$data->{build} 		= "hg19";
	$data->{chromosome} = "chr1";
	$data->{tracklist} 	= "knownGene";
	$data->{start} 		= "250000000";
	$data->{stop} 		= "35000000";
	$data->{status} 	= "ready";
		
	#### ADD WORKFLOW1
	my $success = $self->_addView($data);
 	$self->logError("Could not add view $data->{view} into  view table") and exit if not defined $success;

	#### DO QUERY
    my $username = $data->{username};
	$self->logDebug("username", $username);
	my $query = qq{SELECT * FROM view
WHERE username='$username'
ORDER BY project, view};
	$self->logDebug("$query");
	my $views = $self->db()->queryhasharray($query);
	$self->logDebug("views", $views);

	#### FORK AND RETURN
	my $pid;
	if ( $pid = fork() ) #### ****** Parent ****** 
	{
		$self->logDebug("PARENT    Returning views");
		return $views;	
	}
	elsif ( defined $pid ) #### ****** Child ******
	{
		#### FAKE CGI TERMINATION
		$self->fakeTermination(1);
		
		my $cgidir = $self->conf()->getKey("agua", "CGIDIR");
		my $executable = "$cgidir/view.cgi";

		$data->{sessionId} 	= 	$self->sessionId();
		$data->{mode}		=	"activateView";

		$data->{logfile} 	= 	$self->logfile();
		$data->{SHOWLOG} 	= 	$self->SHOWLOG();		
		$data->{PRINTLOG}	=	$self->PRINTLOG();		

		my $parser = JSON->new();
		my $json = $parser->encode($data);
		$self->logDebug("CHILD    json", $json);

		#### RUN activateView
		my $command = "echo '$json' | $executable";
		$self->logDebug("command", $command);
		exec($command);

		##### LINK ALL STATIC FEATURE TRACKS TO VIEW DIR 
		#$self->logDebug("CHILD    Doing activateView(json)");
		#require Agua::View;
		#my $logfile 	=	"/tmp/$json->{username}.view.log";
		#my $args = {};
		#$args->{json} 		= 	$json;
		#$args->{conf} 		= 	$self->conf();
		#$args->{logfile} 	= 	$logfile;
		#$args->{SHOWLOG} 	= 	$self->SHOWLOG();		
		#$args->{PRINTLOG}	=	$self->PRINTLOG();		
		#
		#my $view = Agua::View->new($args);
		#$view->activateView($json); 	
	}
    
    #### IF NEITHER CHILD NOR PARENT THEN COULDN'T OPEN PIPE
    else
    {
        $self->logError("Could not open pipe (fork failed): $!");
		exit;
    }
}

sub getViewFeatures {
=head2

    SUBROUTINE     getViewFeatures
    
    PURPOSE
        
        RETURN AN ARRAY OF VIEWFEATURE HASHES FOR THIS USER

=cut
    my $self        =   shift;
    $self->logDebug("Agua::Common::View::getViewFeatures()");
    my $json = $self->json();    

	#### VALIDATE USER USING SESSION ID	
	$self->logError("User not validated") and exit unless $self->validate();

	#### GET VIEWS    
    my $username = $json->{'username'};
    my $query = qq{SELECT * FROM viewfeature
WHERE username = '$username'};
    $self->logDebug("$query");
    my $viewfeatures = $self->db()->queryhasharray($query);    
    $self->logDebug("viewfeatures", $viewfeatures);
    $self->logDebug("viewfeatures", $viewfeatures);

	$viewfeatures = [] if not defined $viewfeatures;
    $self->logDebug("viewfeatures", $viewfeatures);
	
	return $viewfeatures;
}

sub getFeatures {
=head2

    SUBROUTINE     getFeatures
    
    PURPOSE
        
        RETURN AN ARRAY OF FEATURE HASHES FOR THIS USER

=cut

    my $self        =   shift;

	#### VALIDATE USER USING SESSION ID	
	$self->logError("User not validated") and exit unless $self->validate();

	#### GET VIEWS    
    my $username = $self->username();
	my $aguauser = $self->conf()->getKey("agua", "AGUAUSER");
	$self->logDebug("aguauser", $aguauser);
    my $query = qq{SELECT project, workflow, feature, species, build, type
FROM feature
WHERE username = '$username'
OR username='$aguauser'};
    $self->logDebug("$query");
    my $features = $self->db()->queryhasharray($query);    
	$features = [] if not defined $features;
    $self->logDebug("features", $features);
	
	return $features;
}

sub _isView {
#### RETURN 1 IF FEATURE PRESENT IN VIEW, 0 OTHERWISE
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("Agua::Common::View::_isView(object)");
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "view";
	my $required_fields = ["username", "project", "view"];
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("Variables not defined: @$not_defined") and exit if @$not_defined;
	
	my $where = $self->db()->where($object, $required_fields);
	my $query = qq{SELECT 1 FROM $table
$where};
	$self->logDebug("query", $query);
	my $result = $self->db()->query($query);
	$result = 0 if not defined $result;
	$self->logDebug("result", $result);

	return $result;
}

sub _addView {
	my $self		=	shift;
	my $json		=	shift;
	$self->logDebug("json", $json);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "view";
	my $required_fields = ["username", "project", "view"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logDebug("Variables not defined: @$not_defined' }") and exit if @$not_defined;
	
	#### LATER: FIX THIS SO THAT THE DATE IS ADDED PROPERLY 
	$json->{datetime} = "NOW()";
	if ( $self->conf()->getKey('database', 'DBTYPE') eq "SQLite" )
	{
		$json->{datetime} = "DATETIME('NOW');";
	}

	#### DO THE ADD
	return $self->_addToTable($table, $json, $required_fields);	
}


sub _removeView {
	my $self		=	shift;
    my $json 			=	$self->json();
 	$self->logDebug("json", $json);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "view";
	my $required_fields = ["username", "project", "view"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### DO THE REMOVE
	return $self->_removeFromTable($table, $json, $required_fields);
}

sub _isViewFeature {
#### RETURN 1 IF FEATURE PRESENT IN VIEW, 0 OTHERWISE
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("Agua::Common::View::_isViewFeature(object)");
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "viewfeature";
	my $required_fields = ["username", "project", "view", "feature"];
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	my $where = $self->db()->where($object, $required_fields);
	my $query = qq{SELECT 1 FROM $table
$where};
	my $result = $self->db()->query($query);
	$result = 0 if not defined $result;
	
	return $result;
}

sub _addFeature {
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("Agua::Common::View::_addFeature(object)");
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "feature";
	my $required_fields = ["username", "project", "workflow", "feature", "location"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### DO THE ADD
	return $self->_addToTable($table, $object, $required_fields);	
}

sub _removeFeature {
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("Agua::Common::View::_removeFeature(object)");
	$self->logDebug("object", $object);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "feature";
	my $required_fields = ["username", "project", "workflow", "feature"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### DO THE REMOVE
	return $self->_removeFromTable($table, $object, $required_fields);	
}


sub _addViewFeature {
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("(featureObject)");
	$self->logDebug("object", $object);

    #### SET TABLE AND REQUIRED FIELDS	
	my $table = "viewfeature";
	my $required_fields = ["username", "project", "view", "feature", "location"];
 	$self->logDebug("required_fields", $required_fields);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("Variables not defined: @$not_defined") and exit if defined $not_defined and @$not_defined;
	
	#### DO THE ADD
	return $self->_addToTable($table, $object, $required_fields);	
}

sub _removeViewFeature {
	my $self		=	shift;
    
    my $json 			=	$self->json();	
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "viewfeature";
	my $required_fields = ["username", "project", "view", "feature"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### DO THE REMOVE
	my $success = $self->_removeFromTable($table, $json, $required_fields);
	return if not $success;
	
	#### REMOVE THE FEATURE FROM THE TRACKLIST IF PRESENT
	my $fields = ["username", "project", "view" ];
	my $where = $self->db()->where($json, $fields);
	my $query = qq{SELECT tracklist FROM view\n$where};
	$self->logDebug("query", $query);
	my $tracklist = $self->db()->query($query);
	$self->logDebug("BEFORE tracklist", $tracklist);
	
	my $feature = $json->{feature};
	$self->logDebug("feature", $feature);
	my @features = split ",", $tracklist;
	$self->logDebug("features: @features");
	for ( my $i = 0; $i < $#features + 1; $i++ ) {
		$self->logDebug("features[$i]", $features[$i]);
		splice @features, $i and last if $features[$i] eq $feature;
	}
	$tracklist = join "," , @features;
	$self->logDebug("AFTER tracklist", $tracklist);

	$query = qq{UPDATE view SET tracklist='$tracklist' $where};
	$self->db()->do($query);
}

sub updateViewLocation {
=head2

    SUBROUTINE     updateViewLocation
    
	PURPOSE

		UPDATE chromosome, start, stop AND tracklist IN view TABLE

=cut

	my $self		=	shift;
    my $json 		=	shift;
	$self->logDebug("json", $json);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "view";
	my $required_fields = ["username", "project", "view", "chromosome", "stop"];
 	$self->logDebug("json", $json);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	my $now = $self->db()->now();

	my $query = qq{UPDATE view
SET chromosome='$json->{chromosome}',
start='$json->{start}',
stop='$json->{stop}',
datetime=$now
WHERE username='$json->{username}'
AND project='$json->{project}'
AND view='$json->{view}'};
	$self->logDebug("$query");
	my $success = $self->db()->do($query);
	$self->logDebug("success", $success);
	

	$self->logError("Could not update view $json->{view}") and exit if not defined $success or not $success;
	$self->logStatus("") and exit;
}

sub updateViewTracklist {
=head2

    SUBROUTINE     updateViewTracklist
    
	PURPOSE

		UPDATE chromosome, start, stop AND tracklist IN view TABLE

=cut
	my $self		=	shift;
    my $json 		=	shift;
	$self->logDebug("json", $json);	

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "view";
	my $required_fields = ["username", "project", "view", "tracklist"];
 	$self->logDebug("json", $json);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	my $now = $self->db()->now();

	my $query = qq{UPDATE view
SET tracklist='$json->{tracklist}',
datetime=$now
WHERE username='$json->{username}'
AND project='$json->{project}'
AND view='$json->{view}'};
	$self->logDebug("$query");
	my $success = $self->db()->do($query);
	$self->logDebug("success", $success);
	
	$self->logError("Could not update view $json->{view}") and exit if not defined $success or not $success;
	$self->logStatus("");
}


1;
