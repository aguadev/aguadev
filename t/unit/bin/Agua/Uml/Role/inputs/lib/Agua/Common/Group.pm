package Agua::Common::Group;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Group
	
	PURPOSE
	
		GROUP METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

=head2

    SUBROUTINE:     getGroups
    
    PURPOSE:

		RETURN AN ARRAY OF group HASHES
			
			E.G.:
			[
				{
				  'name' : 'NGS',
				  'desciption' : 'NGS analysis team',
				  'notes' : 'This group is for ...',
				},
				{
					...
			]

=cut


sub getGroups {
	my $self		=	shift;
	$self->logDebug("Common::getGroups()");
    	my $json			=	$self->json();

	#### GET USERNAME AND SESSION ID
    my $username = $json->{'username'};
	$self->logDebug("username", $username);

    #### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM groups
WHERE username='$username'};
	$self->logDebug("$query");	;
	my $groups = $self->db()->queryhasharray($query);
	$self->logDebug("groups", $groups);

	$groups = [] if not defined $groups;

	return $groups;
}






=head2

	SUBROUTINE		saveGroups

	PURPOSE
	
		SAVE ALL THE USERS IN THE 'GROUP' TABLE SPECIFIED IN THE
		
		JSON OBJECT SENT FROM THE CLIENT:
		
			1. ADD ANY USERS NOT PRESENT IN THE TABLE BUT
			
				PRESENT IN THE JSON OBJECT
				
			2. DELETE ANY USERS PRESENT IN THE TABLE BUT
			
				NOT PRESENT IN THE JSON OBJECT

=cut

sub saveGroups {
	my $self		=	shift;
	$self->logDebug("()");

    	my $json			=	$self->json();

	my $jsonParser = JSON->new();
	#my $users = $jsonParser->decode($json->{data});
	my $users = $jsonParser->decode($json->{data});

	$self->logDebug("users", $users);

	#### VALIDATE    
    my $username = $json->{'username'};
    my $session_id = $json->{'sessionId'};
    if ( not $self->validate($username, $session_id) )
    {
        $self->logError("User $username not validated");
        return;
    }

    my $query = qq{SELECT DISTINCT groupname, groupdesc
	FROM groupmember
	WHERE owner='$username'};
    $self->logDebug("$query");
	my $groups = $self->db()->queryhasharray($query);
	$groups = [] if not defined $groups;
	
	my $add_users;
	my $remove_users;
	
	#### CHECK WHICH USERS TO ADD
	foreach my $user ( @$users )
	{
		my $groupname = $user->{groupname};
		my $groupdesc = $user->{groupdesc};
		$self->logDebug("NEW:\t$groupdesc\t$groupname");
		
		my $matched = 0;
		foreach my $group ( @$groups )
		{
			my $existing_name = $group->{groupdesc};
			my $existing_groupname = $group->{groupname};
			if ( $existing_name eq $groupdesc
				and $existing_groupname eq $groupname )
			{
				$self->logDebug("Match\t$existing_name\t$existing_groupname");
				$matched = 1;
				$user->{groupdesc} = $group->{groupdesc};
				$self->logDebug("user", $user);
				last;
			}
		}
		
		$user->{owner} = $username;
		push @$add_users, $user if not $matched;
	}
	
	$self->logDebug("add_users", $add_users);
	
	#### CHECK WHICH USERS TO REMOVE
	foreach my $group ( @$groups )
	{
		my $existing_name = $group->{groupdesc};
		my $existing_groupname = $group->{groupname};
		
		$self->logDebug("existing_name", $existing_name);
		$self->logDebug("existing_groupname", $existing_groupname);
		
		my $matched = 0;
		foreach my $user ( @$users )
		{
			my $groupname = $user->{groupname};
			my $groupdesc = $user->{groupdesc};
			if ( $existing_name eq $groupdesc
				and $existing_groupname eq $groupname )
			{				
				$self->logDebug("Match\t$groupdesc\t$groupname");
				$matched = 1;
			}
		}
		
		push @$remove_users, $group if not $matched;
	}

	$self->logDebug("remove_users", $remove_users);

	my $fields = $self->db()->fields("groups");
	my $fieldstring = join ",", @$fields;
	$self->logDebug("Adding users...");	;
	foreach my $user ( @$add_users )
	{
		my $tsvline = $self->db()->fieldsToTsv($fieldstring, $user);
		$tsvline =~ s/\t/', '/g;
		$tsvline = "'" . $tsvline . "'";
		$self->logDebug("tsvline", $tsvline);
		
		$query = qq{INSERT INTO groups VALUES ($tsvline)};
		$self->logDebug("$query");
		my $success = $self->db()->do($query);
		$self->logDebug("Insert success", $success);
	}
	$self->logDebug("Removing users...");
	foreach my $user ( @$remove_users )
	{
		my $groupdesc = $user->{groupdesc};
		my $groupname = $user->{groupname};
		my $query = qq{DELETE FROM groupmember WHERE groupdesc = '$groupdesc' AND groupname = '$groupname' AND owner = '$username'};
		$self->logDebug("$query");
		my $success = $self->db()->do($query);
		$self->logDebug("Insert success", $success);
	}
	
	$self->logStatus("saveGroups completed");
}



