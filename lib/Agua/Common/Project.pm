package Agua::Common::Project;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Project
	
	PURPOSE
	
		PROJECT METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

sub saveProject {
=head2

	SUBROUTINE		saveProject
	
	PURPOSE

		ADD A PROJECT TO THE project TABLE
        
=cut

	my $self		=	shift;
    my $json 		=	$self->json();

 	$self->logDebug("Common::saveProject()");
	my $success = $self->_removeProject($json);
	$self->logStatus("Could not remove project $json->{project} from project table") if not $success;
	$success = $self->_addProject($json);	
	$self->logStatus("Successful insert of project $json->{project} into project table") if $success;
}

sub addProject {
=head2

	SUBROUTINE		addProject
	
	PURPOSE

		ADD A PROJECT TO THE project TABLE
        
=cut

	my $self		=	shift;
        my $data 			=	$self->json();

 	$self->logDebug("Common::addProject()");

	#### REMOVE IF EXISTS ALREADY
	$self->_removeProject($data);

	my $success = $self->_addProject($data);	
	$self->logStatus("Created/updated project $data->{name}") if $success;
}

sub _addProject {
=head2

	SUBROUTINE		_addProject
	
	PURPOSE

		ADD A PROJECT TO THE project TABLE
        
=cut
	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "project";
	my $required_fields = ["username", "name"];
 	$self->logDebug("data->{username}", $data->{username});
 	$self->logDebug("data->{name}", $data->{name});

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### DO ADD
	my $success = $self->_addToTable($table, $data, $required_fields);	
 	$self->logError("Could not add project $data->{project} into project $data->{project} in project table") and exit if not defined $success;

	#### ADD THE PROJECT DIRECTORY TO THE USER'S agua DIRECTORY
    my $username = $data->{'username'};
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	my $filepath = "$fileroot/$data->{name}";
	$self->logDebug("Creating directory", $filepath);

	File::Path::mkpath($filepath);
	$self->logError("Could not create the fileroot directory: $fileroot") and exit if not -d $filepath;

    my $apache_user = $self->conf()->getKey("agua", 'APACHEUSER');
	$self->logDebug("apache_user", $apache_user);
	my $chmod = "chown -R $apache_user:$apache_user $filepath &> /dev/null";
	print `$chmod`;
	
	return 1;
}
sub _removeProject {
=head2

	SUBROUTINE		_removeProject
	
	PURPOSE

		REMOVE A PROJECT FROM THE project, workflow, groupmember, stage AND

		stageparameter TABLES, AND REMOVE THE PROJECT FOLDER AND DATA FILES
      
=cut

	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ["username", "name"];
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### REMOVE FROM project
	my $table = "project";
	return $self->_removeFromTable($table, $data, $required_fields);
}

sub removeProject {
=head2

	SUBROUTINE		removeProject
	
	PURPOSE

		REMOVE A PROJECT FROM THE project, workflow, groupmember, stage AND

		stageparameter TABLES, AND REMOVE THE PROJECT FOLDER AND DATA FILES
      
=cut

	my $self		=	shift;

        my $json 			=	$self->json();

    #### VALIDATE
    $self->logError("User session not validated") and exit unless $self->validate();

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ["username", "name"];
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### REMOVE FROM project TABLE
    my $success = $self->_removeProject($json);
    $self->logError("Can't remove project") and exit if not $success;
 	
	#### REMOVE FROM workflow
	my $table = "workflow";
	$required_fields = ["username", "project"];
	$success = $self->_removeFromTable($table, $json, $required_fields);
 	$self->logError("Could not delete project $json->{project} from the $table table") and exit if not defined $success;

	#### REMOVE FROM stage
	$table = "stage";
	$success = $self->_removeFromTable($table, $json, $required_fields);
 	$self->logError("Could not delete project $json->{project} from the $table table") and exit if not defined $success;

	#### REMOVE FROM stageparameter
	$table = "stageparameter";
	$success = $self->_removeFromTable($table, $json, $required_fields);
 	$self->logError("Could not delete project $json->{project} from the $table table") and exit if not defined $success;

	#### REMOVE FROM groupmember
	$table = "groupmember";
	$json->{owner} = $json->{username};
	$json->{type} = "project";
	$success = $self->_removeFromTable($table, $json,  ["owner", "name", "type"]);
 	$self->logError("Could not delete project $json->{project} from the $table table") and exit if not defined $success;

#	#### REMOVE FROM clusters
#	$table = "cluster";
#	$success = $self->_removeFromTable($table, $json, $required_fields);
# 	$self->logError("Could not delete project $json->{project} from the $table table") and exit if not defined $success;

	#### REMOVE PROJECT DIRECTORY
    my $username = $json->{'username'};
	$self->logDebug("username", $username);
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	my $filepath = "$fileroot/$json->{project}";
	if ( $^O =~ /^MSWin32$/ )   {   $filepath =~ s/\//\\/g;  }
	$self->logDebug("Removing directory", $filepath);
	
	$self->logError("Cannot remove directory: $filepath") and exit if not File::Remove::rm(\1, $filepath);

	$self->logStatus("Deleted project $json->{project}");
	
}	#### removeProject





sub getProjects {
=head2

    SUBROUTINE:     getProjects
    
    PURPOSE:

		RETURN AN ARRAY OF project HASHES
			
			E.G.:
			[
				{
				  'name' : 'NGS',
				  'desciption' : 'NGS analysis team',
				  'notes' : 'This project is for ...',
				},
				{
					...
			]

=cut

	my $self		=	shift;

	$self->logDebug("Common::getProjects()");
    	my $json			=	$self->json();

    #### VALIDATE
    $self->logError("User session not validated") and exit unless $self->validate();

    #### GET PROJECTS
    my $username = $json->{username};
    my $projects = $self->_getProjects($username);
    
	######## IF NO RESULTS:
	####	1. INSERT DEFAULT PROJECT INTO project TABLE
	####	2. CREATE DEFAULT PROJECT FOLDERS
	return $self->_defaultProject() if not defined $projects;

	return $projects;
}


sub _getProjects {
#### GET PROJECTS FOR THIS USER
    my $self        =   shift;
    my $username    =   shift;    
    
    $self->logDebug("username", $username);
	my $query = qq{SELECT * FROM project
WHERE username='$username'
ORDER BY name};
	$self->logDebug("query", $query);
    
	return $self->db()->queryhasharray($query);
}

sub _defaultProject {
=head2

	SUBROUTINE		_defaultProject
	
	PURPOSE

		1. INSERT DEFAULT PROJECT INTO project TABLE
		
		2. RETURN QUERY RESULT OF project TABLE
		
=cut

	my $self		=	shift;
	$self->logDebug("Common::_defaultProject()");
	
    my $json         =	$self->json();

    #### VALIDATE    
    $self->logError("User session not validated") and exit unless $self->validate();

	#### SET DEFAULT PROJECT
	$self->json()->{name} = "Project1";
	
	#### ADD PROJECT
	my $success = $self->_addProject($json);
	$self->logError("Could not add project $json->{project} into  project table") and exit if not defined $success;

	#### DO QUERY
    my $username = $json->{'username'};
	$self->logDebug("username", $username);
	my $query = qq{SELECT * FROM project
WHERE username='$username'
ORDER BY name};
	$self->logDebug("$query");	;
	my $projects = $self->db()->queryhasharray($query);

	return $projects;
}


1;