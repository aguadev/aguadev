package B::Hooks::OP::PPAddr::Install::Files;

$self = {
          'libs' => '',
          'deps' => [],
          'typemaps' => [],
          'inc' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/B/Hooks/OP/PPAddr/Install/Files.pm") {
			$CORE = $_ . "/B/Hooks/OP/PPAddr/Install/";
			last;
		}
	}

1;