=head2

	SUBROUTINE		addGroup

	PURPOSE
	
		1. ADD A GROUP OBJECT TO THE groups TABLE
		
		2. ADD A CORRESPONDING ENTRY TO THE access TABLE
		
=cut

sub addGroup {
	my $self		=	shift;

    	my $json			=	$self->json();

	#### ADD USERNAME TO NEW GROUP
	my $group = $json->{data};
    my $username = $json->{username};
	$group->{username} = $username;

	my $success = $self->_addGroup($group);
	$self->logStatus("Group $group->{groupname} added to access table") if $success;
	$self->logError("Added group $group->{groupname} to groups table but could not add to access table") if not $success;
	
}

=head2

	SUBROUTINE		_addGroup

	PURPOSE
	
		1. ADD A GROUP OBJECT TO THE groups TABLE
		
		2. ADD A CORRESPONDING ENTRY TO THE access TABLE
		
=cut

sub _addGroup {
	my $self		=	shift;
	$self->logDebug("Admin::_addGroup(group)");
	my $group		=	shift;
	$self->logDebug("group", $group);
	
	#### SET UP ADD/REMOVE VARIABLES
	my $table = "groups";
	my $required_fields = [ "username", "groupname" ];
	my $inserted_fields = [ "username", "groupname", "description", "notes" ];

	#### DO THE DELETE
	my $success = $self->_removeFromTable($table, $group, $required_fields);
	$self->logDebug("_removeFromTable success ", $success);

	#### DO THE ADD
	$success = $self->_addToTable($table, $group, $required_fields, $inserted_fields);
	$self->logError("Could not add group $group->{groupname} to groups table") and return if not $success;
	
	#### ADD ENTRY IN access TABLE
	my $access = {
		owner		=>	$group->{username},
		groupname	=>	$group->{groupname},
		groupwrite	=>	0,
		groupcopy	=>	1,
		groupview	=>	1,
		worldwrite	=>	0,
		worldcopy	=>	0,
		worldview	=>	0
	};
	$self->logDebug("access", $access);
	
	return $self->_addAccess($access);
}

=head2

	SUBROUTINE		removeGroup

	PURPOSE
	
		DELETE A GROUP OBJECT FROM
		
		1. THE group TABLE
		
		2. THE groupmember TABLE IF PRESENT
		
=cut

sub removeGroup {
	my $self		=	shift;
	$self->logDebug("Admin::removeGroup()");

    	my $json			=	$self->json();

	#### REMOVE FROM groups
	my $group = $json->{data};
	$group->{owner} = $json->{username};
	$group->{username} = $json->{username};
	my $success = $self->_removeGroup($group);
	$self->logError("Could not remove group $group->{groupname} from groups table") and return if not $success;

	#### REMOVE FROM access
	$self->logDebug("Doing _removeAccess");
	$self->_removeAccess($group);
	$self->logDebug("Completed _removeAccess");

	#### REMOVE FROM groupmember
	$self->_removeGroupMembers($group);
	$self->logDebug("Completed _removeGroupMembers");

	$self->logStatus("Group $group->{groupname} removed");
}

=head2

	SUBROUTINE		_removeGroup

	PURPOSE
	
		DELETE A GROUP OBJECT FROM
		
		1. THE group TABLE
		
		2. THE groupmember TABLE IF PRESENT

		3. THE access TABLE		

=cut

sub _removeGroup {
	my $self		=	shift;
	$self->logDebug("Admin::_removeGroup()");
	my $group 		= 	shift;

	#### SET UP ADD/REMOVE VARIABLES
	my $table = "groups";
	my $required_fields = [ "username", "groupname" ];
	my $inserted_fields = [ "username", "groupname", "description", "notes" ];

	#### DO THE DELETE
	return $self->_removeFromTable($table, $group, $required_fields);
}

