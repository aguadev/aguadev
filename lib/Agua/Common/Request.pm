package Agua::Common::Request;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Method::Signatures;

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


1;