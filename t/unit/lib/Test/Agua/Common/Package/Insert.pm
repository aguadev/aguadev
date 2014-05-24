use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Common::Package::Insert with (Test::Agua::Common::Package,
	Agua::Common::Package,
	Test::Agua::Common::Database,
	Test::Agua::Common::Util,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Project,
	Agua::Common::Workflow,
	Agua::Common::Privileges,
	Agua::Common::Stage,
	Agua::Common::App,
	Agua::Common::Parameter,
	Agua::Common::Base,
	Agua::Common::Util) extends Agua::Ops {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

####////}}

method BUILD ($hash) {
	$self->logDebug("");
	
	if ( defined $self->logfile() ) {
		$self->head()->ops()->logfile($self->logfile());
		$self->head()->ops()->keyfile($self->keyfile());
		$self->head()->ops()->log($self->log());
		$self->head()->ops()->printlog($self->printlog());
	}
}

#### DATABASE
method testInsertData {
    my $hash = {
        username    =>  $self->conf()->getKey("database", "TESTUSER"),
        owner       =>  $self->conf()->getKey("database", "TESTUSER"),
        package 	=>  "apps",
		opsdir		=>	"$Bin/inputs/ops",
		installdir	=>	"$Bin/outputs/target",
        version     =>  "0.3"
    };

	my $table = "package";

	$self->insertData($table, $hash);
}

}   #### Test::Agua::Common::Package::Default

=cut