sub _removeGroupMembers {
	my $self		=	shift;	
	my $group 		= 	shift;

	my $table = "groupmember";
	return $self->_removeFromTable($table, $group, ["groupname", "owner"]);
}

=head2

	SUBROUTINE		addGroupUsers

	PURPOSE
	
		SAVE ALL THE USERS IN THE 'GROUP' TABLE SPECIFIED IN THE
		
		JSON OBJECT SENT FROM THE CLIENT:
		
			1. ADD ANY USERS NOT PRESENT IN THE TABLE BUT
			
				PRESENT IN THE JSON OBJECT
				
			2. DELETE ANY USERS PRESENT IN THE TABLE BUT
			
				NOT PRESENT IN THE JSON OBJECT

=cut

sub addGroupUsers {
	my $self		=	shift;
	$self->logDebug("Admin::removeGroup()");
	
	$self->logDebug("()");

    	my $json			=	$self->json();

	my $jsonParser = JSON->new();
	#my $users = $jsonParser->decode($json->{data});
	my $users = $jsonParser->decode($json->{data});

	$self->logDebug("users", $users);

	#### VALIDATE    
    my $username = $json->{'username'};
    my $session_id = $json->{'sessionId'};
	$self->logDebug("username", $username);
	$self->logDebug("sessionId", $session_id);
    if ( not $self->validate($username, $session_id) )
    {
        $self->logError("User $username not validated");
        return;
    }

    #my $query = qq{SELECT * FROM groupmember WHERE owner='$owner'};
    my $query = qq{SELECT DISTINCT name, groupname, type
	FROM groupmember
	WHERE owner='$username'};
    $self->logDebug("$query");
	my $groupmember = $self->db()->queryhasharray($query);
    if ( not defined $groupmember )
    {
        my $json = "{   'error' : 'No groupmember for owner: $username'    }";
        $self->logDebug("$json");
        return;
    }
	$self->logDebug("groupmember", $groupmember);
	
	my $add_users;
	my $remove_users;
	
	#### CHECK WHICH USERS TO ADD
	foreach my $user ( @$users )
	{
		my $groupname = $user->{groupname};
		my $name = $user->{name};
		my $matched = 0;
		foreach my $groupuser ( @$groupmember )
		{
			my $existing_name = $groupuser->{name};
			my $existing_groupname = $groupuser->{groupname};
			if ( $existing_name eq $name
				and $existing_groupname eq $groupname )
			{
				$self->logDebug("Match\t$existing_name\t$existing_groupname");
				$matched = 1;
				$user->{groupdesc} = $groupuser->{groupdesc};
				last;
			}
		}
		
		$user->{owner} = $username;
		push @$add_users, $user if not $matched;
	}
	
	$self->logDebug("add_users", $add_users);
	
	#### CHECK WHICH USERS TO REMOVE
	foreach my $groupuser ( @$groupmember )
	{
		my $existing_name = $groupuser->{name};
		my $existing_groupname = $groupuser->{groupname};
		
		$self->logDebug("existing_name", $existing_name);
		$self->logDebug("existing_groupname", $existing_groupname);
		
		my $matched = 0;
		foreach my $user ( @$users )
		{
			my $groupname = $user->{groupname};
			my $name = $user->{name};		
			if ( $existing_name eq $name
				and $existing_groupname eq $groupname )
			{
				
				$self->logDebug("Match\t$name\t$groupname");
				$matched = 1;
			}
		}
		
		push @$remove_users, $groupuser if not $matched;
	}
	$self->logDebug("remove_users", $remove_users);

	#### ADD USERS
	my $fields = $self->db()->fields("groupmember");
	my $fieldstring = join ",", @$fields;
	$self->logDebug("Fieldstring", $fieldstring);	;
	
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	
	$self->logDebug("Adding users...");	;
	foreach my $user ( @$add_users )
	{
		my $groupname = $user->{groupname};
		my $query = qq{SELECT groupdesc FROM groupmember WHERE groupname = '$groupname'};
		my $groupdesc = $self->db()->query($query);
		$self->logDebug("groupdesc", $groupdesc);
		
		my $location = "$fileroot/$user->{name}";
		$self->logDebug("location", $location);
		
		$user->{groupdesc} = $groupdesc;
		$user->{location} = $location;
		
		my $tsvline = $self->db()->fieldsToTsv($fieldstring, $user);
		$tsvline =~ s/\t/', '/g;
		$tsvline = "'" . $tsvline . "'";
		$self->logDebug("tsvline", $tsvline);
		
		$query = qq{INSERT INTO groupmember VALUES ($tsvline)};
		$self->logDebug("$query");
		my $success = $self->db()->do($query);
		$self->logDebug("Insert 'groupmember' success", $success);
		
		#### UPDATE access TABLE
		#### SO THAT IS IS CONSTANTLY IN SYNC WITH groupmember TABLE
		#### NB: DEFAULT PERMISSIONS: 751
		if ( $user->{type} eq 'project' )
		{
			my $project = $user->{name};
			$query = qq{INSERT INTO access
VALUES ('$project', '$groupname', '$username', 7, 5, 1, '$username/$project')};
		my $success = $self->db()->do($query);
		$self->logDebug("Insert 'access' success", $success);
		}
	}
	
	
	#### REMOVE USERS
	$self->logDebug("Removing users...");
	foreach my $user ( @$remove_users )
	{
		my $name = $user->{name};
		my $groupname = $user->{groupname};
		my $query = qq{DELETE FROM groupmember
WHERE name = '$name'
AND groupname = '$groupname'
AND owner = '$username'};
		$self->logDebug("$query");
		my $success = $self->db()->do($query);
		$self->logDebug("Delete 'groupmember' success", $success);

		#### UPDATE access TABLE
		#### SO THAT IS IS CONSTANTLY IN SYNC WITH groupmember TABLE
		#### NB: DEFAULT PERMISSIONS: 751
		if ( $user->{type} eq 'project' )
		{
			my $project = $user->{name};
			$query = qq{DELETE FROM access
WHERE project = '$project'
AND groupname = '$groupname'
AND owner = '$username'};
		$self->logDebug("$query");
		my $success = $self->db()->do($query);
		$self->logDebug("Delete 'access' success", $success);
		}
	}
	
	$self->logStatus("addGroupUsers completed");
}

