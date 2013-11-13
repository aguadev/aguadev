package Agua::Common::Aws;
use Moose::Role;
#use Moose::Util::TypeConstraints;
use Data::Dumper;

=head2

	PACKAGE		Agua::Common::Aws
	
	PURPOSE
	
		AMAZON WEB SERVICES (AWS) METHODS FOR Agua::Common
		
=cut

#### AWS
sub getAws {
#### RETURN aws TABLE ENTRIES
	my $self		=	shift;

	my $username	=	$self->username();
	$self->logDebug("username", $username);

	#### GET AWS INFO FOR USER
	my $aws = $self->_getAws($username) || {};

	#### OMIT KEY INFO
	$aws = $self->omitAwsInfo($aws);
	
	return $aws;
}

sub _getAws {
	my $self		=	shift;
	my $username	=	shift;

	my $adminkey = $self->getAdminKey($username);
 	$self->logDebug("adminkey", $adminkey);

	my $aws;
	if ( $adminkey ) {
		my $adminuser = $self->conf()->getKey("agua", 'ADMINUSER');	
		my $query = qq{SELECT *
FROM aws
WHERE username='$adminuser'};
		$self->logDebug("$query");
		$aws = $self->db()->queryhash($query);
	}
	
	#### USE ADMIN KEYS IF USER HAS NO AWS CREDENTIALS
	if ( not defined $aws ) {
		my $query = qq{SELECT *
	FROM aws
	WHERE username='$username'};
		$self->logDebug("$query");
		$aws = $self->db()->queryhash($query);
	}
	#$self->logDebug("aws", $aws);
	
	return $aws;	
}

sub omitAwsInfo {
	my $self		=	shift;
	my $aws			=	shift;
	
	$aws->{ec2publiccert} = '' if not defined $aws->{ec2publiccert};
	$aws->{ec2privatekey} = '' if not defined $aws->{ec2privatekey};
	$aws->{awsaccesskeyid} = '' if not defined $aws->{awsaccesskeyid};
	$aws->{awssecretaccesskey} = '' if not defined $aws->{awssecretaccesskey};
	$aws->{ec2publiccert} = substr($aws->{ec2publiccert}, 0, 40) . " (OMITTED)" if $aws->{ec2publiccert};
	$aws->{ec2privatekey} = substr($aws->{ec2privatekey}, 0, 40) . " (OMITTED)" if $aws->{ec2privatekey};
	$aws->{awsaccesskeyid} = substr($aws->{awsaccesskeyid}, 0, 5) . " (OMITTED)" if $aws->{awsaccesskeyid};
	$aws->{awssecretaccesskey} = substr($aws->{awssecretaccesskey}, 0, 5) . " (OMITTED)" if $aws->{awssecretaccesskey};

	return $aws;
}

