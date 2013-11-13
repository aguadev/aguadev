package Agua::Common::Privileges;
use Moose::Role;
use Moose::Util::TypeConstraints;

# Ints
#has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );
has 'requestor'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sessionId'     => ( isa => 'Str|Undef', is => 'rw' );


=head2

	PACKAGE		Agua::Common::Privileges
	
	PURPOSE
	
		AUTHENTICATION AND ACCESS PRIVILEGE METHODS FOR Agua::Common
		
=cut

use Data::Dumper;

##############################################################################
#				AUTHENTICATION METHODS
##############################################################################

sub isAdminUser {
=head2

    SUBROUTINE      isAdminUser
    
    PURPOSE
    
        CONFIRM USER HAS ADMIN PRIVILEGES
        
	INPUTS
	
		1. JSON->USERNAME
		
		2. CONF->ADMINS (COMMA-SEPARATED)
	
	OUTPUTS
	
		1. RETURN 1 ON SUCCESS, 0 ON FAILURE

=cut
	my $self		=	shift;
	my $username	=	shift;
    $self->logDebug("username", $username);

	my $json 		=	$self->json();
	my $conf 		=	$self->conf();
	my $isAdminUsers 	= 	$conf->getKey('agua', "ADMINS");
    $self->logDebug("isAdminUsers", $isAdminUsers);

	if ( not defined $isAdminUsers ) {
		return 0;
	}
	my @users = split ",", $isAdminUsers;
	foreach my $adminuser ( @users ) {
		$self->logDebug("adminuser", $adminuser);
		return 1 if $adminuser eq $username;
	}
	
	return 0;
}

sub validate {
=head2

    SUBROUTINE      validate
    
    PURPOSE
    
        CHECK SESSION ID AGAINST STORED SESSION IN sessions TABLE
        
        TO VALIDATE USER
        
=cut
	my $self		=	shift;
		
	return 1 if  $self->validated();

	my $username	=	$self->username();
	my $requestor	=	$self->requestor();
	my $session_id	=	$self->sessionId();
	$self->logDebug("username", $username);
	$self->logDebug("requestor", $requestor);
	$self->logDebug("session_id", $session_id);

	#### VALIDATE GUEST USER
	my $guestvalidated = $self->validateGuest();
	$self->logDebug("guestvalidated", $guestvalidated);
	$self->logError("guest access denied") and exit if not $guestvalidated;
	
	#### VALIDATE TEST USER
	return 1 if $self->validateTest();
	
	#### CHECK INPUTS
	$self->logError("username not defined") and exit if not defined $username;

	#### SET 'AS USER'
	my $as_user = $username;
	$as_user = $requestor if defined $requestor and $requestor;
	
	#### VALIDATE BASED ON PRESENCE OF SESSION ID IN sessions TABLE
	my $query = qq{
	SELECT username FROM sessions
	WHERE username = '$as_user'
	AND sessionid = '$session_id'};
    $self->logDebug("query", $query);
	my $validated = $self->db()->query($query);
	$self->logDebug("validated", $validated);

    #### IF IT DOES EXIST, UPDATE THE TIME
    if ( defined $validated )
    {
		my $conf = $self->conf();
		my $now = "DATETIME('NOW')";
		$now = "NOW()" if $conf->getKey("database", "DBTYPE") =~ /^MYSQL$/i;

        my $update_query = qq{UPDATE sessions
	SET datetime = $now
	WHERE username = '$username'
	AND sessionid = '$session_id'};
        $self->logDebug("Update query", $update_query);
        my $update_success = $self->db()->do($update_query);
        $self->logDebug("Update success", $update_success);
    }
	
	if ( not defined $validated )	{	return	0;	}
	
	$self->validated(1);
	return 1;
}

