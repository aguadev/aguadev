package Agua::Common::Source;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Source
	
	PURPOSE
	
		SOURCE METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

=head2

    SUBROUTINE:     getSources
    
    PURPOSE:

		RETURN ALL ENTRIES IN THE source TABLE
			
			E.G.:
			[
				{
				  'location' : '/mihg/data/NGS/syoung/base/pipeline/human-genome-fa',
				  'name' : 'Human genome FASTA (36.1)',
				  'type' : 'fasta',
				  'description' : 'A single human genome file with one FASTA record pe
			r chromosome (Build 36.1)'
				},
				{
				  'location' : '/mihg/data/NGS/syoung/base/pipeline/human-chr/fa',
				  'name' : 'Human chromosome FASTA (36.1)',
				  'type' : 'fasta',
				  'description' : 'Human chromosome FASTA files (Build 36.1)'
				},
				{
					...
			]

=cut

sub getSources {
	my $self		=	shift;
	$self->logDebug("");

	#### GET USERNAME AND SESSION ID
    my $username = $self->username();
	$self->logDebug("username", $username);

	return $self->_getSources($username);
}
	
sub _getSources {
	my $self		=	shift;
	my $username	=	shift;

	#### GET ALL SOURCES
	my $query = qq{
SELECT * FROM source
WHERE username='$username'};
	$self->logDebug("$query");	;
	my $sources = $self->db()->queryhasharray($query);
	$sources = [] if not defined $sources;

	$self->logDebug("sources", $sources);

	return $sources;
}

=head2

    SUBROUTINE:     removeSource
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE A SOURCE
		
=cut

sub removeSource {
	my $self		=	shift;
	$self->logDebug("()");

    	my $json			=	$self->json();

    my $username 	= $json->{'username'};
    my $sessionid 	= $json->{'sessionid'};
	$self->logDebug("username", $username);
	$self->logDebug("sessionid", $sessionid);

	#### PRIMARY KEYS FOR source TABLE: name, type, location
	my $data 		= $json->{data};
	my $name 		= $data->{name};
	$self->logError("Name of source not defined") and exit if not defined $name;
	$self->logDebug("name", $name);

	#### DELETE SOURCE
	my $query = qq{DELETE FROM source
WHERE username='$username'
AND name='$name'};
	$self->logDebug("$query");
	my $success = $self->db()->do($query);
	$self->logDebug("Delete success", $success);
	if ( $success )
	{
		my $query = qq{DELETE FROM groupmember
WHERE owner='$username'
AND name = '$name'
AND type = 'source'};
		$success = $self->db()->do($query);
		if ( $success )
		{
			$self->logStatus("Deleted source $name");
		}
		else
		{
			$self->logError("Could not delete source $name from groupmember table");
		}
	}
	else
	{
		$self->logError("Could not delete source $name from source table");
	}
}


=head2

    SUBROUTINE:     addSource
    
    PURPOSE:

        VALIDATE THE admin USER THEN SAVE SOURCE INFORMATION
		
=cut

sub addSource {
	my $self		=	shift;
	$self->logDebug("Admin::addSource()");

    	my $json			=	$self->json();

    my $username = $json->{username};
    my $sessionid = $json->{sessionid};
	$self->logDebug("username", $username);
	$self->logDebug("sessionid", $sessionid);

	#### PARSE JSON INTO OBJECT
	my $jsonParser = JSON->new();

	#### PRIMARY KEYS FOR source TABLE: name, type, location
	my $data 		=	$json->{data};
	$data->{username} = $username;
	my $name 		=	$data->{name};
	$self->logError("Name of source not defined") and exit if not defined $name;
	$self->logDebug("name", $name);

	my $description 	=	$data->{description};
	my $type 			=	$data->{type};
	my $location 		=	$data->{location};
	$self->logError("Location not defined") and exit if not defined $location;

	$self->logDebug("name", $name);
	$self->logDebug("type", $type);
	$self->logDebug("location", $location);
	
	my $fields = $self->db()->fields('source');
	$self->logDebug("fields: @$fields");

	#### CHECK IF THIS ENTRY EXISTS ALREADY
	my $query = qq{SELECT 1 FROM source
WHERE username='$username'
AND name='$name'};
#AND type= '$type'
#AND location = '$location'};
    $self->logDebug("$query");
    my $already_exists = $self->db()->query($query);
	$self->logDebug("already exists", $already_exists);
	
	#### UPDATE THE source TABLE ENTRY IF EXISTS ALREADY
	if ( defined $already_exists )
	{
		#### UPDATE THE source TABLE
		my $set = '';
		foreach my $field ( @$fields )
		{
			$data->{$field} =~ s/'/"/g;
			$set .= "$field = '$data->{$field}',\n";
		}
		$set =~ s/,\s*$//;
		
		my $query = qq{UPDATE source
SET $set
WHERE username='$username'
AND name='$name'};
		$self->logDebug("$query");
		
		my $success = $self->db()->do($query);
		$self->logDebug("update 'source' success", $success);
		
		if ( $success )
		{
			#### UPDATE THE groupmember TABLE
			$query = qq(UPDATE groupmember
SET
description = '$description',
location = '$location'
WHERE owner='$username'
AND name='$name'
AND type = 'source');
			$self->logDebug("$query");
			$success = $self->db()->do($query);
			$self->logDebug("update 'groupmember' success", $success);

			if ( $success == 1 )
			{
				$self->logStatus("Updated source $name");
			}
			else
			{
				$self->logError("Could not update groupmember table with source $name");
			}
			return;
		}
		else
		{
			$self->logError("Could not update source $name");
		}
	}

	#### OTHERWISE, INSERT THE ENTRY
	else
	{
		my $values = '';
		foreach my $field ( @$fields )
		{
			my $value = $data->{$field};
			$value = '' if not defined $value;
			$values .= "'$value',\n";
		}
		$values =~ s/,\s*$//;

		my $query = qq{INSERT INTO source
VALUES ($values) };
		$self->logDebug("$query");
		
		my $success = $self->db()->do($query);
		if ( $success == 1 )
		{
			$self->logStatus("Created source $name");
		}
		else
		{
			$self->logError("Could not create source $name");
		}
		return;
	}
}






1;