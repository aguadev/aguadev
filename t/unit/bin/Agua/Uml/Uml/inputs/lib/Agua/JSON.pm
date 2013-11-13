use MooseX::Declare;

#### FAKE A CGI OBJECT - JUST THE PARAM METHOD WILL DO
class Agua::JSON with Agua::Common::Logger {

has 'params'	    => ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'querystring'   => ( isa => 'Str|Undef', is => 'rw', default => '' );

method decode ($json) {
	my @pairs = split ",", $json;
	my $data;
	foreach my $pair ( @pairs ) {
		my ($key, $value) = $pair =~ /"*([^"]+)"*:"*([^"^}]+)"*/;
		$self->logDebug("key", $key);
		$self->logDebug("value", $value);
		$value = '' if not defined $value;
		$data->{$key} = $value if defined $key;
	}
	
	return $data;
}

method cgiToJson ($querystring) {
	
	$self->logDebug("querystring", $querystring);
    my @array = split "\&", $querystring;
    my $json = {};
    foreach my $pair ( @array )
    {
        my ($key, $value) = $pair =~ /^(.+?)=(.+)$/;
        die "Missing key or value in pair: $pair\n" if not defined $key or not defined $value;
        #### CONVERT HTML CODED ASCII INTO TEXT
        $value =~ s/%22/"/g;
        $value =~ s/%2F/\//g;
        $json->{$key} = $value;
    }
	
    return $json;
}

}