sub validateGuest {
	my $self		=	shift;
	
	my $username	=	$self->username();
	$username		=	$self->requestor() if $self->requestor();
	
	my $guestuser = $self->conf()->getKey("agua", "GUESTUSER");
	$self->logDebug("guestuser", $guestuser);	
	my $guestaccess = $self->conf()->getKey("agua", "GUESTACCESS");
	$self->logDebug("guestaccess", $guestaccess);
	my $guestlock = $self->conf()->getKey("agua", "GUESTLOCK");
	$self->logDebug("guestlock", $guestlock);
	
	#### SKIP IF NOT GUEST USER
	return 1 if not $username eq $guestuser;
	$self->logDebug("username is guestuser: $guestuser");
	
	#### QUIT IF GUEST ACCESS NOT ALLOWED
	$self->logError("guest access denied") and exit if not $guestaccess;
	
	#### SKIP IF GUESS LOCK NOT ENABLED
	return 1 if not $guestlock;
	$self->logDebug("guest lock is enabled: $guestlock");

	#### GET MODE
	my $mode = $self->mode();
	$self->logDebug("mode", $mode);

	#### RETURN 1 IF MODE IS ALLOWED, 0 OTHERWISE
	my @allowedmodes = qw(
getData
checkFile
checkFiles
fileSystem
);
	foreach my $allowedmode ( @allowedmodes ) {
		if ( $mode eq $allowedmode ) {
			return 1;
		}
	}
	
	return 0;
}

sub validateTest {
	my $self		=	shift;
	
	my $username	=	$self->username();
	$username		=	$self->requestor() if $self->requestor();
	$self->logDebug("username", $username);
	my $testuser	=	$self->conf()->getKey("database", "TESTUSER");
	$self->logDebug("testuser", $testuser);
	
	if ( $testuser eq $username ) {
		my $testpassword = $self->conf()->getKey("database", "TESTPASSWORD");
		$self->logDebug("Doing setDbh()");
		
		$self->setDbh({
			user		=>	$testuser,
			password	=>	$testpassword
		});
		return 1;
	}
	
	return 0;
}

##############################################################################
#				PRIVILEGE METHODS
##############################################################################
sub canViewGroup {
    my $self        =   shift;    
    my $owner       =   shift;
    my $groupname   =   shift;
    my $requestor   =   shift;
	my $type		=	shift;
	$self->logDebug("(owner, groupname, requestor)");
	$self->logDebug("owner", $owner);
	$self->logDebug("groupname", $groupname);
	$self->logDebug("requestor", $requestor);
	my $privileges = $self->_getGroupPrivileges($owner, $groupname, $requestor, $type);
	return if not defined $privileges;
	
	return $privileges->{groupview};
}

sub canCopyGroup {
    my $self        =   shift;    
    my $owner       =   shift;
    my $groupname   =   shift;
    my $requestor   =   shift;
	my $type		=	shift;
	$self->logDebug("(owner, groupname, requestor)");
	$self->logDebug("owner", $owner);
	$self->logDebug("groupname", $groupname);
	$self->logDebug("requestor", $requestor);
	my $privileges = $self->_getGroupPrivileges($owner, $groupname, $requestor, $type);
	return if not defined $privileges;

	return $privileges->{groupview};
}

sub _getGroupPrivileges {
=head2

    SUBROUTINE:     _getGroupPrivileges
    
    PURPOSE:
    
		INPUTS
			
			1. NAME OF OWNER
			
			2. NAME OF REQUESTOR

			3. GROUP NAME

		OUTPUTS
		
			1. RETURN 1 IF A USER CAN ACCESS ANOTHER USER'S PROJECT.
		
			2. RETURN 0 OTHERWISE

=cut

    my $self        =   shift;    
    my $owner       =   shift;
    my $groupname   =   shift;
    my $requestor   =   shift;
	my $type		=	shift;
	$self->logDebug("(owner, groupname, requestor)");
	$self->logDebug("owner", $owner);
	$self->logDebug("groupname", $groupname);
	$self->logDebug("requestor", $requestor);
	my $belongs = $self->_belongsToGroup($owner, $groupname, $requestor, $type);
	return 0 if not $belongs;
	my $privileges = $self->_getPrivileges($owner, $groupname);
	$self->logDebug("privileges", $privileges);
	
	return $privileges;
}