sub _addAws {
#### ADD aws TABLE ENTRY
	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "aws";
	my $required_fields = ["username", "amazonuserid"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
	 	
	#### DO THE ADD
	return $self->_addToTable($table, $data, $required_fields);	
}

sub removeAws {
#### REMOVE aws TABLE ENTRY AND PRINT RESULT
	my $self		=	shift;
	my $aws			=	shift;
    
	#### DO THE REMOVE
	my $success = $self->_removeAws($aws);
	return if not defined $success;

 	$self->logError("{ error: 'Agua::Common::Aws::removeAws    Could not remove user $aws->{username} from user table") and return if not $success;
 	$self->logDebug("{ status: 'Agua::Common::Aws::removeAws    Removed user $aws->{username} from user table");
	return;
}

sub _removeAws {
#### REMOVE aws TABLE ENTRY
	my $self		=	shift;
	my $aws			=	shift;
	
 	$self->logDebug("aws", $aws);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "aws";
	my $required_fields = ["username"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($aws, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### DO THE REMOVE
	return $self->_removeFromTable($table, $aws, $required_fields);
}


#### EC2 KEYS
sub printEc2KeyFiles {
=head2

	SUBROUTINE		printKeyFiles
	
	PURPOSE
	
		1. PRINT EC2 PRIVATE KEY AND PUBLIC CERTIFICATE TO FILE

		2. COPY EC2 PRIVATE KEY TO SSH PRIVATE KEY id_rsa

		3. GENERATE RSA-FORMAT SSH PUBLIC CERT id_rsa.pub
		
=cut
	my $self		=	shift;
	my $username	=	shift;
	my $privatekey	=	shift;
	my $publiccert	=	shift;
	$self->logNote("username", $username);
	$self->logNote("privatekey", $privatekey);
	$self->logNote("publiccert", $publiccert);
	
	#### FORMAT KEYS
	my $private		=	$self->formatPrivateKey($privatekey);
	my $public 		=	$self->formatPublicCert($publiccert);
	$self->logNote("public", $public);
	$self->logNote("private", $private);
	
	my $privatefile 	=	$self->getEc2PrivateFile($username);
	$self->logNote("privatefile", $privatefile);
	$self->printToFile($privatefile, $private);
	`chmod 600 $privatefile`;

	my $publicfile 	=	$self->getEc2PublicFile($username);
	$self->logDebug("publicfile", $publicfile);
	$self->printToFile($publicfile, $public);
}

sub formatPrivateKey {
#### PRIVATE KEY HAS 76-LETTER LINES
	my $self		=	shift;
	my $privatekey	=	shift;
	$self->logNote("privatekey", $privatekey);
	
	my ($string) = $privatekey =~ /^\s*\-{1,5}BEGIN.+?KEY\-{1,5}\s*(.+?)\s*\-{1,5}END.+?KEY\-{1,5}$/ms;
	$string =~ s/\s+//g;
	my $private = $self->formatLines($string, 76) || '';
	$private = "-----BEGIN PRIVATE KEY-----\n"
				. $private
				. "-----END PRIVATE KEY-----";
	$self->logNote("private", $private);
	
	return $private;
}

sub formatPublicCert {
#### PUBLIC CERT HAS 64-LETTER LINES
	my $self		=	shift;
	my $string		=	shift;
	
	$string =~ s/^\s*\-{1,5}BEGIN\s*CERTIFICATE\-{1,5}\s*//;
	$string =~ s/\s*\-{1,5}END\s*CERTIFICATE\-{1,5}$//;
	$string =~ s/\s+//g;

	my $public = $self->formatLines($string, 64) || '';
	$public = "-----BEGIN CERTIFICATE-----\n"
				. $public
				. "-----END CERTIFICATE-----";
	$self->logNote("public", $public);
	
	return $public;
}

sub formatLines {
	my $self	=	shift;
	my $string	=	shift;
	my $length	=	shift;
	my $lines = '';
	my $offset = 0;
	while ( $offset < length($string) )
	{
		$lines .= substr($string, $offset, $length);
		$lines .= "\n";
		$offset += $length;
	}
	return $lines;	
}
sub getEc2PublicFile {
	my $self		=	shift;
	my $username	=	shift;

	#### FOR LAZY BUILDER
	$username = $self->username() if not defined $username;

	my $keydir = $self->getEc2KeyDir($username);
	my $publicfile = "$keydir/public.pem";
	#$self->logDebug("publicfile", $publicfile);
	
	return $publicfile;
}

sub getEc2PrivateFile {
	my $self		=	shift;
	my $username	=	shift;

	#### FOR LAZY BUILDER
	$username = $self->username() if not defined $username;

	my $keydir = $self->getEc2KeyDir($username);
	my $privatefile = "$keydir/private.pem";
	#$self->logDebug("privatefile", $privatefile);
	
	return $privatefile;
}

sub getEc2KeyDir {
	my $self		=	shift;
	my $username	=	shift;
	#$self->logDebug("username", $username);
	print "Agua::Init::getEc2KeyDir    username not defined. Returning\n" and return if not defined $username;

	my $installdir = $self->conf()->getKey("agua", 'INSTALLDIR');
	
	return "$installdir/conf/.ec2/$username";
}

#### META-DATA
sub getAvailabilityZone {
	my $self		=	shift;
	$self->logDebug("");
	my $availzone = `curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`;	
	$self->logDebug("availzone", $availzone);
	
	return $availzone;
}

#### UTILS
sub getRegionZones {
	return {
    "ap-northeast-1"	=>	[
        "ap-northeast-1a",
        "ap-northeast-1b",
    ],
    "ap-southeast-1"	=>	[
        "ap-southeast-1a",
        "ap-southeast-1b",
    ],
    "eu-west-1"	    =>	[
        "eu-west-1a",
        "eu-west-1b",
        "eu-west-1c",
    ],
    "us-east-1"	    =>	[
        "us-east-1a",
        "us-east-1b",
        "us-east-1c",
        "us-east-1d",
    ],
    "us-west-1"	    =>	[
        "us-west-1a",
        "us-west-1b",
        "us-west-1c",
    ]
}

}
sub mountUserVolume {
=head2

	SUBROUTINE		mountVolume
	
	PURPOSE
	
		MOUNT AN EBS VOLUME FOR A GIVEN USER TO A WORKFLOW DIRECTORY
		
		IN THE USER'S HOME DIRECTORY

	INPUT
	
		1. THE USER'S AWS ACCESS KEY ID AND SECRET ACCESS KEY
		
		2. VOLUME (OR SNAPSHOT) ID, E.G., vol-e0e0e0e0, snap-e0e0e0e0
	
		3. DESTINATION MOUNT POINT, I.E., USER'S PROJECT AND WORKFLOW
		
=cut

	my $self		=	shift;

	my $json		=	$self->get_json();
	$self->logDebug("json", $json);
	
	my $username	=	$json->{username};
	my $mountpoint	=	$json->{mountpoint};
	my $volume		=	$json->{volume};

	#### CHOOSE AN UNUSED DEVICE
	my $device		=	$json->{device};

	my $aws = $self->getAws($username);
	$self->logDebug("aws", $aws);
	
	my $accesskeyid = $aws->{accesskeyid};
	my $awssecretaccesskey = $aws->{awssecretaccesskey};

	

}

sub addVolume {
#### ADD AN ENTRY TO THE volume TABLE
	my $self		=	shift;
	my $json		=	$self->json();
	$self->logDebug("json", $json);	
	
	my $username	=	$json->{username};
	my $mountpoint	=	$json->{mountpoint};
	my $device		=	$json->{device};
	my $volume		=	$json->{volume};
	my $snapshot	=	$json->{snapshot};

	#### GET EXISTING KEYS IF AVAILABLE
	my $aws = $self->getAws($self->username);	
	$self->logDebug("aws", $aws);
	
	my $accesskeyid = $aws->{awsaccesskeyid};
	my $awssecretaccesskey = $aws->{awssecretaccesskey};
	$self->logDebug("accesskeyid", $accesskeyid);
	$self->logDebug("secret", $accesskeyid);

	my $ec2 = Net::Amazon::EC2->new(
		AWSAccessKeyId	=>	$self->accesskeyid(), 
		SecretAccessKey	=>	$self->awssecretaccesskey(),
		debug => 1
	);

	


}




1;