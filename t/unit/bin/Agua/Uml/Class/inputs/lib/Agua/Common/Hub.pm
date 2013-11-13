package Agua::Common::Hub;
use Moose::Role;
#use Moose::Util::TypeConstraints;
use Data::Dumper;

=head2

	PACKAGE		Agua::Common::Hub
	
	PURPOSE
	
		HUB ACCESS MANAGEMENT METHODS FOR Agua::Common
	
=cut

#### HUB
sub getHub {
	my $self		=	shift;

	my $username	=	$self->username();
	$self->logError("username not defined") and exit if not defined $username;
	
	return $self->_getHub($username);
}

sub _getHub {
	my $self		=	shift;
	my $username	=	shift;
	
	my $query = qq{SELECT * FROM hub
WHERE username='$username'};
	$self->logDebug("query", $query);
	my $hub = $self->db()->queryhash($query) || {};
	
	return $hub;
}

sub addHub {
 	my $self		=	shift;

    my $json 		=	$self->json();
	$self->logDebug("json", $json);
    
	#### CHECK IF THE USER ALREADY HAS STORED AWS INFO,
	#### IN WHICH CASE QUIT
	my $table 		= 	"hub";
	my $username 	= 	$json->{username};
	my $success;
	if ( $self->db()->inTable($table, $json, ["username"]) ) {
		$success	=	$self->_updateHub($json);
	}
	else {
		$success 	=	$self->_addHub($json);
	}

	$self->logDebug("{ error: 'Failed to add repo login: $json->{login}") and return if not defined $success and not $success;	

 	$self->logStatus("Added repo login $json->{login}");
}

