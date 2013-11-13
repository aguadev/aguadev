use MooseX::Declare;

#### FAKE A CGI OBJECT - JUST THE PARAM METHOD WILL DO


class Agua::FakeCGI {

has 'params'	    => ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'querystring'   => ( isa => 'Str|Undef', is => 'rw', default => '' );

method BUILD ($hash) {
    $self->initialise();
    #use Data::Dumper;
}

method initialise () {
    my @array = split "\&", $self->querystring();

    my $params = {};
    foreach my $pair ( @array )
    {
        my ($key, $value) = $pair =~ /^(.+?)=(.+)$/;
        die "Missing key or value in pair: $pair\n" if not defined $key or not defined $value;
        #### CONVERT HTML CODED ASCII INTO TEXT
        $value =~ s/%22/"/g;
        $value =~ s/%2F/\//g;
        $params->{$key} = $value;
    }

    $self->params($params);
}

method param ($param) {
    
    return $self->params()->{$param};
}



}