sub _belongsToGroup {
=head2

    SUBROUTINE:     _belongsToGroup
    
    PURPOSE:
    
		INPUTS
			
			1. NAME OF OWNER
			
			2. NAME OF REQUESTOR

			3. GROUP NAME

		OUTPUTS
		
			1. RETURN 1 IF THE USER (requestor) BELONGS TO ANOTHER USER'S PROJECT (owner)
		
			2. RETURN 0 OTHERWISE

=cut

    my $self        =   shift;    
    my $owner       =   shift;
    my $groupname   =   shift;
    my $requestor   =   shift;
	my $type		=	shift;
	$self->logDebug("(owner, groupname, requestor)");
	$self->logDebug("owner", $owner);
	$self->logDebug("groupname", $groupname);
	$self->logDebug("requestor", $requestor);
	
		
	my $query = qq{SELECT 1 FROM groupmember
WHERE groupname = '$groupname'
AND owner = '$owner'
AND name = '$requestor'
AND type = 'user'};
	$self->logDebug("$query");
	my $access = $self->db()->query($query);
	
	return 1 if defined $access;
	return 0;
}

sub _getPrivileges {
=head2

    SUBROUTINE:     _getPrivileges
    
    PURPOSE:
    
		INPUTS
			
			1. NAME OF OWNER
			
			2. NAME OF REQUESTOR

			3. GROUP NAME
			
			4. TYPE (PROJECT/SOURCE)

		OUTPUTS
		
			1. RETURN 1 IF A USER CAN ACCESS ANOTHER USER'S PROJECT.
		
			2. RETURN 0 OTHERWISE

=cut

    my $self        =   shift;    
    my $owner       =   shift;
    my $groupname     =   shift;
	$self->logDebug("(owner, groupname, requestor, type)");
	$self->logDebug("owner", $owner);
	$self->logDebug("groupname", $groupname);

	#### MAKE SURE THAT THE GROUP PRIVILEGES ALLOW ACCESS
	my $query = qq{SELECT *
FROM access
WHERE owner = '$owner'
AND groupname='$groupname'};
	$self->logDebug("$query");
	my $privileges = $self->db()->queryhash($query);
	$self->logDebug("privileges", $privileges);

	return $privileges;
}

sub _canAccess {
=head2

    SUBROUTINE:     _canAccess
    
    PURPOSE:
    
		INPUTS
			
			1. IDENTITY OF SHARER AND SHAREE

			2. LOCATION OF PROJECT OR SOURCE

			3. TYPE - WHETHER PROJECT OR SOURCE
	
		OUTPUTS
		
			1. RETURN 1 IF A USER CAN ACCESS ANOTHER USER'S PROJECT.
		
			2. RETURN 0 OTHERWISE

=cut

    my $self        =   shift;    
    my $owner       =   shift;
    my $groupname     =   shift;
    my $requestor   =   shift;
	my $type		=	shift;
	$self->logDebug("(owner, groupname, requestor, type)");
	$self->logDebug("owner", $owner);
	$self->logDebug("groupname", $groupname);
	$self->logDebug("requestor", $requestor);
	$self->logDebug("type", $type);

    #### GET GROUP NAME FOR PROJECT
    my $query = qq{SELECT DISTINCT groupname from groupmember where owner = '$owner' and groupname = '$groupname' and type = '$type'};
    $self->logDebug("$query");
    my $groupnames = $self->db()->queryarray($query);
	$self->logDebug("groupnames: @$groupnames");
    
	#### RETURN IF GROUP NAME NOT IN access TABLE
	if ( not defined $groupnames )
    {
        return;
    }
    
    #### CONFIRM THAT USER BELONGS TO THIS GROUP
	my $accessible = 0;
	for my $groupname ( @$groupnames )
	{
		my $access = $self->_getGroupPrivileges($groupname, $owner, $requestor);
		$self->logDebug("Access", $access);
		if ( $access )
		{
			$accessible = 1;
			last;
		}
	}

	if ( not $accessible )
	{
		return;
	}

    $self->logDebug("accessible: $accessible. Returning 1");
	return 1 if defined $accessible;
	
    $self->logDebug("accessible: $accessible. Returning 0");
	return 0;
}


