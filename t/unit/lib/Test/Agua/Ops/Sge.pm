use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Ops::Sge with (Agua::Ops::Sge,
	Test::Agua::Common::Database,
	Test::Agua::Common::Util,
	Agua::Common::Logger) {

use FindBin qw($Bin);
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use Data::Dumper;
use Test::More;

has 'runCommandOutput'	=> ( isa => 'HashRef|Undef', is => 'rw' );

####////}}

method BUILD ($hash) {
	if ( defined $hash ) {
		foreach my $key ( keys %{$hash} ) {
			$self->$key($hash->{$key}) if $self->can($key);
		}
	}
	
	$self->logDebug("");
}

method testSgeProcessListening {
	diag("Testing sgeProcessListening");

	my $port = 36352;
	my $pattern = "sge_execd";
	my $expected = "tcp        0      0 0.0.0.0:36352           0.0.0.0:*               LISTEN      6166/sge_execd";
	my $output = {
		output	=> 	$expected,
		error	=> 	""
	};
	$self->runCommandOutput($output);
	
	my $listening = $self->sgeProcessListening($port, $pattern);
	$self->logDebug("listening", $listening);
	$self->logDebug("expected", $expected);
	ok($listening !~ /^0$/, "not incorrect output");

	#like  ($expected, qr/$listening/, "correct output");
	
	cmp_ok($listening, 'eq', $expected, "correct output");	
}

#### UTILS
method runCommand ($command) {
	$self->logDebug("command", $command);

	my $output = $self->runCommandOutput();
	$self->logDebug("output", $output);
	
	return ($output->{output}, $output->{error});
}


}
	