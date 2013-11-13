package Agua::Common::Ami;
use Moose::Role;

=head2

	PACKAGE		Agua::Common::Ami
	
	PURPOSE
	
		CLUSTER METHODS FOR Agua::Common
		



	SUBROUTINE		addAmi
	
	PURPOSE

		ADD A CLUSTER TO THE cluster TABLE
        
		IF THE USER HAS NO AWS CREDENTIALS INFORMATION,
		
		USE THE 'admin' USER'S AWS CREDENTIALS AND STORE
		
		THE CONFIGFILE IN THE ADMIN USER'S .starcluster
		
		DIRECTORY

=cut
use Data::Dumper;
use File::Path;

sub addAmi {
	my $self		=	shift;
 	$self->logDebug("Common::addAmi()");

        my $json 		=	$self->json();

	$self->_removeAmi();	
	my $success = $self->_addAmi();
	$self->logStatus("Could not add cluster $json->{cluster}") and return if not $success;
 	$self->logStatus("Added AMI $json->{aminame}: ($json->{amiid})") if $success;
	return;
}

sub _addAmi {
	my $self		=	shift;
 	$self->logDebug("Common::_addAmi()");

        my $json 			=	$self->json();
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "ami";
	my $required_fields = ["username", "amiid"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("not defined: @$not_defined") and return if @$not_defined;

	#### DO ADD
	return $self->_addToTable($table, $json, $required_fields);	
}

sub removeAmi  {
#### REMOVE A CLUSTER FROM THE cluster TABLE
	my $self		=	shift;
 	$self->logDebug("Common::removeAmi()");
    
    my $json 			=	$self->json();
	my $success = $self->_removeAmi();
	return if not defined $success;
 	$self->logError("Could not remove cluster $json->{cluster}") and return if not defined $success;
 	$self->logStatus("Removed AMI $json->{aminame}: ($json->{amiid})") if $success;
	return;	
}

sub _removeAmi {
	my $self		=	shift;
 	$self->logDebug("Common::_removeAmi()");
    
        my $json 			=	$self->json();

	#### SET CLUSTER, TABLE AND REQUIRED FIELDS	
	my $table = "ami";
	my $required_fields = ["username", "amiid"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	return $self->_removeFromTable($table, $json, $required_fields);
}

sub getAmis {
#### RETURN AN ARRAY OF cluster HASHES
	my $self		=	shift;
	$self->logDebug("");

    	my $json			=	$self->json();

	my $username	=	$self->username();

	#### GET ALL SOURCES
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	my $aguauser = $self->conf()->getKey("agua", "AGUAUSER");
	my $query = qq{SELECT * FROM ami
WHERE username='$adminuser'
OR username='$aguauser'
OR username='$username'};
	$self->logDebug("$query");	;
	my $clusters = $self->db()->queryhasharray($query);

	#### SET TO EMPTY ARRAY IF NO RESULTS
	$clusters = [] if not defined $clusters;

	return $clusters;
}

sub getAmi {
	my $self		=	shift;
	my $username	=	shift;
	my $cluster		=	shift;
	$self->logDebug("Common::getAmi()");

	#### GET ALL SOURCES
	my $query = qq{SELECT * FROM cluster
WHERE username='$username'
AND cluster='$cluster'};
	$self->logDebug("$query");	;
	
	return $self->db()->queryhash($query);
}

1;