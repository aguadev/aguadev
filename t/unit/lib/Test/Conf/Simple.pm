use MooseX::Declare;

class Test::Conf::Simple extends Conf::Simple with (Agua::Common, Test::Agua::Common) {
	
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# Bool
has 'memory'		=> ( isa => 'Bool', 	is => 'rw', default	=> 	0);

# Ints
has 'showlog'		=> ( isa => 'Int', 		is => 'rw', default	=> 	2);
has 'printlog'		=> ( isa => 'Int', 		is => 'rw', default	=> 	5);

# Objects
has 'sections'		=> ( isa => 'ArrayRef', is => 'rw'	);

######///}}}

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
}

method testWriteToMemory {
	#### FILES
	my $originalfile    =  "$Bin/inputs/default.conf";
	my $inputfile       =  "$Bin/outputs/default.conf";

	#### SET LOG
	my $logfile = "$Bin/outputs/writetomemory.log";
	#$self->startLog($logfile);
	$self->logfile($logfile);
	$self->showlog(2);
	$self->printlog(5);

	#### SETUP
    $self->setUpFile($originalfile, $inputfile);
	$self->inputfile($inputfile);
	#$self->read();

	#### SET MEMORY
	$self->memory(1);

	#### TESTS
	my $expecteduser = "TEST--USER";
	$self->setKey("database", "TESTUSER", $expecteduser);
	my $user = $self->getKey('database', 'TESTUSER');
	ok($expecteduser eq $user, "writeToMemory    setKey for TESTUSER: $user");
	my $diff = `diff $originalfile $inputfile`;
	ok($diff eq '', "writeToMemory    inputfile unchanged");
	
	#### NEW SECTIONS
	my $expectedvalue = "TESTVALUE";
	$self->setKey("NEWSECTION", "TEST", $expectedvalue);
	my $actualvalue = $self->getKey("NEWSECTION", "TEST");
	ok($actualvalue eq $expectedvalue, "writeToMemory    new section key value: $expectedvalue");
	$diff = `diff $originalfile $inputfile`;
	ok($diff eq '', "writeToMemory    new section inputfile unchanged");

	$self->removeKey("NEWSECTION", "TEST");
	$actualvalue = $self->getKey("NEWSECTION", "TEST");
	ok( ! $actualvalue, "writeToMemory    new section no value after removeKey");
	$diff = `diff $originalfile $inputfile`;
	ok($diff eq '', "writeToMemory    new section inputfile unchanged");
}

method write ($sections) {
	$self->logDebug("self->memory", $self->memory());
	$self->logDebug("sections length", scalar(@$sections));

#$self->logDebug("sections", $sections);
#$self->logDebug("file", $file);

#$self->logDebug("DEBUG EXIT") and exit;
	return $self->writeToMemory($sections) if $self->memory();
	return $self->SUPER::write();
}

method writeToMemory ($sections) {
	$self->logDebug("");
	$self->sections($sections);
}

method read {
	$self->logDebug("");

	return $self->SUPER::read() if not defined $self->sections();
	return $self->readFromMemory();
}

method readFromMemory {
	return $self->sections();
}


}