use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::CLI::App with (Test::Agua::Common::Database,
	Test::Agua::Common::Util,
	Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::Package,
	Agua::Common::Util) extends Agua::CLI::App {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

# Ints
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'requestor'     => ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'       => ( isa => 'Str|Undef', is => 'rw' );
has 'owner'	        => ( isa => 'Str|Undef', is => 'rw' );
has 'package'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'remoterepo'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'sourcedir'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'rootpassword'  => ( isa => 'Str|Undef', is => 'rw' );
has 'dbuser'        => ( isa => 'Str|Undef', is => 'rw' );
has 'dbpass'        => ( isa => 'Str|Undef', is => 'rw' );
#has 'sessionid'     => ( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'head' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);
has 'master' 	=> (
	is =>	'rw',
	'isa' => 'Agua::Instance',
	default	=>	sub { Agua::Instance->new();	}
);

has 'ops' 	=> (
	is 		=>	'rw',
	isa 	=>	'Agua::Ops',
	default	=>	sub { Agua::Ops->new();	}
);

has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new(	memory	=>	1	);	}
);

####////}}

method BUILD ($hash) {
	$self->logDebug("");
	
	if ( defined $self->logfile() ) {
		$self->head()->ops()->logfile($self->logfile());
		$self->head()->ops()->SHOWLOG($self->SHOWLOG());
		$self->head()->ops()->PRINTLOG($self->PRINTLOG());
	}
}

method testLoadUsage {
	diag("loadUsage");
	
	#### SET UP DIRS
	my $inputs = "$Bin/inputs/loadusage";
	my $outputs = "$Bin/outputs/loadusage";
	$self->setUpDirs($inputs, $outputs);

	#### SET FILES
	my $usagefile = "$Bin/outputs/loadusage/jbrowseFeatures.txt";
	my $expectedusagefile = "$Bin/outputs/loadusage/jbrowseFeatures-expected.txt";
	my $appfile = "$Bin/outputs/loadusage/jbrowseFeatures.app";
	my $expectedappfile = "$Bin/outputs/loadusage/jbrowseFeatures-expected.app";

	#### LOAD USAGE	
	my $app = $self->_loadUsage($usagefile);
	$self->logDebug("app", $app->toString());
	
	#### CONFIRM PARAMETER NAMES
	my $expected = $self->getFileContents($expectedusagefile);
	$self->logDebug("expected", $expected);
	ok($app->toString() eq $expected, "parameter names");
	
	#### CHECK DESCRIPTIONS
	my $tests = [
		{
			param		=>	"tempdir",
			type		=>	"String",
			description =>	"Use this temporary directory to write data on execution host"
		},
		{
			param		=>	"maxjobs",
			type		=>	"Int",
			description =>	"Maximum number of jobs to be run concurrently"
		},
		{
			param		=>	"queue",
			type		=>	"String",
			description =>	undef
		}
	];
	
	foreach my $test ( @$tests ) {
		my $paramname = $test->{param};
		ok($app->hasParam($paramname), "hasParam $paramname");

		my $param = $app->getParam($paramname);
		$self->logDebug("param", $param);

		my $type = $param->paramtype();
		$self->logDebug("type", $type);
		is_deeply($type, $test->{type}, "type for param $paramname");

		my $description = $param->description();
		$self->logDebug("description", $description);
		is_deeply($description, $test->{description}, "description for param $paramname");
	}
	
	#### WRITE APP FILE
	$self->exportApp($appfile);

	#### TEST FILE
	ok(-f $appfile, "appfile printed: $appfile");
	
	my $appjson = $self->getFileContents($appfile);
	my $expectedappjson = $self->getFileContents($expectedappfile);
	$self->logDebug("appjson", $appjson);
	$self->logDebug("expectedappjson", $expectedappjson);
	
	require JSON;
	my $parser = JSON->new();
	my $appobject = $parser->decode($appjson);
	$self->logDebug("appobject", $appobject);
	my $expectedapp = $parser->decode($expectedappjson);
	$self->logDebug("expectedapp", $expectedapp);

	is_deeply($appobject, $expectedapp, "app hash as expected");	
}


}   #### Test::Agua::CLI::App

