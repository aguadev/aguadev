use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Agua::Request with Agua::Common::Exchange {

#### INTERNAL MODULES
use Agua::Common::Util;
use Agua::DBaseFactory;
use Agua::JBrowse;
use Agua::Common::Exchange;

# Booleans
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 4 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Ints
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sourceid'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'token'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'callback'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'data'		=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 		=> (
	isa 	=> 'Conf::Yaml',
	is 		=>	'rw',
	default	=>	sub { Conf::Yaml->new( {} );	}
);

#####/////}}}}}

method notifyStatus ($data) {	
	$self->logDebug("DOING self->openConnection() with data", $data);
	$self->logDebug("self->exchange", $self->exchange());
	
	my $connection = $self->exchange()->openConnection();
	$self->logDebug("connection", $connection);
	sleep(1);
	
	$self->logDebug("DOING self->exchange()->sendData(data)");
	return $self->exchange()->sendData($data);
}
method notify ($status, $error, $data) {
	#### NOTIFY CLIENT OF STATUS
	my $object = {
		sourceid	=> 	$self->sourceid(),
		callback	=> 	$self->callback(),
		token		=>	$self->token(),
		queue		=> 	"routing",
		status		=> 	$status,
		error		=>	$error,
		data		=>	$data
	};
	$self->logDebug("object", $object);
	
	$self->notifyStatus($object);
}
#### QUERY
method getQueries {
    my $username = $self->username();
    my $queries = $self->_getQueries($username);
    
	return $queries;
}
method _getQueries ($username) {
    $self->logDebug("username", $username);
	my $query = qq{SELECT * FROM query
WHERE username='$username'
ORDER BY query};
	$self->logDebug("query", $query);
    
	return $self->db()->queryhasharray($query);
}
method addQuery {
	#### GET DATA
    my $data 		=	$self->data();
 	$self->logDebug("data", $data);
	
	#### REMOVE IF EXISTS ALREADY
	$self->_removeQuery($data);

	my ($success, $error) = $self->_addQuery($data);	
	$self->logDebug("success", $success);
	$self->logDebug("error", $error);
	
	#$self->logError("Failed to add query. Error: $error") and return if not $success;
	#$self->logStatus("Added query $$data[0]->{query}") if $success;

	#### SET STATUS
	my $status	=	"ready";
	$status		=	"error" if not $success;

	
	$self->notify($status, $error, $data);
}

method _addQuery ($data) {
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
	
	return (1, undef);
}
method removeQuery {
	my $data	=	$self->data();
	
	#### REMOVE FROM query TABLE
    my ($success, $error) = $self->_removeQuery($data);

    $self->logError("Failed to remove query. Error: $error") and exit if not $success; 	
	$self->logStatus("Removed query $data->{query}");	
}
method _removeQuery ($data) {
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
#### DOWNLOAD
method getDownloads {
=head2

    SUBROUTINE:     getDownloads
    
    PURPOSE:

		RETURN AN ARRAY OF download HASHES

=cut

    #### GET PROJECTS
    my $username = $self->username();
    my $queries = $self->_getDownloads($username);
    
	return $queries;
}
method _getDownloads ($username) {
    $self->logDebug("username", $username);
	my $query = qq{SELECT * FROM download
WHERE username='$username'
ORDER BY download, source, filename};
	$self->logDebug("query", $query);
    
	return $self->db()->queryhasharray($query);
}
method addDownload {
=head2

	SUBROUTINE		addDownload
	
	PURPOSE

		ADD A DOWNLOAD TO THE download TABLE
        
=cut
	my $data 		=	$self->data();
 	$self->logDebug("data", $data);

	#### REMOVE IF EXISTS ALREADY
	$self->_removeDownload($data);

	my ($success, $error)	= $self->_addDownload($data);	

	$self->logStatus("Added download filename: $data->{filename}") if $success;
	$self->logStatus("Failed to add download filename: $data->{filename}. Error: $error") if not $success;
}
method _addDownload ($data) {
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
method removeDownload {
	my $data	=	$self->data();

	#### REMOVE FROM query TABLE
    my ($success, $error) = $self->_removeDownload($data);

    $self->logError("Failed to remove query. Error: $error") and exit if not $success; 	
	$self->logStatus("Removed query $data->{query}");	
}	#### removeDownload

method _removeDownload ($data) {
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







}