=head2

    SUBROUTINE:     getGroupMembers
    
    PURPOSE:

		RETURN THESE GROUP-RELATED TABLES:
		
			groupmember 
		
	INPUTS
	
		1. JSON OBJECT CONTAINING username AND sessionId

	OUTPUTS	

			groups: JSON groupmember HASH

			E.G.:

			{
				'nextgen' : [],
				'bioinfo' : [
					{
					  'groupdesc' : '',
					  'owner' : 'syoung',
					  'location' : '/mihg/data/NGS/syoung/base/pipeline/human-chr-squashed',
					  'groupname' : 'bioinfo',
					  'name' : 'Eland squashed human chromosomes (36.1)',
					  'type' : 'source',
					  'description' : 'A directory containing human chromosome sequence files processed with squashGenome for input into Eland(Build 36.1)'
					},
					{
					  'groupdesc' : undef,
					  'owner' : 'syoung',
					  'location' : '/mihg/data/NGS/syoung/base/pipeline/human-chr/fa',
					  'groupname' : 'bioinfo',
					  'name' : 'Human chromosome FASTA (36.1)',
					  'type' : 'source',
					  'description' : 'Human chromosome FASTA files (Build 36.1)'
					},
				   ...
				]
			}

=cut


sub getGroupMembers {
	my $self		=	shift;
	
	$self->logDebug("()");

    	my $json			=	$self->json();

	#### GET USERNAME
    my $username = $json->{'username'};

	#### VALIDATE USER USING SESSION ID	
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### GET ALL GROUPS AND USERS IN THIS USER'S groupmember TABLE
    my $query = qq{SELECT *
FROM groupmember 
WHERE owner='$username'
ORDER BY groupname, name};
	$self->logDebug("$query");
    my $groupmember = $self->db()->queryhasharray($query);
	$groupmember = [] if not defined $groupmember;
	
	return $groupmember;

=head2
	#### SORT SOURCES BY groupname INTO AN ARRAY OF HASHES
	my $groups = {};
	my $groupsarray = [];
	my $current_groupname = $$groupmember[0]->{groupname};
	$self->logDebug("current_groupname", $current_groupname);
	foreach my $groupuser( @$groupmember)
	{
		my $groupname = $groupuser->{groupname};
		my $name = $groupuser->{name};
		$self->logDebug("groupname", $groupname);
	
		if ( $groupname eq $current_groupname )
		{
		$self->logDebug("current_groupname", $current_groupname);
			$self->logDebug("pushing groupuser with groupname '$groupname' and name '$name' onto groupsarray");
	
			push @$groupsarray, $groupuser;
		}
		else
		{
			$self->logDebug("pushing groupuser with groupname '$groupname' and name '$name' onto groupsarray");
			
			#### ADD TO GROUP USERS HASH
			$groups->{$current_groupname} = $groupsarray;
	
			#### REINITITALISE GROUP USERS ARRAY FOR NEW HASH KEY
			$groupsarray = [];
			#if ( $groupuser->{type} eq 'group' )
			#{
				push @$groupsarray, $groupuser;
			#}
			
			#### SET NEW HASH KEY
			$current_groupname = $groupname;
		}
	}
	
	#### ADD TO GROUP USERS HASH
	$groups->{$current_groupname} = $groupsarray;
	
	return $groups;
=cut

}

