use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Test::Agua::Common::App with (Agua::Common::App, Agua::Common::Logger, Agua::Common::Util, Test::Agua::Common::Util, Test::Agua::Common::Database, Agua::Common::Database, Agua::Common::Base) {

use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use JSON;

# Ints

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'password'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'requestor'		=> 	( isa => 'Str|Undef', is => 'rw' );

# OBJECTS
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is 		=>	'rw',
	isa 	=> 	'Conf::Yaml|Undef'
);

#####/////}}}}}

method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( $args ) {
			$self->$arg($args->{$arg}) if $self->can($arg);
		}
	}
}

method testSaveApp {
	my $tests = [
		{
			name			=>	"localonly",
			file			=>	"$Bin/inputs/saveapp/localonly.json",
			expectedfile	=>	"$Bin/inputs/saveapp/tsv/localonly.tsv"
		}
	];
	
	#### LOAD --no-data DATABASE DUMP 
	my $installdir		=	$ENV{'installdir'};
	$self->logDebug("installdir", $installdir);	
	my $dumpfile	=	"$installdir/bin/sql/dump/create-agua.dump";
	$self->dumpfile($dumpfile);

	
	foreach my $test ( @$tests ) {
		$self->logDebug("test", $test);
		my $name		=	$test->{name};
		my $file		=	$test->{file};
		my $expectedfile=	$test->{expectedfile};

		my $json		=	$self->getFileContents($file);
		$self->logDebug("json", $json);
		my $object		=	$self->jsonToObject($json);
		my $data		=	$object->{data};
		$self->logDebug("data", $data);
		#$self->json($data);

		#### SET DATABASE HANDLE
		$self->setUpTestDatabase();
		
		my $success		=	$self->_saveApp($data);
		$self->logDebug("success", $success);
		
		##### VERIFY
		#diag("Testing loaded apps");
		#$self->checkTsvLines("app", $appfile, "loadAppFiles    app values");
	}
	
}


}