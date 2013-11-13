use MooseX::Declare;

class Test::Conf::StarCluster extends Conf::StarCluster with (Agua::Common, Test::Agua::Common) {
	
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
our $DEBUG = 0;
#$DEBUG = 1;

# INTS
has 'LOG'			=>  ( isa => 'Int', is => 'rw', default => 3 );

######///}}}

method BUILD ($hash) {
    #$self->logDebug("()");1
	$self->initialise();
}

method initialise () {
	my $logfile = $self->logfile();
	$self->startLog($logfile) if defined $logfile;
	#$self->logDebug("logfile", $logfile);
}

method testGetKey ($originalfile, $inputfile) {
    diag("Test getKey");
	
	#### SETUP
    $self->setUpFile($originalfile, $inputfile);
	$self->inputfile($inputfile);
	$self->read();

	#### TESTS
	
	#### BY section
	my $expected;
	my $actual;
	
	$expected = "True";
	$actual = $self->getKey("global", "ENABLE_EXPERIMENTAL");
	ok($actual eq $expected, "global, ENABLE_EXPERIMENTAL: $expected (actual: $actual)");

	$expected = "syoung-microcluster";
	$actual = $self->getKey("global", "DEFAULT_TEMPLATE");
	ok($actual eq $expected, "global, DEFAULT_TEMPLATE: $expected");

	#### BY section:value
	$expected = "us-east-1a";
	$actual = $self->getKey("cluster:syoung-microcluster", "AVAILABILITY_ZONE");
	ok($actual eq $expected, "cluster:syoung-microcluster, AVAILABILITY_ZONE: $expected");

	$expected = "ami-78837d11";
	$actual = $self->getKey("cluster:syoung-microcluster", "NODE_IMAGE_ID");
	ok($actual eq $expected, "cluster:syoung-microcluster, NODE_IMAGE_ID: $expected");

	$expected = undef;
	ok(! $self->getKey("cluster:syoung-microcluster", "NODE_IMAGE_IDXXX"), "Correctly can't find cluster:syoung-microcluster, NODE_IMAGE_IDXXX");
}

method testSetKey ($originalfile, $inputfile, $addedfile) {
	diag("Test setKey");

	#### SETUP
    $self->setUpFile($originalfile, $inputfile);
	$self->inputfile($inputfile);
	$self->read();

	#### TESTS
	my $expected;
	my $actual;
		
	#### BY section:value
	$expected = "vol-eeee0000";
	$self->setKey("volume:experiments", "VOLUME_ID", $expected);
	$actual = $self->getKey("volume:experiments", "VOLUME_ID");
	ok($expected eq $actual, "setKey    volume:experiments, VOLUME_ID: $expected");
	my $diff = `diff $addedfile $inputfile`;
	ok($diff eq '', "Added file content is correct");
	
	#### BY section
	$expected = "True";
	$self->setKey("global", "SPOT_RATE", $expected);
	$actual = $self->getKey("global", "SPOT_RATE");
	ok($expected eq $actual, "setKey    global, SPOT_RATE: $expected");
}

method testRemoveKey ($originalfile, $inputfile, $removedfile) {
    diag("Test removeKey");

	#### SETUP
    $self->setUpFile($originalfile, $inputfile);
	$self->inputfile($inputfile);
	$self->read();

	#### TESTS
	my $expected = "True";
	my $actual;
		
	#### BY section:value
	$actual = $self->removeKey("global", "ENABLE_EXPERIMENTAL");
	ok($actual eq $expected, "global, ENABLE_EXPERIMENTAL: $expected (actual: $actual)");
	ok( -f $inputfile, "input file exists");
	my $diff = `diff $removedfile $inputfile`;
	ok($diff eq '', "Removed file content is correct");
	

	#### ADD/REMOVE CONFIG
	$expected = "mediumcluster";
	ok($self->setKey("globalised:test", "DEFAULT_TEMPLATE", $expected, "MEDIUM CLUSTER IS DEFAULT"), "added DEFAULT TEMPLATE");
	$actual = $self->getKey("globalised:test", "DEFAULT_TEMPLATE");
	ok($expected eq $actual, "setKey after removeKey correct value: $expected");
	ok(! $self->removeKey("globalised", "test", "DEFAULT_TEMPLATE", "smallcluster"), "correctly failed to remove wrong DEFAULT TEMPLATE");

	#### REMOVE, ADD THEN REMOVE
	$expected = "vol-XXXXXXXX";
	ok(! $self->removeKey("aws", "", "datavolume", ), "correctly failed to remove non-existent entry");
	ok($self->setKey("aws", "datavolume", $expected, undef), "added missing entry");
	$actual = $self->removeKey("aws", "datavolume", $expected);
	ok($expected eq $actual, "correctly removed existing entry");
	
	


}


}