=head2

	SUBROUTINE		deleteProject

	PURPOSE
	
		ADD A GROUP OBJECT TO THE projects TABLE
		
=cut

sub deleteProject {
	my $self		=	shift;
	$self->logDebug("Admin::deleteProject()");

    	my $json			=	$self->json();

	#### VALIDATE    
    my $username = $json->{'username'};
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### DELETE FROM project TABLE
	my $name = $json->{data}->{name};
	my $description = $json->{data}->{description};
	my $notes = $json->{data}->{notes};
	my $query = qq{DELETE FROM project
	WHERE username='$username'
	AND name='$name'};
	$self->logDebug("query", $query);
	my $success = $self->db()->do($query);	

	#### DELETE FROM groupmember TABLE
	$query = qq{DELETE FROM groupmember
	WHERE owner='$username'
	AND name='$name'};
	$self->logDebug("query", $query);
	$self->db()->do($query);	
	
	if ( $success == 1 )
	{
		#### REMOVE PROJECT FROM workflow TABLE
		$self->removeProjectWorkflow();
	}
	else
	{
		$self->logError("Could not delete project $name from project table");
	}

	return;
}








=head2

    SUBROUTINE:     removeFromGroup
    
    PURPOSE:

        VALIDATE THE admin USER THEN REMOVE A SOURCE, user, ETC.
		
		FROM THE groupmember TABLE UNDER THE GIVEN groupname
		
=cut

sub removeFromGroup {
	my $self		=	shift;
	
	$self->logDebug("()");

    	my $json			=	$self->json();

	#### VALIDATE USER USING SESSION ID	
    my $username = $json->{'username'};
    $self->logError("User $username not validated") and return unless $self->validate($username);

	#### PARSE JSON INTO OBJECT
	my $jsonParser = JSON->new();
	my $data = $json->{data};
	
	#### PRIMARY KEYS FOR apps TABLE:
	####    name, type, location
	my $groupname = $data->{groupname};
	my $name = $data->{name};
	my $description = $data->{description};
	my $location = $data->{location};
	my $type = $data->{type};
	$self->logDebug("name", $name);
	$self->logDebug("location", $location);
	
	if ( not defined $groupname or not defined $name or not defined $type )
	{
		$self->logError("Either groupname, name or type not defined");
		return;
	}
	my $query = qq{DELETE FROM groupmember
WHERE owner = '$username'
AND groupname = '$groupname'
AND name = '$name'
AND type = '$type'};

	$self->logDebug("$query");
	
	my $success = $self->db()->do($query);
	if ( $success == 1 )
	{
		$self->logStatus("Deleted $json->{data}->{type} $name from group $groupname");
	}
	else
	{
		$self->logError("Could not delete $json->{data}->{type} $name from group $groupname");
	}
	return;
}




=head2

    SUBROUTINE:     addToGroup
    
    PURPOSE:

        VALIDATE THE admin USER THEN ADD A SOURCE TO
		
		THE groupmember TABLE UNDER THE GIVEN groupname
		
=cut

sub addToGroup {
	my $self		=	shift;
	
	$self->logDebug("Admin::addToGroup()");

    	my $json			=	$self->json();

	#### VALIDATE    
	$self->logError("User not validated") and return unless $self->validate();

	#### PARSE JSON INTO OBJECT
	my $jsonParser = JSON->new();
	my $data = $json->{data};
	$data->{owner} = $json->{username} if not defined $data->{owner};

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "groupmember";
	my $required_fields = ["owner", "groupname", "name", "type"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### DO THE ADD
	my $inserted_fields = $self->db()->fields($table);
	my $success = $self->_addToTable($table, $data, $required_fields, $inserted_fields);
 	$self->logError("Could not add $json->{type} $json->{name} to group $data->{groupname}") and return if not defined $success;

	$self->logStatus("Added $data->{type} $data->{name} to group $data->{groupname}");
	return;
}






1;