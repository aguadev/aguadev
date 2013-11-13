use MooseX::Declare;

class Test::Doc extends Doc with (Test::Agua::Common) {
	
use Data::Dumper;
use Test::More;

# INTS
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 5 );

# STRINGS
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'basedir'		=>  ( isa => 'Str', is => 'rw', required	=>	1 );

######///}}}

method BUILD ($hash) {
    $self->logDebug("");

	$self->initialise();
}

method initialise () {
    $self->logDebug("");
	
	#### REMOVE OUTPUT DIRECTORY CONTENTS
	#$self->cleanUp();
}

method testDocToWiki () {
	diag("Test docToWiki");
	
	#### GET OPTIONS
	my $Bin = $self->basedir();
	my $inputdir        = "$Bin/inputs/bin/cluster";
	my $outputdir       = "$Bin/outputs/bin/cluster";
	my $outputfile      = "$Bin/outputs/bin/cluster/starcluster.txt";
	my $expectedfile    = "$Bin/inputs/bin/cluster/starcluster.txt";
	my $prefix          = "";

	$self->docToWiki($inputdir, $outputdir, $prefix);
	ok(-f $outputfile, "outputfile present");
	my $diff = `diff $outputfile $expectedfile`;
	ok($diff eq '', "starcluster.txt created");
}


}