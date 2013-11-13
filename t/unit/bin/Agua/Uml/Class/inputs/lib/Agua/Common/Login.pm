package Agua::Common::Login;
use Moose::Role;

has 'mode'		=> ( isa => 'Str|Undef', is => 'rw' );

=head2

	PACKAGE		Agua::Common::Login
	
	PURPOSE
	
		SOURCE METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

####///}}}}
##############################################################################
#				LOGIN METHODS
sub ldap {
=head2

    SUBROUTINE      ldap
    
    PURPOSE
    
        USE LDAP SERVER TO VALIDATE USER
        
	INPUTS
	
		1. JSON->USERNAME
		
		2. JSON->PASSWORD
		
		3. CONF->LDAP_SERVER
	
	OUTPUTS
	
		1. RETURN 1 ON SUCCESS, 0 ON FAILURE

=cut
	my $self		=	shift;
	$self->logDebug("Agua::Common::Login::ldap()");

	use Net::LDAP;

	my $json 		=	$self->json();
	my $conf 		=	$self->conf();

	my $username	=	$json->{username};
	my $password 	=	$json->{password};

	#### EXAMPLE:
	#### 'ldap.florida.edu'
	#### Server: ldap.ccs.florida.edu
	#### Binddn: uid=USERNAME,ou=Users,dc=ccs,dc=florida,dc=edu
	#### Bindpw: USERPASS
	my $ldap_server = $conf->getKey('agua', "LDAP_SERVER");
	$self->logDebug("LDAP SERVER", $ldap_server);
	
	####  RETURN 1 IF NO LDAP SERVER
	return 1 if not defined $ldap_server;
	
	#### CREATE Net::LDAP OBJECT
	my $ldap = Net::LDAP->new($ldap_server);

	#### TEST BIND TO A DIRECTORY WITH DN AND PASSWORD.
	#### WILL RETURN '0' IF AUTHENTICATED
	#### EXAMPLE UID LINE:
	####	"uid=$username,ou=Users,dc=ccs,dc=miami,dc=edu"
	my $uid  = 	"uid=$username,ou=Users";
	my @dnsnodes = split "\.", $ldap;
	foreach my $dnsnode ( @dnsnodes ) {
		$uid .= ",dc=" . lc($dnsnode);
	}
	$self->logDebug("uid", $uid);

	my $message = $ldap->bind(
		$uid,
		"password" => "$password"
	);

	my $result = $message->code();
	$self->logDebug("ldap result", $result);
	
	#### CONVERT TO 1 IF SUCCES (I.E., RESULT = 0)
	if ( $result == 0 ) {
		$result = 1;
	}
	else {
		$result = 0;
	}
	
	return $result;
}

