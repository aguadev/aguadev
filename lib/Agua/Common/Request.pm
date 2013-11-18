package Agua::Common::Request;
use Moose::Role;
use Moose::Util::TypeConstraints;

sub getQueries {
	my $self		=	shift;

    #### GET PROJECTS
    my $username = $self->username();
    my $queries = $self->_getQueries($username);
    
	return $queries;
}

sub _getQueries {
#### GET PROJECTS FOR THIS USER
    my $self        =   shift;
    my $username    =   shift;    
    
    $self->logDebug("username", $username);
	my $query = qq{SELECT * FROM query
WHERE username='$username'
ORDER BY query};
	$self->logDebug("query", $query);
    
	return $self->db()->queryhasharray($query);
}

sub addQuery {
=head2

	SUBROUTINE		addQuery
	
	PURPOSE

		ADD A PROJECT TO THE query TABLE
        
=cut

	my $self		=	shift;

	#### GET DATA
    my $data 		=	$self->data();
 	$self->logDebug("data", $data);
	
	#### REMOVE IF EXISTS ALREADY
	$self->_removeQuery($data);

	my ($success, $error) = $self->_addQuery($data);	

	$self->logStatus("Added query $$data[0]->{query}") if $success;
	$self->logError("Failed to add query. Error: $error") if not $success;
}

sub _addQuery {
=head2

	SUBROUTINE		_addQuery
	
	PURPOSE

		ADD A PROJECT TO THE query TABLE
        
=cut
	my $self		=	shift;
    my $data 		=	shift;

 	$self->logDebug("data", $data);
	return (0, "Error: data is empty") if not defined $data or not @$data;

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "query";
	my $required_fields = ["username", "query"];

	foreach my $datum ( @$data ) {
		#### CHECK REQUIRED FIELDS ARE DEFINED
		my $not_defined = $self->db()->notDefined($datum, $required_fields);
		return (0, "undefined values: @$not_defined") if @$not_defined;
	
		#### DO ADD
		my $success = $self->_addToTable($table, $datum, $required_fields);
		$self->logDebug("success", $success);
		return (0, "Could not add query $datum->{query}") if not defined $success or $success == 0;
	}
	
	return 1;
}
sub removeQuery {
=head2

	SUBROUTINE		removeQuery
	
	PURPOSE

		REMOVE A QUERY FROM THE query TABLE, REPORT ERROR IF FAILS
      
=cut

	my $self		=	shift;

	my $data	=	$self->data();
	
	#### REMOVE FROM query TABLE
    my ($success, $error) = $self->_removeQuery($data);

    $self->logError("Failed to remove query. Error: $error") and exit if not $success; 	
	$self->logStatus("Removed query $data->{query}");	
}

sub _removeQuery {
=head2

	SUBROUTINE		_removeQuery
	
	PURPOSE

		REMOVE A QUERY FROM THE query TABLE
      
=cut

	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ["username", "query"];
	my $not_defined = $self->db()->notDefined($data, $required_fields);

    return (0, "Could not remove query $data->{query} - undefined values: @$not_defined") if @$not_defined;

	#### REMOVE FROM query
	my $table = "query";

	my $success	= $self->_removeFromTable($table, $data, $required_fields);

	return (0, "Could not remove query $data->{query} - query failed") if not defined $success or $success == 0;
	return 1;
}

sub getDownloads {
=head2

    SUBROUTINE:     getDownloads
    
    PURPOSE:

		RETURN AN ARRAY OF download HASHES

=cut

	my $self		=	shift;

    #### GET PROJECTS
    my $username = $self->username();
    my $queries = $self->_getDownloads($username);
    
	return $queries;
}

sub _getDownloads {
#### GET PROJECTS FOR THIS USER
    my $self        =   shift;
    my $username    =   shift;    
    
    $self->logDebug("username", $username);
	my $query = qq{SELECT * FROM download
WHERE username='$username'
ORDER BY download, source, filename};
	$self->logDebug("query", $query);
    
	return $self->db()->queryhasharray($query);
}

sub addDownload {
=head2

	SUBROUTINE		addDownload
	
	PURPOSE

		ADD A DOWNLOAD TO THE download TABLE
        
=cut

	my $self		=	shift;

	my $data 		=	$self->json();
 	$self->logDebug("data", $data);

	#### REMOVE IF EXISTS ALREADY
	$self->_removeDownload($data);

	my ($success, $error)	= $self->_addDownload($data);	

	$self->logStatus("Added download filename: $data->{filename}") if $success;
	$self->logStatus("Failed to add download filename: $data->{filename}. Error: $error") if not $success;
}

sub _addDownload {
=head2

	SUBROUTINE		_addDownload
	
	PURPOSE

		ADD A PROJECT TO THE query TABLE
        
=cut
	my $self		=	shift;
    my $data 		=	shift;

 	$self->logDebug("data", $data);
	return (0, "Error: data is empty") if not defined $data or not %$data;

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "download";
	my $required_fields = ["username", "source", "filename"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
	return (0, "Could not add query $data->{filename}. undefined values: @$not_defined") if @$not_defined;

	#### DO ADD
	my $success = $self->_addToTable($table, $data, $required_fields);
	$self->logDebug("success", $success);
	return (0, "Could not add query $data->{filename}") if not defined $success or $success == 0;
	
	return 1;
}
sub removeDownload {
=head2

	SUBROUTINE		removeDownload
	
	PURPOSE

		REMOVE A PROJECT FROM THE download, workflow, groupmember, stage AND

		stageparameter TABLES, AND REMOVE THE PROJECT FOLDER AND DATA FILES
      
=cut

	my $self		=	shift;

	my $data	=	$self->data();

	#### REMOVE FROM query TABLE
    my ($success, $error) = $self->_removeDownload($data);

    $self->logError("Failed to remove query. Error: $error") and exit if not $success; 	
	$self->logStatus("Removed query $data->{query}");	
}	#### removeDownload

sub _removeDownload {
=head2

	SUBROUTINE		_removeDownload
	
	PURPOSE

		REMOVE A PROJECT FROM THE download, workflow, groupmember, stage AND

		stageparameter TABLES, AND REMOVE THE PROJECT FOLDER AND DATA FILES
      
=cut

	my $self		=	shift;
    my $data 		=	shift;
 	$self->logDebug("data", $data);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ["username", "source", "filename"];
	my $not_defined = $self->db()->notDefined($data, $required_fields);

    return (0, "Could not remove download download - undefined values: @$not_defined") if @$not_defined;

	#### REMOVE FROM download
	my $table = "download";

	my $success	= $self->_removeFromTable($table, $data, $required_fields);

	return (0, "Could not remove download $data->{download} - query failed") if not defined $success or $success == 0;
	return 1;
}






1;