sub _addHub {
	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "hub";
	my $required_fields = ["username"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
	
	#### DO THE ADD
	return $self->_addToTable($table, $data, $required_fields);	
}

sub _updateHub {
 	my $self		=	shift;
    my $json 		=	shift;

	my $table = "hub";
	my $username = $json->{username};
	my $login = $json->{login};
	my $hubtype = $json->{hubtype};
	my $query = qq{UPDATE $table
	SET login='$login',
	hubtype = '$hubtype'
	WHERE username='$username'};
	$self->logDebug("$query");
	
	return $self->db()->do($query);
}

sub _removeHub {
#### ADD aws TABLE ENTRY
	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "hub";
	my $required_fields = ["username"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
	 	
	#### DO THE ADD
	return $self->_removeFromTable($table, $data, $required_fields);	
}

#### HUB TOKEN
sub addHubToken {
 	my $self		=	shift;

    my $json 		=	$self->json();
	$self->logDebug("json", $json);

	my $username 	= $json->{username};	
	my $login 		= $json->{login};
	my $password 	= $json->{password};
	my $hubtype 	= $json->{hubtype};
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $fields = ["username", "login", "password", "hubtype"];
	my $not_defined = $self->db()->notDefined($json, $fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### SET ops HUB TYPE	
	$self->head()->ops()->setHubType($hubtype) if not $self->head()->ops()->hubtype() eq $hubtype;

	#### ADD hub IF NOT EXISTS
	my $hub = $self->getHub($username);
	my $tokenid = $hub->{tokenid};
	$self->logDebug("hub", $hub);
	if ( not defined $hub ) {
		$self->logDebug("Doing _addHub(json)");
		$self->_addHub($json)
	}
	#### OTHERWISE, REMOVE 'agua' TOKEN IF ALREADY EXISTS
	else {
		$self->logDebug("Doing _removeOAuthToken(...)");
		$self->head()->ops()->removeOAuthToken($login, $password, $tokenid) if defined $tokenid;
	}

	#### ADD TOKEN 'agua'
	$self->logDebug("Doing _addHubToken(");
	my $token;
	($token, $tokenid) = $self->head()->ops()->addOAuthToken($login, $password, $hubtype, $tokenid);
	$json->{token} 		= 	$token;
	$json->{tokenid} 	= 	$tokenid;
	$self->logDebug("json", $json);
	
	#### UPDATE hub TABLE WITH token AND tokeinid
	my $success = $self->_addHubToken($json);
	$self->logError("Failed to update OAuth Token", $success) if not $success;

	my $data;
	$data->{token} = $token;
	$self->logStatus("Created hub token: $token", $data);
}

sub _addHubToken {
 	my $self		=	shift;
	my $hash		=	shift;
	$self->logDebug("hash", $hash);
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_keys = ["username", "login", "hubtype", "token", "tokenid"];
	my $not_defined = $self->db()->notDefined($hash, $required_keys);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### CHECK IF ENTRY IN TABLE
	my $table = "hub";
	my $keys = ["username", "login"];
	my $exists = $self->db()->inTable($table, $hash, $keys);
	$self->logDebug("exists", $exists);
	
	#### IF ENTRY EXISTS, UPDATE ENTRY
	if ( $exists ) {
		$self->logDebug("updating entry");
		my $result = $self->db()->_updateTable($table, $hash, $keys, $hash, ["token", "tokenid"]);
		$self->logDebug("result", $result);
		return $result;
	}
	#### OTHERWISE, INSERT NEW ENTRY
	else {
		$self->logDebug("inserting new entry");
		my $fields = $self->db()->fields($table);
		my $result = $self->db()->_addToTable($table, $hash, $keys, $fields);
		$self->logDebug("result", $result);
		return $result;
	}
}

sub removeHubToken {
	my $self		=	shift;

    my $json 		=	$self->json();
	$self->logDebug("json", $json);

	my $username 	= $json->{username};	
	my $login 		= $json->{login};
	my $password 	= $json->{password};
	my $hubtype 	= $json->{hubtype};

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $keys = ["username", "login", "hubtype", "token", "tokenid"];
	my $not_defined = $self->db()->notDefined($json, $keys);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### CHECK IF ENTRY IN TABLE
	my $table = "hub";
	return $self->db()->_removeFromTable($table, $json, $keys);
}

sub _removeHubToken {
	my $self		=	shift;
	my $hash		=	shift;
	$self->logDebug("hash", $hash);
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $keys = ["username", "login", "hubtype", "token", "tokenid"];
	my $not_defined = $self->db()->notDefined($hash, $keys);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### CHECK IF ENTRY IN TABLE
	my $table = "hub";
	return $self->db()->_removeFromTable($table, $hash, $keys);
}

#### HUB CERTIFICATE
sub addHubCertificate {
 	my $self		=	shift;

    my $json 		=	$self->json();
	$self->logDebug("json", $json);

	my $username 	= $json->{username};	
	my $login 		= $json->{login};
	my $hubtype 	= $json->{hubtype};

	#### SET KEYFILE
	my $hub = $self->_getHub($username);
	my $keyfile = $self->setHubKeyfile($username, $login, $hubtype);
	$self->logDebug("keyfile", $keyfile);
	$hub->{keyfile} = $keyfile;
	$self->_updateHubKeyfile($hub);
	
	#### CREATE HUB KEYS FROM PRIVATE KEY IN aws TABLE
	my $publiccert = $self->generateHubKeys($username, $login, $hubtype, $keyfile);
	
	#### UPDATE LOCATION OF KEY FILE AND PUBLIC CERT IN hub TABLE
	$self->_updateHubKeys($username, $keyfile, $publiccert);

	my $data;
	$data->{publiccert} = $publiccert;
	$self->logStatus("Created hub certificate", $data);
	
}
sub _updateHubKeyfile {
	my $self		=	shift;
    my $json 		=	shift;

	my $table = "hub";
	my $username = $json->{username};
	my $keyfile = $json->{keyfile};
	my $hubtype = $json->{hubtype};

	my $query = qq{UPDATE $table
	SET keyfile='$keyfile',
	hubtype = '$hubtype'
	WHERE username='$username'};
	$self->logDebug("$query");
	
	return $self->db()->do($query);
}


sub generateHubKeys {
	my $self		=	shift;
	my $username	=	shift;
	my $login		=	shift;
	my $hubtype		=	shift;
	my $keyfile		=	shift;
	
	$self->logDebug("keyfile", $keyfile);
	
	#### PRINT PRIVATE KEY FROM aws TABLE TO HUB KEY FILE
	$keyfile = $self->printHubKeyFile($username, $login, $hubtype) ;

	#### GENERATE RSA-FORMAT REPO PUBLIC CERT FROM HUB PRIVATE KEY
	my $certfile 	= 	"$keyfile.pub";
	$self->logDebug("certfile", $certfile);
	my $publiccert = $self->createHubCertificate($keyfile, $certfile);
	$self->logError("Can't create public certificate") and exit if not defined $publiccert;
	
	return $publiccert;
}

sub printHubKeyFile {
	my $self		=	shift;
	my $username	=	shift;
	my $login		=	shift;
	my $hubtype		=	shift;

	my $aws = $self->_getAws($username);
	$self->logError("aws not defined") and exit if not defined $aws;
	my $privatekey = 	$aws->{ec2privatekey};
	$self->logError("AWS privatekey not defined") and exit if not defined $privatekey;

	#### CREATE REPO PRIVATE SSH KEY DIR
	my $keydir = $self->head()->ops()->getHubKeyDir($login, $hubtype);
	`mkdir -p $keydir` if not -d $keydir;
	$self->logCritical("Can't create keydir: $keydir") and exit if not -d $keydir;

	#### SET FILENAMES
	my $keyfile 	=	"$keydir/id_rsa";
	$self->logDebug("keyfile: $keyfile ");
	
	#### REPO PRIVATE SSH KEY FILE
	$self->printToFile($keyfile, $privatekey);
	`chmod 600 $keyfile`;
	
	return $keyfile;
}

sub setHubKeyfile {
	my $self		=	shift;
	my $username	=	shift;
	my $login		=	shift;
	my $hubtype		=	shift;

	#### CREATE REPO PRIVATE SSH KEY DIR
	my $keydir = $self->head()->ops()->getHubKeyDir($login, $hubtype);
	`mkdir -p $keydir` if not -d $keydir;
	$self->logCritical("Can't create keydir: $keydir") and exit if not -d $keydir;

	#### SET FILENAMES
	my $keyfile 	=	"$keydir/id_rsa";
	$self->logDebug("keyfile: $keyfile ");

	return $keyfile;
}
sub createHubCertificate {
	my $self		=	shift;
	my $privatefile	=	shift;
	my $publicfile	=	shift;
	$self->logDebug("privatefile: $privatefile ");
	$self->logDebug("publicfile", $publicfile);
	my $remove = "rm -fr $publicfile";
	$self->logDebug("remove", $remove);
	`$remove` if -f $publicfile;
	
	my $command = "ssh-keygen -y -f $privatefile -q -P '' > $publicfile";
	$self->logDebug("command", $command);
	my $output = `$command`;
	$self->logDebug("output", $output);
	return if $output ne '' or -z $publicfile;

	my $publiccert = `cat $publicfile`;
	
	return $publiccert;
}

sub _updateHubKeys {
	my $self		=	shift;
    my $username 	=	shift;
    my $keyfile 	=	shift;
	my $publiccert	=	shift;
	
    $self->logError("username not defined") and return if not defined $username;
    $self->logError("keyfile not defined") and return if not defined $keyfile;

	my $query = qq{UPDATE hub
SET keyfile='$keyfile',
publiccert='$publiccert'
WHERE username='$username'};
	$self->logDebug("query", $query);

	return $self->db()->do($query);
}



1;