use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Test::Infusion::Base extends Infusion::Base with (Infusion::Common::Util, Test::Agua::Common::Database) {

use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use JSON;

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'password'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'requestor'		=> 	( isa => 'Str|Undef', is => 'rw' );

#####/////}}}}}

method BUILD ($args) {
	$self->setSlots($args);
}

method testUpdateProject {
	diag("# updateProject");

	my $testuser = $self->conf()->getKey("database", "TESTUSER");
	$self->username($testuser);
	
	###### LOAD DATABASE
	$self->setUpTestDatabase();
	$self->setDatabaseHandle();

	#### CLEAN UP
	my $query = qq{DELETE FROM project};
	$self->db()->do($query);
	$query = qq{DELETE FROM sample};
	$self->db()->do($query);

	#### LOAD TSVFILE
	my $tsvfile = "$Bin/inputs/tsv/project.tsv";
	$self->loadTsvFile("project", $tsvfile);

	#### JSON PARSER
	my $jsonparser = JSON->new();

	#### OVERRIDE logError
	no warnings;
	*{logError} = sub {
		#print "...................................OVERRIDE logError: ", shift, "\n";
		return 0;
	};
	*{logStatus} = sub {
		#print "...................................OVERRIDE logStatus: ", shift, "\n";
		return 1;
	};
	use warnings;
	
	my $tests = [
		{
			testname	=>	"failure",
			jsonfile	=>	"$Bin/inputs/json/update-failure.json",
			expected	=>	"0E0",
			indirect	=>	0
		}
		,
		{
			testname	=>	"success",
			jsonfile	=>	"$Bin/inputs/json/update-failure-exists.json",
			expected	=>	1,
			indirect	=>	1
		}
		,
		{
			testname	=>	"failure-undef",
			jsonfile	=>	"$Bin/inputs/json/update-failure-undef.json",
			expected	=>	"0E0",
			indirect	=>	0
		}
	];

	foreach my $test ( @$tests ) {
		my $testname	=	$test->{testname};
		my $jsonfile	=	$test->{jsonfile};
		my $expected	=	$test->{expected};
		my $indirect	=	$test->{indirect};
		
		my $contents = $self->fileContents($jsonfile);
		my $json = $jsonparser->decode($contents);
		$self->logDebug("json", $json);
		my $data = $json->{data};
		
		#### TEST _updateProject
		my $result = $self->_updateProject($data);
		$self->logDebug("result", $result);
		is_deeply($result, $expected, "_updateProject $testname");
	
		#### TEST updateProject
		$self->setSlots($json);
		$result = $self->updateProject();
		$self->logDebug("result", $result);
		is_deeply($result, $indirect, "updateProject $testname");
	}
}

method fileContents ($filename) {
	if ( not -f $filename ) {
		print "Can't find file; $filename\n\n";
		return;
	}
	
	my $endline = $/;
	
	$/ = undef;
	open(FILE, $filename) or die "[Util::contents] Can't open file '$filename'\n";
	my $contents = <FILE>;
	close(FILE);
	$/ = $endline;

	return $contents;
}


}	####	Agua::Login::Common