sub submitLogin {
=head2

    SUBROUTINE      login
    
    PURPOSE
    
        AUTHENTICATE USER USING ONE OF TWO WAYS:
		
		1. IF EXISTS 'LDAP_SERVER' ENTRY IN CONF FILE, USE THIS TO AUTHENTICATE

			THEN GENERATE A SESSION_ID IF SUCCESSFULLY AUTHENTICATED. STORE
			
			SESSION_ID IN sessions TABLE AND PRINT IT TO STDOUT
		
		2. OTHERWISE, CHECK INPUT PASSWORD AGAINST STORED PASSWORD IN users TABLE
		
			THEN GENERATE A SESSION_ID IF SUCCESSFULLY AUTHENTICATED. STORE
			
			SESSION_ID IN sessions TABLE AND PRINT IT TO STDOUT
		
	INPUTS
	
		1. JSON->USERNAME
		
		2. JSON->PASSWORD
	
	OUTPUTS
	
		1. SESSION ID

=cut
	my $self		=	shift;

	my $username	=	$self->username();
	my $password 	=	$self->password();
	$self->logDebug("username", $username);
	$self->logNote("password not defined or empty") if not defined $password or not $password;
    
    #### CHECK USERNAME AND PASSWORD DEFINED AND NOT EMPTY
    if ( not defined $username )    {   return; }
    if ( not defined $password )    {   return; }
    if ( not $username )    {   return; }
    if ( not $password )    {   return; }

	#### CHECK IF GUEST USER AND IF SO WHETHER ACCESS IS ALLOWED
	$self->guestLogin();
	
	#### ADMIN VALIDATES AGAINST DATABASE, OTHER USERS VALIDATE
	#### AGAINST LDAP OR DATABASE IF LDAP NOT AVAILABLE
	my $is_admin = $self->isAdminUser($username);
	$self->logDebug("is_admin", $is_admin);
	
	#### VALIDATE USING LDAP IF EXISTS 'LDAP_SERVER' ENTRY IN CONF FILE
	my $conf 		=	$self->conf();
	my $ldap_server = $conf->getKey('agua', "LDAP_SERVER");
	my $match = 0;
	$self->logDebug("LDAP SERVER", $ldap_server);
	if ( not $is_admin and defined $ldap_server )
	{
		$self->logDebug("Doing LDAP authentication...");
		$match = $self->ldap();
		$self->logDebug("LDAP result", $match);
	}

	#### OTHERWISE, GET STORED PASSWORD FROM users TABLE
	else
	{
		my $query = qq{SELECT password FROM users
	WHERE username='$username'};
		$self->logDebug("$query");
		my $stored_password = $self->db()->query($query);	
	
		#### CHECK FOR INPUT PASSWORD MATCHES STORED PASSWORD
		$self->logDebug("Stored_password: ***$stored_password***");
		$self->logDebug("Passed password: ***$password***");
	
		$match = $password =~ /^$stored_password$/; 
		$self->logDebug("Match", $match);
	}
	$self->logDebug("match", $match);

	#### GENERATE SESSION ID
	my $session_id;
	
	#### IF PASSWORD MATCHES, STORE SESSION ID AND RETURN '1'
	my $exists;
	
	####
	my $now = $self->db()->now();
	$self->logDebug("now", $now);
	
	if ( $match )
	{
		while ( not defined $session_id )
		{
			#### CREATE A RANDOM SESSION ID TO BE STORED IN dojo.cookie
			#### AND PASSED WITH EVERY REQUEST
			$session_id = time() . "." . $$ . "." . int(rand(999));

			#### CHECK IF THIS SESSION ID ALREADY EXISTS
			my $exists_query = qq{
			SELECT username FROM sessions
			WHERE username = '$username'
			AND sessionid = '$session_id'};
			$self->logDebug("Exists query", $exists_query);
			$exists = $self->db()->query($exists_query);
			if ( defined $exists )
			{
				$self->logDebug("Exists", $exists);
				$session_id = undef;
			}
			else
			{
				$self->logDebug("Session ID for username $username does not exist in sessions table");
			}
		}        
        
		#### IF IT DOES EXIST, UPDATE THE TIME
		if ( defined $exists )
		{
			my $update_query = qq{UPDATE sessions
			SET datetime = $now
			WHERE username = '$username'
			AND sessionid = '$session_id'};
			$self->logDebug("Update query", $update_query);
			my $update_success = $self->db()->query($update_query);
			$self->logDebug("Update success", $update_success);
		}
		
		#### IF IT DOESN'T EXIST, INSERT IT INTO THE TABLE
		else
		{
			my $query = qq{
INSERT INTO sessions
(username, sessionid, datetime)
VALUES
('$username', '$session_id', $now )};
			$self->logDebug("$query");
			my $success = $self->db()->do($query);
			$self->logDebug("$success");
			if ( $success )
			{
				$self->logDebug("Session ID has been stored.");
			}
		}		
	}
	
	#### LATER:: CLEAN OUT OLD SESSIONS
	# DELETE FROM sessions WHERE datetime < ADDDATE(NOW(), INTERVAL -48 HOUR)
	# DELETE FROM sessions WHERE datetime < DATE_SUB(NOW(), INTERVAL 1 DAY)
	my $timeout = $self->conf()->getKey('database', 'SESSIONTIMEOUT');
	$timeout = "24" if not defined $timeout;
	my $delete_query = qq{
#DELETE FROM sessions
#WHERE datetime < DATETIME ('NOW()', 'LOCALTIME', '-$timeout HOURS') };
	my $dbtype = $self->conf()->getKey('database', 'DBTYPE');
	$delete_query = qq{
DELETE FROM sessions
WHERE timediff(sysdate(), datetime) > $timeout * 3600} if defined $dbtype and $dbtype eq "MySQL";
	$self->logDebug("delete_query", $delete_query);
	$self->db()->do($delete_query);
	
	if ( not defined $session_id and defined $ldap_server)
	{
		$self->logError("LDAP authentication failed for user: $username");
		return;
	}
	elsif ( not defined $session_id )
	{
		$self->logError("Authentication failed for user: $username");
		return;
	}
	
	print "{ sessionId : '$session_id' }";
}

sub guestLogin {
	my $self		=	shift;
	
	my $username	=	$self->username();
	$username		=	$self->requestor() if $self->requestor();
	
	my $guestuser 	= $self->conf()->getKey("agua", "GUESTUSER");
	$self->logDebug("guestuser", $guestuser);	
	my $guestaccess = $self->conf()->getKey("agua", "GUESTACCESS");
	$self->logDebug("guestaccess", $guestaccess);
	
	#### SKIP IF NOT GUEST USER
	return if not $username eq $guestuser;
	$self->logDebug("username is guestuser: $guestuser");
	
	#### QUIT IF GUEST ACCESS NOT ALLOWED
	$self->logError("guestuser access denied") and exit if not $guestaccess;
}

sub newuser {
=head2

    SUBROUTINE      newuser
    
    PURPOSE
    
        CHECK 'admin' NAME AND PASSWORD AGAINST INPUT VALUES. IF
        
        VALIDATED, CREATE A NEW USER IN THE users TABLE
        
=cut
	my $self		=	shift;
	$self->logDebug("Agua::Common::Login::newuser()");

    
    my $json;
    if ( not $self->validate() )
    {
        $json = "{ {validated: false} }";
        print $json;
        return;
    }
	
	my $username	=	$self->cgiParam('username');
	my $password 	=	$self->cgiParam('password');
	my $newuser 	=	$self->cgiParam('newuser');
	my $newuserpassword 	=	$self->cgiParam('newuserpassword');

	$self->logDebug("DB User", $username);
	$self->logDebug("DB Password", $password);
	$self->logDebug("New user", $newuser);
	$self->logDebug("New user password", $newuserpassword);

    ##### CREATE TABLE users IF NOT EXISTS
    #$self->createTable('users');

	#### CHECK IF USER ALREADY EXISTS
	my $query = qq{SELECT username FROM users WHERE username='$newuser' LIMIT 1};
	my $exists_already = $self->db()->query($query);
	if ( $exists_already )
	{
		$self->logError("User exists already: $username");
		return;
	}
	
    $query = qq{INSERT INTO users VALUES ('$newuser', '$newuserpassword', NOW())};
    my $success = $self->db()->do($query);
    $self->logDebug("Insert success", $success);

    if ( $success )
    {
        $self->logStatus("New user created");
    }
    else
    {
        $self->logStatus("Failed to create new user");
    }
}












1;