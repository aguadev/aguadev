package Agua::Common::Shared;

=head2

	PACKAGE		Agua::Common::Shared
	
	PURPOSE
	
		PROJECT AND RESOURCE SHARING METHODS FOR Agua::Common
		
=cut


use Moose::Role;
use Moose::Util::TypeConstraints;
has 'totalprojects'		=> ( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'sharedprojects'	=> ( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'worldprojects'		=> ( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'userprojects'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'usersources'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'sharedsources'		=> ( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'worldownergroups'		=> ( isa => 'ArrayRef|Undef', is => 'rw', default => undef );

use Data::Dumper;

#### SHARED APPS
=head2

    SUBROUTINE:     getSharedApps
    
    PURPOSE:

        RETURN A JSON LIST OF SHARED APPLICATIONS

=cut

sub getSharedApps {
	my $self		=	shift;
	$self->logDebug("");

	my $json			=	$self->json();

	#### VALIDATE    
    my $username = $json->{username};
    my $session_id = $json->{sessionId};
    $self->logError("User $username not validated") and exit unless $self->validate($username, $session_id);
	$self->logDebug("User validated", $username);

	#### GET admin USER'S APPS	
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
    my $query = qq{SELECT * FROM app
WHERE owner = '$admin'
ORDER BY type};
    my $sharedapps = $self->db()->queryhasharray($query);
	$sharedapps = [] if not defined $sharedapps;

	$self->logDebug("sharedapps", $sharedapps);
	
	return $sharedapps;
}

=head2

    SUBROUTINE:     getSharedParameters
    
    PURPOSE:

        RETURN A JSON LIST OF PARAMETERS TO ACCOMPANY THE SHARED
		
		APPS RETURNED BY getSharedApps
=cut

sub getSharedParameters {
	my $self		=	shift;
	$self->logDebug("Common::getSharedParameters()");

	my $json			=	$self->json();

	#### VALIDATE    
    my $username = $json->{username};

	#### GET admin USER'S APPS	
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
    my $query = qq{SELECT * FROM parameter
WHERE owner = '$admin'
ORDER BY appname, apptype};
    my $apps = $self->db()->queryhasharray($query);
	$apps = [] if not defined $apps;
	
	return $apps;
}



#### SHARED PROJECTS
sub getUserProjects {
    my $self        =   shift;
	my $username	=	shift;
	$self->logDebug("");
	
	return $self->userprojects() if defined $self->userprojects();
	
    #### GET PROJECTS SHARED WITH THE USER
    my $shared_projects = $self->getGroupProjects($username);	
	$self->logDebug("shared_projects", $shared_projects);

    #### GET PROJECTS SHARED WITH THE USER
    my $world_projects = $self->getWorldProjects($username, $shared_projects);	
	$self->logDebug("world_projects", $world_projects);
	
	#### ADD GROUP SHARED TO WORLD SHARED
	my $total_projects;
	@$total_projects = (@$shared_projects, @$world_projects);
	
	#### CONVERT TO USERNAME:PROJECTS HASH
	my $userprojects = $self->hasharrayToHash($total_projects, "owner");
	$self->logDebug("userprojects", $userprojects);

	#### SET userprojects
	$self->userprojects($userprojects);

	return $userprojects;
}

sub getUserShared {
    my $self        =   shift;
	my $username	=	shift;
	my $type		=	shift;
	$self->logDebug("username", $username);
	$self->logDebug("type", $type);

	$self->logDebug("usersources", $self->usersources());
	$self->logDebug("userprojects", $self->userprojects());
	
	return $self->userprojects() if $type eq "project" and defined $self->userprojects();
	return $self->usersources() if $type eq "source" and defined $self->usersources();
	
    #### GET PROJECTS/SOURCES SHARED WITH THE USER
    my $groupshareds = $self->getGroupShared($username, $type);	
	$self->logDebug("groupshareds", $groupshareds);

    #### GET PROJECTS SHARED WITH THE USER
    my $worldshareds = $self->getWorldShared($username, $groupshareds, $type);	
	$self->logDebug("worldshareds", $worldshareds);
	
	#### ADD GROUP SHARED TO WORLD SHARED
	my $totalshareds;
	@$totalshareds = (@$groupshareds, @$worldshareds);
	
	#### CONVERT TO USERNAME:PROJECTS HASH
	my $usershareds = $self->hasharrayToHash($totalshareds, "owner");
	$self->logDebug("usershareds", $usershareds);

	#### SET usershareds
	
	$self->userprojects($usershareds) if $type eq "project";
	$self->usersources($usershareds) if $type eq "source";

	return $usershareds;
}

sub getGroupProjects {
=head2

    SUBROUTINE     getGroupProjects
    
    PURPOSE
			
		RETURN THE LIST OF PROJECTS BELONGING TO GROUPS OF WHICH
		
		THE USER IS A MEMBER
	
	NOTES
	
		RETURNS THE FOLLOWING DATA STRUCTURE:
	
		$sharedprojects = [
			  {
				'rights' => {
							  'groupview' => '1',
							  'groupcopy' => '1',
							  'groupwrite' => '1'
							},
				'owner' => 'admin',
				'groupname' => 'bioinfo',
				'project' => 'Project1',
				'description' => ''
			  },
			  {
				'rights' => {
							  'groupview' => '1',
							  'groupcopy' => '1',
							  'groupwrite' => '1'
							},
				'owner' => 'admin',
				'groupname' => 'bioinfo',
				'project' => 'ProjectX',
				'description' => ''
			  },
			  ...
		]

=cut

    my $self        =   shift;
    my $username	=   shift;
	$self->logDebug("");

	return $self->sharedprojects() if $self->sharedprojects();

    #### GET USERNAME IF NOT DEFINED
    my $json = $self->json();
	$username = $json->{username} if not defined $username;

	####  1. GET USER-ACCESSIBLE SHARED PROJECTS
	my $query = qq{SELECT DISTINCT owner, groupname, description
FROM groupmember
WHERE name='$username'
AND type='user'
AND owner != '$username'
ORDER BY owner};
    my $ownergroups = $self->db()->queryhasharray($query);
    $self->logDebug("ownergroups", $ownergroups);

	my $shared_projects;
	my $already_seen;
    foreach my $ownergroup( @$ownergroups )
    {
        my $owner = $ownergroup->{owner};
        my $group = $ownergroup->{groupname};
        
        $query = qq{select groupname, name, description from groupmember where owner = '$owner' and groupname = '$group' and type='project'};
        $self->logDebug("$query");
        my $projects = $self->db()->queryhasharray($query);
        foreach my $project ( @$projects )
        {
			#### SKIP IT IF WE'VE SEEN IT BEFORE
			next if $already_seen->{$project->{name}};
			$already_seen->{$project->{name}} = 1;
			
			my $hash;
            $hash->{groupname} = $project->{groupname};
            $hash->{name} = $project->{name};
            $hash->{description} = $project->{description};
            $hash->{owner} = $owner;
            push @$shared_projects, $hash;
        }
    }

    $self->logDebug("shared_projects", $shared_projects);

    #### GET THE PERMISSIONS OF THE SHARED PROJECTS
    for my $shared_project ( @$shared_projects )
    {
        my $owner = $shared_project->{owner};
        my $groupname = $shared_project->{groupname};

        my $query = qq{select groupwrite, groupcopy, groupview from access where owner = '$owner' and groupname = '$groupname'};
        $self->logDebug("$query");
        my $grouprights = $self->db()->queryhash($query);
		
		$self->logDebug("grouprights", $grouprights);
		
		$grouprights = {} if not defined $grouprights;        
        $shared_project->{rights} = $grouprights;
    }
	$shared_projects = [] if not defined $shared_projects;

    $self->logDebug("shared_projects", $shared_projects);

	#### SET _sharedprojects
	$self->sharedprojects($shared_projects);

	return $shared_projects;
}


sub getGroupShared {
    my $self        =   shift;
    my $username	=   shift;
    my $type		=   shift;
	$self->logDebug("username", $username);
	$self->logDebug("type", $type);

	return $self->sharedprojects() if $type eq "project" and $self->sharedprojects();
	return $self->sharedsources() if $type eq "source" and $self->sharedsources();

    #### GET USERNAME IF NOT DEFINED
    my $json = $self->json();
	$username = $json->{username} if not defined $username;

	####  1. GET USER-ACCESSIBLE GROUPS
	my $query = qq{SELECT DISTINCT owner, groupname, description
FROM groupmember
WHERE name='$username'
AND type='user'
AND owner != '$username'
ORDER BY owner};
    my $ownergroups = $self->db()->queryhasharray($query);
    $self->logDebug("ownergroups", $ownergroups);

	my $groupshared;
	my $already_seen;
    foreach my $ownergroup( @$ownergroups )
    {
        my $owner = $ownergroup->{owner};
        my $group = $ownergroup->{groupname};
        
        $query = qq{SELECT owner, groupname, name, type, description
FROM groupmember
WHERE owner = '$owner'
AND groupname = '$group'
AND type='$type'};
        $self->logDebug("$query");
        my $shareds = $self->db()->queryhasharray($query);
        foreach my $shared ( @$shareds )
        {
			#### SKIP IT IF WE'VE SEEN IT BEFORE
			next if $already_seen->{$shared->{name}};
			$already_seen->{$shared->{name}} = 1;
            push @$groupshared, $shared;
        }
    }

    $self->logDebug("groupshared", $groupshared);

    #### GET THE PERMISSIONS OF THE SHARED PROJECTS
    for my $groupshare ( @$groupshared )
    {
        my $owner = $groupshare->{owner};
        my $groupname = $groupshare->{groupname};

        my $query = qq{SELECT groupwrite, groupcopy, groupview
FROM access
WHERE owner = '$owner'
AND groupname = '$groupname'};
        $self->logDebug("$query");
        my $grouprights = $self->db()->queryhash($query);
		$self->logDebug("grouprights", $grouprights);
		
		$grouprights = {} if not defined $grouprights;        
        $groupshare->{rights} = $grouprights;
    }
	$groupshared = [] if not defined $groupshared;

    $self->logDebug("groupshared", $groupshared);

	#### SET _sharedTYPE
	my $label = "shared" . $type . "s";
	$self->logDebug("label", $label);
	$self->$label($groupshared);

	return $groupshared;
}

sub getWorldProjects {
=head2

    SUBROUTINE     getWorldProjects
    
    PURPOSE
			
		RETURN THE LIST OF WORLD ACCESSIBLE PROJECTS ___MINUS___ THE
		
		PROJECTS BELONGING TO GROUPS OF WHICH THE USER IS A MEMBER
	
=cut

    my $self        		=   shift;
    my $username			=   shift;
    my $shared_projects 	=   shift;
    $self->logDebug("shared_projects", $shared_projects);
    
    #### GET GROUPS SHARED WITH WORLD
    my $query = qq{SELECT DISTINCT owner, groupname, worldwrite, worldcopy, worldview
FROM access
WHERE worldview = 1
AND owner != "$username"};
	$self->logDebug("$query");
    my $world_ownergroups = $self->db()->queryhasharray($query);
	$world_ownergroups = [] if not defined $world_ownergroups;
	$self->logDebug("world_ownergroups", $world_ownergroups);
	
    #### GET PROJECTS IN WORLD GROUPS
    my $world_projects = [];
    foreach my $world_ownergroup ( @$world_ownergroups )
    {
        my $owner = $world_ownergroup->{owner};
        my $group = $world_ownergroup->{groupname};
        my $query = qq{SELECT owner, groupname, name, description 
FROM groupmember
WHERE owner='$owner'
AND groupname='$group'
AND type='project'};
		$self->logDebug("$query");
        my $projects = $self->db()->queryhasharray($query);
        $projects = [] if not defined $projects;
		@$world_projects = (@$world_projects, @$projects) if @$projects;
    }
	$self->logDebug("world_projects", $world_projects);
    
	#### REMOVE ANY WORLD PROJECTS THAT HAVE ALREADY BEEN SHARED WITH THIS USER
	if ( defined $world_projects and @$world_projects )
	{
		for ( my $i = 0; $i < @$world_projects; $i++ )
		{
			my $world_owner = $$world_projects[$i]->{owner};
			my $world_project = $$world_projects[$i]->{name};
			foreach my $shared_project ( @$shared_projects )
			{
				my $shared_owner = $shared_project->{owner};
				my $shared_project = $shared_project->{name};
				
				if ( $shared_owner eq $world_owner
					&& $shared_project eq $world_project)
				{
					splice @$world_projects, $i, 1;
					$i--;
				}
			}
		}
	}

    #### GET THE PERMISSIONS OF THE SHARED PROJECTS
    for my $world_project ( @$world_projects )
    {
        my $owner = $world_project->{owner};
        my $groupname = $world_project->{groupname};

        my $query = qq{SELECT worldwrite, worldcopy, worldview
FROM access
WHERE owner = '$owner'
AND groupname = '$groupname'};
        $self->logDebug("$query");
        my $grouprights = $self->db()->queryhash($query);		
		$self->logDebug("grouprights", $grouprights);
		
		$grouprights = {} if not defined $grouprights;        
        $world_project->{rights} = $grouprights;
    }
	$world_projects = [] if not defined $world_projects;

    $self->logDebug("world_projects", $world_projects);

	#### FOR PROJECTS THAT BELONG TO MULTIPLE GROUPS, SELECT THE
	#### GROUP IN WHICH THIS USER HAS THE GREATEST PRIVILEGES    
	$world_projects = $self->highestPrivilegeProjects($world_projects);
    $self->logDebug("world_projects", $world_projects);

	return $world_projects;
}

sub getWorldShared {
    my $self        		=   shift;
    my $username			=   shift;
    my $groupshareds 		=   shift;
	my $type				=	shift;
	
    $self->logDebug("groupshareds", $groupshareds);
    
    #### GET GROUPS SHARED WITH WORLD
	my $worldownergroups = $self->getWorldOwnerGroups($username);
	$self->logDebug("worldownergroups", $worldownergroups);
	
    #### GET PROJECTS IN WORLD GROUPS
    my $worldshareds = [];
    foreach my $worldownergroup ( @$worldownergroups )
    {
        my $owner = $worldownergroup->{owner};
        my $group = $worldownergroup->{groupname};
        my $query = qq{SELECT owner, groupname, name, type, description 
FROM groupmember
WHERE owner='$owner'
AND groupname='$group'
AND type='$type'};
		$self->logDebug("$query");
        my $projects = $self->db()->queryhasharray($query);
        $projects = [] if not defined $projects;
		@$worldshareds = (@$worldshareds, @$projects) if @$projects;
    }
	$self->logDebug("worldshareds", $worldshareds);
    
	#### REMOVE ANY WORLD PROJECTS THAT HAVE ALREADY BEEN SHARED WITH THIS USER
	if ( defined $worldshareds and @$worldshareds )
	{
		for ( my $i = 0; $i < @$worldshareds; $i++ )
		{
			my $world_owner = $$worldshareds[$i]->{owner};
			my $worldshared = $$worldshareds[$i]->{name};
			foreach my $groupshared ( @$groupshareds )
			{
				my $shared_owner = $groupshared->{owner};
				my $groupshared = $groupshared->{name};
				
				if ( $shared_owner eq $world_owner
					&& $groupshared eq $worldshared)
				{
					splice @$worldshareds, $i, 1;
					$i--;
				}
			}
		}
	}

    #### GET THE PERMISSIONS OF THE SHARED PROJECTS
    for my $worldshared ( @$worldshareds )
    {
        my $owner = $worldshared->{owner};
        my $groupname = $worldshared->{groupname};

        my $query = qq{SELECT worldwrite, worldcopy, worldview
FROM access
WHERE owner = '$owner'
AND groupname = '$groupname'};
        $self->logDebug("$query");
        my $grouprights = $self->db()->queryhash($query);		
		$self->logDebug("grouprights", $grouprights);
		
		$grouprights = {} if not defined $grouprights;        
        $worldshared->{rights} = $grouprights;
    }
	$worldshareds = [] if not defined $worldshareds;

    $self->logDebug("worldshareds", $worldshareds);

	#### FOR PROJECTS THAT BELONG TO MULTIPLE GROUPS, SELECT THE
	#### GROUP IN WHICH THIS USER HAS THE GREATEST PRIVILEGES    
	$worldshareds = $self->highestPrivilegeShared($worldshareds);
    $self->logDebug("worldshareds", $worldshareds);

	return $worldshareds;
}

sub getWorldOwnerGroups {
    my $self        		=   shift;
    my $username			=   shift;

	return $self->worldownergroups() if defined $self->worldownergroups();

	my $query = qq{SELECT DISTINCT owner, groupname, worldwrite, worldcopy, worldview
FROM access
WHERE worldview = 1
AND owner != "$username"};
	$self->logDebug("$query");
    my $worldownergroups = $self->db()->queryhasharray($query);
	$worldownergroups = [] if not defined $worldownergroups;
	$self->worldownergroups($worldownergroups);

	return $worldownergroups;
}

sub addProjectRights {
	my $self		=	shift;
	my $hasharray	=	shift;
	my $project		=	shift;
	
	#### ADD THE PERMISSIONS FOR THIS PROJECT TO EACH VIEW

	foreach my $entry ( @$hasharray )
	{
		my $permissions = ["groupwrite", "groupcopy", "groupview", "worldwrite", "worldcopy", "worldview"];
		foreach my $permission ( @$permissions )
		{
			$entry->{$permission} = $project->{rights}->{$permission}
				if defined $project->{rights}->{$permission};
		}
	}

	return $hasharray;	
}

sub highestPrivilegeProjects {
=head2

	SUBROUTINE		highestPrivilegeProjects
	
	PURPOSE
	
		FOR PROJECTS THAT BELONG TO MULTIPLE GROUPS, SELECT THE
		
		GROUP IN WHICH THIS USER HAS THE GREATEST PRIVILEGES.
		
		AN IMPORTANT POINT ABOUT THE 'sumPrivilege' COUNTING SCHEME
		
		IS THAT WORLD RIGHTS ARE ALWAYS LESS THAN OR EQUAL TO GROUP
		
		RIGHTS IN EVERY CATEGORY (I.E., WRITE, COPY, READ).
		
		SO YOU CAN HAVE
		
		111000
		100000
		101000
		
		BUT NEVER
		
		000111
		000001
		000101
=cut

	my $self		=	shift;
	my $projects	=	shift;
	#$self->logDebug("projects", $projects);
	$self->logError("projects not defined") and exit if not defined $projects;

	my $uniqueprojectshash = {};
	for ( my $i = 0; $i < @$projects; $i++ )
	{
		my $project = $$projects[$i];
		$self->logDebug("project", $project);
		my $key = $project->{owner};
		$key .= "-" . $project->{project} if defined $project->{project};
		$key .= "-" . $project->{name} if defined $project->{name};
		$self->logDebug("key", $key);
		if ( not exists $uniqueprojectshash->{$key} ) {
			$uniqueprojectshash->{$key} = $project;
		}
		else {
			my $currentproject = $uniqueprojectshash->{$key};
			if ( $self->sumPrivilege($currentproject->{rights}, "world")
				< $self->sumPrivilege($project->{rights}, "world") ) {
				$uniqueprojectshash->{$key} = $project;
			}
		}
	}
	$self->logDebug("uniqueprojectshash", $uniqueprojectshash);

	my $uniqueprojects = [];
	foreach my $key ( keys %$uniqueprojectshash ) {
		push @$uniqueprojects, $uniqueprojectshash->{$key};
	}
	#$self->logDebug("projects", $projects);

	return $projects;
}

sub highestPrivilegeShared {
	my $self		=	shift;
	my $shareds	=	shift;
	#$self->logDebug("shareds", $shareds);
	$self->logError("shareds not defined") and exit if not defined $shareds;

	my $uniquesharedshash = {};
	foreach my $shared ( @$shareds ) {
		$self->logDebug("shared", $shared);
		my $key = $shared->{owner};
		$key .= "-" . $shared->{project} if defined $shared->{project};
		$key .= "-" . $shared->{name} if defined $shared->{name};
		$self->logDebug("key", $key);
		if ( not exists $uniquesharedshash->{$key} ) {
			$uniquesharedshash->{$key} = $shared;
		}
		else {
			my $currentshared = $uniquesharedshash->{$key};
			if ( $self->sumPrivilege($currentshared->{rights}, "world")
				< $self->sumPrivilege($shared->{rights}, "world") ) {
				$uniquesharedshash->{$key} = $shared;
			}
		}
	}
	$self->logDebug("uniquesharedshash", $uniquesharedshash);

	my $uniqueshareds = [];
	foreach my $key ( keys %$uniquesharedshash ) {
		push @$uniqueshareds, $uniquesharedshash->{$key};
	}
	#$self->logDebug("shareds", $shareds);

	return $shareds;
}




sub _sharedProjectData {
=head2

	SUBROUTINE		_sharedProjectData
	
	PURPOSE

		RETURN ARRAY OF DATA VALUES FOR THE SHARED PROJECTS
		
		WITH PERMISSIONS ATTACHED TO EACH ENTRY
		
	INPUT
	
		1. PROJECTS HASH (username|owner, project, etc.)
		
		2. TABLE FROM WHICH TO GET THE DATA
		
	OUTPUT
		
		1. USER-KEYED HASH:
			
			{
				USER1 : [
					{ project: project1, workflow: workflow1, appname: app1, ...},
					{ .. }
				],
				USER2 : [ ... ],
				...
			}

=cut

	my $self		=	shift;	
	my $projects	=	shift;
	my $table		=	shift;
	my $select		=	shift;
	my $extra		=	shift;
	$self->logDebug("Agua::Common::Shared::_sharedProjectStages()");

	#### DEFAULTS
	$select = '*' if not defined $select;
	$extra = '' if not defined $extra;
	
	#### 1. RETRIEVE USER PROJECTS (STORED EARLIER IN getSharedStages)
	my $user_projects = $self->userprojects();
	$self->logDebug("user_projects", $user_projects);

	#### GET THE DATA
	my $shared_project_stages = [];
	
	$self->logDebug("Getting projectStages for each user");
	foreach my $project ( @$projects )
	{
		#### ADD username FIELD
		$project->{username} = $project->{owner};
		$project->{project} = $project->{name};
		
		$self->logDebug("project", $project);

		my $unique_keys = ["username", "project"];
		my $where = $self->db()->where($project, $unique_keys);
		my $query = qq{SELECT $select FROM $table
$where $extra};
		$self->logDebug("$query");
		my $hasharray = $self->db()->queryhasharray($query);
		next if not defined $hasharray;
		
		#### ADD THE PERMISSIONS FOR THIS PROJECT TO EACH ENTRY
		$hasharray = $self->addProjectRights($hasharray, $project);

		(@$shared_project_stages) = (@$shared_project_stages, @$hasharray);
	}

	$self->logDebug("shared_project_stages", $shared_project_stages);

	return $shared_project_stages;
}


sub getSharedProjects {
	my $self		=	shift;
	
	return $self->getShared("project");
}

sub getSharedWorkflows  {
	my $self		=	shift;
	$self->logDebug("");

	my $jsonParser = $self->json_parser();	

	#### GET JSON
    my $json         =	$self->json();

	#### GET THE ARRAY OF SHARED PROJECTS CONVERTED TO
	#### A USERNAME:PROJECT KEYED HASH
    my $username = $json->{username};
	my $userprojects = $self->getUserProjects($username);
	return [] unless defined $userprojects and %$userprojects;
	$self->logDebug("userprojects", $userprojects);
	
	#### GET THE STAGES FOR EACH SHARED PROJECT
	$self->logDebug("Getting projectWorkflows for each user");
	my $shared_workflows = {};
	foreach my $username ( keys %$userprojects )
	{
		$self->logDebug("username", $username);
		my $projects = $userprojects->{$username};
		$self->logDebug("projects", $projects);
		
		my $shared_data = $self->_sharedProjectData($projects, "workflow");
		$shared_workflows->{$username} = $shared_data if defined $shared_data;
	}
	
	$self->logDebug("shared_workflows", $shared_workflows);
	$shared_workflows = [] if not defined $shared_workflows;

	return $shared_workflows;
}

sub getSharedStages  {
=head2

	SUBROUTINE		getSharedStages
	
	PURPOSE

		RETURN ARRAY OF STAGES THAT HAVE BEEN SHARED WITH
		
		THE USER BY OTHER USERS

	INPUT
	
		1. USERNAME
		
		2. SESSION ID
		
	OUTPUT
		
		1. USER-KEYED HASH:
			
			{
				USER1 : [
					{ project: project1, workflow: workflow1, name: app1, ...},
					{ .. }
				],
				USER2 : [ ... ],
				...
			}

=cut

	my $self		=	shift;
	$self->logDebug("");

	my $jsonParser = $self->json_parser();	

	#### GET JSON
    my $json         =	$self->json();

	#### GET THE ARRAY OF SHARED PROJECTS CONVERTED TO
	#### A USERNAME:PROJECT KEYED HASH
    my $username = $json->{username};
	my $userprojects = $self->getUserProjects($username);
	return [] unless defined $userprojects and %$userprojects;
	$self->logDebug("userprojects", $userprojects);
	
	#### GET THE STAGES FOR EACH SHARED PROJECT
	$self->logDebug("Getting projectStages for each user");
	my $shared_stages = {};
	foreach my $username ( keys %$userprojects )
	{
		$self->logDebug("username", $username);
		my $projects = $userprojects->{$username};
		$self->logDebug("projects", $projects);
		
		my $shared_data = $self->_sharedProjectData($projects, "stage");
		$shared_stages->{$username} = $shared_data if defined $shared_data;
	}
	
	$self->logDebug("shared_stages", $shared_stages);
	$shared_stages = [] if not defined $shared_stages;

	return $shared_stages;
}

sub getSharedStageParameters  {
=head2

	SUBROUTINE		getSharedStageParameters
	
	PURPOSE

		RETURN ARRAY OF STAGE PARAMETERS THAT HAVE BEEN SHARED WITH
		
		THE USER BY OTHER USERS

	INPUT
	
		1. USERNAME
		
		2. SESSION ID
		
	OUTPUT
		
		1. USER-KEYED HASH:
			
			{
				USER1 : [
					{ project: project1, workflow: workflow1, appname: app1, ...},
					{ .. }
				],
				USER2 : [ ... ],
				...
			}

=cut

	my $self		=	shift;
	$self->logDebug("Agua::Common::Shared::getSharedStageParameters()");

	#### GET JSON
    my $json         =	$self->json();

	#### STORE THE USER-KEYED SHARED PROJECTS HERE
	my $shared_stageparameters = {};

	#### GET THE ARRAY OF SHARED PROJECTS CONVERTED TO
	#### A USERNAME:PROJECT KEYED HASH
    my $username = $json->{username};
	my $userprojects = $self->getUserProjects($username);
	return [] unless defined $userprojects and %$userprojects;

	#### GET THE STAGE PARAMETERS FOR EACH SHARED PROJECT
	$self->logDebug("Getting projectStages for each user");
	foreach my $username ( keys %$userprojects )
	{
		my $projects = $userprojects->{$username};
		$self->logDebug("projects", $projects);
		
		my $shared_data = $self->_sharedProjectData($projects, "stageparameter");
		$shared_stageparameters->{$username} = $shared_data if defined $shared_data;
	}
	
	$self->logDebug("shared_stageparameters", $shared_stageparameters);

	return $shared_stageparameters;
}

sub getShared {
	my $self		=	shift;
	my $type		=	shift;
	$self->logDebug("type", $type);

	#### GET THE ARRAY OF SHARED ITEMS CONVERTED TO
	#### A USERNAME:ITEM KEYED HASH
    my $json         	=	$self->json();
    my $username 		= $json->{username};
	my $usershareds 	= $self->getUserShared($username, $type);
	
	return {} if not defined $usershareds and not %$usershareds and $type eq "source";
	return [] if not defined $usershareds and not %$usershareds and $type eq "project";
	
	$self->logDebug("usershareds", $usershareds);
	
	#### GET THE COMPLETE INFO FOR EACH SHARED PROJECT
	$self->logDebug("Getting shared shareds for each user");
	my $usersharedhash = {};
	foreach my $username ( keys %$usershareds ) {
		$self->logDebug("username", $username);
		my $shareds = $usershareds->{$username};
		$self->logDebug("shareds", $shareds);

		my $shareddata = [];
		foreach my $shared ( @$shareds ) {
			my $select = "*";
			my $extra = "ORDER BY name";
			my $query = qq{SELECT * FROM $type
WHERE username = '$username'
AND name = '$shared->{name}'
};
			$self->logDebug("query", $query);
			my $data = $self->db()->queryhash($query);
	$self->logDebug("data", $data);
			$data->{groupname} = $shared->{groupname};
			$data->{rights} = $shared->{rights};
			push @$shareddata, $data;
		}
		
		$usersharedhash->{$username} = $shareddata if defined $shareddata;
	}
	$self->logDebug("usersharedhash", $usersharedhash);

	return $usersharedhash;
}

#### SHARED SOURCES
sub getSharedSources {
	my $self		=	shift;
	
	return $self->getShared("source");
}

sub getOwnSharedSources {	
=head2

    SUBROUTINE     getSharedSources
    
    PURPOSE
			
		GET FILESYSTEM SOURCES SHARED BY OTHER USERS:

			1. FIND THE SHARED SOURCES
			
			2. CHECK THE USER BELONGS TO THE GROUP

=cut

    my $self        		=   shift;
    my $username			=   shift;
	$self->logDebug("Common::getSharedSources()");

    #### SET USERNAME
    my $json = $self->json();	
	$username = $json->{username} if not defined $username;

	#### 1. FIND THE SHARED SOURCES
	my $admin = $self->conf()->getKey('agua', 'ADMINUSER');
	my $query = qq{SELECT DISTINCT owner, groupname
FROM groupmember
WHERE type='source'
ORDER BY owner, groupname};
	$self->logDebug("$query");
	my $sourcegroups = $self->db()->queryhasharray($query);
	$self->logDebug("sourcegroups", $sourcegroups);
	
	#### 2. CHECK THE USER BELONGS TO THE GROUP
	$query = qq{SELECT owner, groupname
FROM groupmember
WHERE name='$username'
AND type='user'
};
	my $sharedgroups = $self->db()->queryhasharray($query);
	$self->logDebug("sharedgroups", $sharedgroups);
	
	return [] if not defined $sourcegroups;
	return [] if not defined $sharedgroups;
	
	my $sources = [];
	foreach my $sourcegroup ( @$sourcegroups )
	{
		$self->logDebug("sourcegroup", $sourcegroup);

		my $found = 0; 
		foreach my $sharedgroup ( @$sharedgroups )
		{
			$self->logDebug("sharedgroup", $sharedgroup);

			$self->logDebug("sourcegroup->{owner}", $sourcegroup->{owner});
			$self->logDebug("sharedgroup->{owner}", $sharedgroup->{owner});
			$self->logDebug("sourcegroup->{groupname}", $sourcegroup->{groupname});
			$self->logDebug("sharedgroup->{groupname}", $sharedgroup->{groupname});

			if ( $sharedgroup->{owner} eq $sourcegroup->{owner}
				and $sharedgroup->{groupname} eq $sourcegroup->{groupname} )
			{
				$found = 1;
				$self->logDebug("MATCH!:");
			}
			
			if ( $found )
			{
				$self->logDebug("sourcegroup", $sourcegroup);

				$query = qq{SELECT * FROM groupmember
WHERE owner='$sourcegroup->{owner}'
AND groupname='$sourcegroup->{groupname}'
AND type='source'
};
				$self->logDebug("$query");
				my $groupsources = $self->db()->queryhasharray($query);
				$self->logDebug("groupsources", $groupsources);
				foreach my $groupsource ( @$groupsources )
				{
					push @$sources, $groupsource;
				}
				last;
			}
		}
	}

	$self->logDebug("sources", $sources);

	#### REMOVE DUPLICATE SOURCES
	my $already_seen;
	for ( my $i = 0; $i < @$sources; $i++ )
	{
		if ( not exists $already_seen->{$$sources[$i]->{name}} )
		{
			$already_seen->{$$sources[$i]->{name}} = 1;
		}
		else
		{
			splice (@$sources, $i, 1);
			$i--;
		}
	}
	$self->logDebug("sources", $sources);

	return $sources;	
}




#### SHARED VIEWS
sub getSharedViews {
=head2

    SUBROUTINE     getSharedViews
    
    PURPOSE
        
        1. RETURN A USERNAME:VIEWS HASH ARRAY CONTAINING ALL VIEWS
		
			(GROUP AND WORLD) SHARED WITH THIS USER
        
        2. EACH 
        	
				A. VIEW - CAN BEEN SEEN FROM SHARER'S HOME DIRECTORY
				
				B. COPY - CAN BE COPIED TO THE USER'S HOME DIRECTORY 

				C. READ - BY DEFINITION, A SHARED VIEW HAS READ PERMISSION

echo '{"sourceuser":"admin","targetuser":"syoung","sourceworkflow":"Workflow0","sourceproject":"Project1","targetworkflow":"Workflow9","targetproject":"Project1","username":"syoung","sessionId":"9999999999.9999.999","mode":"getData"}' |  ./workflow.cgi

=cut

    my $self        =   shift;
    $self->logDebug(" Reports::views()");

    #### VALIDATE
    my $validated = $self->validate();
    $self->logDebug("Validated", $validated);
    $self->logError("User session not validated") and exit unless $validated;

    #### GET A USERNAME:PROJECTS HASH ARRAY OF PROJECTS
	#### SHARED WITH THE username USER 
    my $username = $self->json->{username};
	my $userprojects = $self->getUserProjects($username);
	return [] unless defined $userprojects and %$userprojects;
	
	#### GET THE VIEWS FOR THESE PROJECTS
	$self->logDebug("GET THE VIEWS");
	my $sharedviews = {};
	foreach my $username ( keys %$userprojects )
	{
		$self->logDebug("username", $username);
		my $projects = $userprojects->{$username};
		next if scalar @$projects == 0;
		$self->logDebug("projects", $projects);

		my $select = "*";
		my $extra = "ORDER BY project, view, species, build, chromosome, start, stop";
		my $shared_data = $self->_sharedProjectData($projects, "view", $select, $extra);
		$sharedviews->{$username} = $shared_data if defined $shared_data;
	}
	$self->logDebug("sharedviews", $sharedviews);

	return $sharedviews;
}


sub getSharedViewFeatures {
=head2

    SUBROUTINE     getSharedViewFeatures
    
    PURPOSE
        
        1. RETURN A USERNAME:VIEWS HASH ARRAY CONTAINING ALL VIEWS
		
			(GROUP AND WORLD) SHARED WITH THIS USER
        
        2. EACH 
        	
				A. VIEW - CAN BEEN SEEN FROM SHARER'S HOME DIRECTORY
				
				B. COPY - CAN BE COPIED TO THE USER'S HOME DIRECTORY 

				C. READ - BY DEFINITION, A SHARED VIEW HAS READ PERMISSION

echo '{"sourceuser":"admin","targetuser":"syoung","sourceworkflow":"Workflow0","sourceproject":"Project1","targetworkflow":"Workflow9","targetproject":"Project1","username":"syoung","sessionId":"9999999999.9999.999","mode":"getData"}' |  ./workflow.cgi

=cut

    my $self        =   shift;
    $self->logDebug(" Reports::views()");

    #### VALIDATE
    my $validated = $self->validate();
    $self->logDebug("Validated", $validated);
    $self->logError("User session not validated") and exit unless $validated;

    #### GET A USERNAME:PROJECTS HASH ARRAY OF PROJECTS
	#### SHARED WITH THIS USER 
    my $username = $self->json->{username};
	my $userprojects = $self->getUserProjects($username);
	return [] unless defined $userprojects and %$userprojects;
	
	#### GET THE VIEWS FOR THESE PROJECTS
	$self->logDebug("GET THE VIEWS");
	my $sharedviewfeatures = {};
	foreach my $username ( keys %$userprojects )
	{
		$self->logDebug("username", $username);
		my $projects = $userprojects->{$username};
		next if scalar @$projects == 0;
		$self->logDebug("projects", $projects);

		my $select = "username,project,view,feature";
		my $extra = "ORDER BY project, view, feature";
		my $shared_data = $self->_sharedProjectData($projects, "viewfeature", $select, $extra);
		$sharedviewfeatures->{$username} = $shared_data if defined $shared_data;
	}
	$self->logDebug("sharedviewfeatures", $sharedviewfeatures);

	return $sharedviewfeatures;
}





1;
