use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Ssh with (Agua::Common::Logger,
	Agua::Common::Util) extends Agua::Ssh {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

#### Int
has 'keyfile'		=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'command'		=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'remoteuser'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'remotehost'		=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);

####////}}

method BUILD ($hash) {
	$self->logDebug("hash", $hash);	
}

#### SYNC WORKFLOWS
method testExecute {
	diag("Test execute");

	#my $command		=	$self->command();
	my $keyfile 	= 	$self->keyfile();
	my $remotehost	=	$self->remotehost();
	my $remoteuser	=	$self->remoteuser() || "root";
	$self->logDebug("keyfile", $keyfile);
	$self->logDebug("remotehost", $remotehost);
	$self->logDebug("remoteuser", $remoteuser);

	my $commandobjects = [
		{
			command	=>	"ls /tmp",
			output	=>	"\.+",
			error	=>	"^(\\s*\$|Warning: Permanently added)"
		},
		{
			command	=>	"cd /tmp/nothere",
			output	=>	"",
			error	=>	"bash: line 0: cd: \/tmp\/nothere: No such file or directory"
		}
	];
	
	foreach my $commandobject ( @$commandobjects ) {
		my $command = $commandobject->{command};
		my ($output, $error) = $self->execute($command);
		$self->logDebug("output", $output);
		$self->logDebug("error", $error);
		
		ok($output =~ /$commandobject->{output}/, "output for command: $command");
		ok($error =~ /$commandobject->{error}/, "error for command: $command");
	}
}


}   #### Test::Agua::Common::Ssh


=cut
