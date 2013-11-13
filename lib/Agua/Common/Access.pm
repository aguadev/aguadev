package Agua::Common::Access;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Access
	
	PURPOSE
	
		ACCESS METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

##############################################################################
#				ACCESS METHODS
##############################################################################

=head2

    SUBROUTINE:     getAccess
    
    PURPOSE:

        RETURN A JSON STORE WITH THE FOLLOWING FORMAT    
    
			{
				//identifier: 'name',
				label: 'name',
				items: [
					{
						name: 'Project1',
						type: 'project',
						fullname: 'Next Generation Analysis Tools',
						groupname: 'bioinfo',
						groupdesc: 'Bioinformatics Team'
					},
					{   name: 'skhuri',
						type: 'user',
						fullname: 'Sawsan Khuri',
						groupname: 'bioinfo',
						groupdesc: 'Bioinformatics Team'
					},
					...
				]	
			}

=cut

sub getAccess {
	my $self		=	shift;
	$self->logDebug("()");

    	my $cgi 			=	$self->cgi();
	my $json			=	$self->json();

	my $jsonParser = JSON->new();

	#### VALIDATE    
    my $username = $json->{'username'};
    my $sessionid = $json->{'sessionid'};
	$self->logDebug("username", $username);
	$self->logDebug("sessionid", $sessionid);
    if ( not $self->validate($username, $sessionid) )
    {
        $self->logError("User $username not validated");
        return;
    }

    my $query = qq{SELECT * FROM access WHERE owner='$username' ORDER BY groupname};
    $self->logDebug("$query");
    my $access = $self->db()->queryhasharray($query);
    $access = [] if not defined $access;

    return $access;
}





=head2

	SUBROUTINE		addAccess

	PURPOSE
	
		UPDATE THE 'ACCESS' TABLE WITH THE ENTRY SPECIFIED IN THE
		
		JSON OBJECT SENT FROM THE CLIENT:
		
			1. UPDATE ALL ROWS WHERE ALL ENTRIES ARE DEFINED IN THE JSON
				
			2. IGNORE ROWS WHERE ANY ENTRIES ARE UNDEFINED

=cut

sub _addAccess {
	my $self		=	shift;
	my $access 		=	shift;
	$self->logDebug("(access)");
	$self->logDebug("access", $access);

	#### SET UP ADD/REMOVE VARIABLES
	my $table = "access";
	my $required_fields = [ "owner", "groupname" ];

	#### DO THE DELETE
	my $deleted = $self->_removeFromTable($table, $access, $required_fields);
	$self->logDebug("deleted ", $deleted);
	return if not defined $deleted;
	$self->logError("Could not add group $access->{groupname} to groups table") and return if not $deleted;	

	#### DO THE ADD
	my $added = $self->_addToTable($table, $access, $required_fields);
	return if not defined $added;
	$self->logError("Could not add group $access->{groupname} to $table table") and return if not $added;
	
	return $added;
}

sub _removeAccess {
	my $self		=	shift;
	my $access 		=	shift;
	$self->logDebug("()");

	#### SET UP ADD/REMOVE VARIABLES
	my $table = "access";
	my $required_fields = [ "owner", "groupname" ];

	#### DO THE DELETE
	my $deleted = $self->_removeFromTable($table, $access, $required_fields);
	return $deleted;
}

sub addAccess {
	my $self		=	shift;
    	my $json			=	$self->json();
	
	my $access_entries = $json->{data};
	$self->logDebug("access_entries", $access_entries);

	#### VALIDATE    
    my $username = $json->{'username'};
    my $sessionid = $json->{'sessionid'};
    $self->logError("User $username not validated") and return if not $self->validate();
	
	#### GET FIELDS	
	my $fields = $self->db()->fields("access");
	my $fieldstring = join ",", @$fields;

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "access";
	my $required_fields = ['owner', 'groupname'];
	
	#### CHECK WHICH USERS TO ADD
	foreach my $access_entry ( @$access_entries )
	{
		#### CHECK REQUIRED FIELDS ARE DEFINED
		my $not_defined = $self->db()->notDefined($access_entry, $required_fields);
		$self->logError("undefined values: @$not_defined") and return if @$not_defined;
		
		#### IGNORE THIS PROJECT ENTRY IF A FIELD IS UNDEFINED
		my $defined = 1;
		foreach my $field ( @$fields )
		{
			if ( not defined $access_entry->{$field} )
			{
				$defined = 0;
				last;
			}
		}
		next if not defined $defined;

		my $set = '';
		foreach my $field ( @$fields )
		{
			$set .= "$field = '$access_entry->{$field}',\n";
		}
		$set =~ s/,$//;
		
		my $query = qq{UPDATE access
SET $set WHERE owner = '$username'
AND groupname = '$access_entry->{groupname}'};
		$self->logDebug("$query");
		
		my $success = $self->db()->do($query);
		$self->logDebug("Insert success", $success);
	}

	$self->logStatus("Added access entry");
}




1;