sub projectPrivilege {
=head2

    SUBROUTINE:     projectPrivilege
    
    PURPOSE:
    
        1. Check the rights of a user to access another user's project

=cut
    my $self        =   shift;    
    my $owner       =   shift;
    my $project     =   shift;
    my $requestor   =   shift;
    my $privilege   =   shift;
    my $type		=	shift;
	
	$type = "project" if not defined $type;
	$self->logDebug("Common::projectPrivilege(owner, project, requestor)");
	$self->logDebug("owner", $owner);
	$self->logDebug("project", $project);
	$self->logDebug("privilege", $privilege) if defined $privilege;
	$self->logDebug("requestor", $requestor);
	$self->logDebug("type", $type);

    #### LATER: GET MAX PRIVILEGES ACROSS ALL GROUPS THE USER BELONGS TO
    my $max_privilege;

	#### CHECK IF THE PROJECT IS WORLD-ACCESSIBLE
	my $query = qq{SELECT access.* FROM access, groupmember
WHERE access.worldwrite = 1
OR access.worldview = 1
OR access.worldcopy = 1
AND groupmember.name='$project'
AND groupmember.type='project'
AND groupmember.owner='$owner'
AND access.owner=groupmember.owner
AND access.groupname=groupmember.groupname};
	my $hash = $self->db()->queryhash($query);
	$self->logDebug("hash", $hash);
	my $max_write = $hash->{worldwrite};
    my $max_copy = $hash->{worldcopy};
    my $max_view = $hash->{worldview};

    #### GET GROUP NAME FOR PROJECT
    $query = qq{SELECT groupname FROM  groupmember
WHERE owner = '$owner'
AND name = '$project'
AND type = '$type'};
    $self->logDebug("$query");
    my $groupnames = $self->db()->queryarray($query);
	$self->logDebug("groupnames", $groupnames);
	return if not defined $groupnames;
    
	#### RETURN THE MAXIMUM PRIVILEGE FOR THIS USER AMONG ALL OF THE
    #### GROUPS THEY BELONG TO (FOR THIS SHARER)
    foreach my $groupname ( @$groupnames )
    {
        $query = qq{SELECT owner
FROM groupmember
WHERE groupname = '$groupname'
AND owner = '$owner'
AND name = '$requestor'
AND type = 'user'};
        $self->logDebug("$query");
        my $owner = $self->db()->query($query);
        $self->logDebug("owner", $owner)  if defined $owner;
        $self->logDebug("owner not defined")  if not defined $owner;
        next if not defined $owner;
    
        #### MAKE SURE THAT THE GROUP PRIVILEGES ALLOW ACCESS
        $query = qq{SELECT groupwrite, groupcopy, groupview
FROM access
WHERE owner = '$owner'
AND groupname='$groupname'};
        $self->logDebug("$query");
        my $privileges = $self->db()->queryhash($query);
        next if not defined $privileges;
        $self->logDebug("privileges", $privileges);
        $max_write = $privileges->{groupwrite} if $max_write < $privileges->{groupwrite};
        $max_copy = $privileges->{groupcopy} if $max_copy < $privileges->{groupcopy};
        $max_view = $privileges->{groupview} if $max_view < $privileges->{groupview};
    }
    
    $self->logDebug("FINAL group privileges:");
    return { groupwrite => $max_write, groupcopy => $max_copy, groupview => $max_view };
}

sub sumPrivilege () {
	my $self		=	shift;
	my $rights		=	shift;
	my $group		=	shift;
	
	my $privilege = 0;
	$privilege += $rights->{$group . "write"} if defined $rights->{$group . "write"};
	$privilege += $rights->{$group . "copy"}  if defined $rights->{$group . "copy"};
	$privilege += $rights->{$group . "view"}  if defined $rights->{$group . "view"};
	
	return $privilege;
}


sub canCopy() {
    my $self    =   shift;
    my $privileges = $self->projectPrivilege(@_);
    $self->logDebug("privileges", $privileges);

    my $can_copy = $privileges->{groupcopy};
    $self->logDebug("can_copy", $can_copy);

    return $can_copy;
}



1;