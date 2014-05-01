use MooseX::Declare;
use Conf::Json;

class Test::Conf::Json extends Conf::Json with (Agua::Common, Test::Agua::Common, Test::Common, Test::Agua::Common::Database) {
	
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# INTS
has 'LOG'			=>  ( isa => 'Int', is => 'rw', default => 3 );

######///}}}

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
	my $logfile = $self->logfile();
	$self->startLog($logfile) if defined $logfile;
	$self->logDebug("logfile", $logfile);
}

method testRead ($object, $inputfile) {
	my $sections = $object->read($inputfile);
	$self->logDebug("sections", $sections);
	$self->logDebug("sections: " . scalar(@$sections));
	ok(scalar(@$sections) == 17, "number of sections");
	
	is_deeply(
		$$sections[0],
		{
			"urlTemplate" => "http://genome.ucsc.edu/cgi-bin/hgGene?hgg_gene={proteinID}"
		},
		"sections[0]: urlTemplate"
	);
		
	is_deeply(
		$$sections[16],
		{
            "lazyfeatureUrlTemplate" => "data/tracks/chr22/knownGene/lazyfeatures-{chunk}.json"
 		},
		"sections[16]: lazyfeatureUrlTemplate"
	);
}

method testWrite ($object, $inputfile, $outputfile) {
	diag("Test write");

	$self->logDebug("inputfile", $inputfile);
	$object->read($inputfile);
	$self->logDebug("outputfile", $outputfile);
	$object->write($outputfile);
	my $diff = `diff -wB $inputfile $outputfile`;
	is($diff, '', "input and output files are identical");
}

method testGetSectionOrder ($object, $inputfile) {	
	diag("Test getSectionOrder");

	my $order = $object->getSectionOrder($inputfile);
is_deeply($order,  [
		'urlTemplate',
		'headers',
		'subfeatureClasses',
		'histogramMeta',
		'lazyIndex',
		'featureCount',
		'histStats',
		'key',
		'featureNCList',
		'className',
		'clientConfig',
		'arrowheadClass',
		'subfeatureHeaders',
		'type',
		'label',
		'sublistIndex',
		'lazyfeatureUrlTemplate',
	],
	"order and number of sections" 
);
}

method testGetKey ($object) {
	diag("Test getKey");

	my $logfile = "$Bin/outputs/getkey.log";
	$object->startLog($logfile);

	#### SCALARS
	my $scalar = $object->getKey("urlTemplate");
	ok($scalar eq 'http://genome.ucsc.edu/cgi-bin/hgGene?hgg_gene={proteinID}', "first scalar: url line");

	#### HASHES
	my $hash = $object->getKey("histogramMeta");
	is_deeply($hash, [
		{
		  'basesPerBin' => '100000',
		  'arrayParams' => {
							 'length' => 514,
							 'chunkSize' => 10000,
							 'urlTemplate' => 'data/tracks/chr22/knownGene/hist-100000-{chunk}.json'
						   }
		}
	],
	"hash entry");

	#my $value = $object->getKey("urlTemplate");
	#ok($value eq 'http://genome.ucsc.edu/cgi-bin/hgGene?hgg_gene={proteinID}');
}

method testInsertKey ($object) {
	diag("Test insertKey");

	my $logfile = "$Bin/outputs/getinsert.log";
	$object->startLog($logfile);
	
	my $key = "urlTemplate";
	my $value = "http://genome.ucsc.edu/cgi-bin/hgGene?hgg_gene={proteinID}XXXX";
	my $outputfile = "$Bin/outputs/trackData-insertKey.json";
	$object->outputfile($outputfile);
	$object->insertKey($key, $value, undef);
	$object->read($outputfile);
	my $inserted = $object->getKey($key);
	#$object->logDebug("inserted", $inserted);
	ok($inserted eq $value, "inserted value as expected");
	
	my $inputfile = "$Bin/inputs/trackData-noKey.json";
	$object->inputfile($inputfile);
	$object->read($inputfile);
	$inserted = $object->getKey("urlTemplate");
	is($inserted, undef, "no existing key as expected");
	my $index = 0;
	$object->insertKey($key, $value, $index);
	$inserted = $object->getKey($key);
	#$object->logDebug("inserted", $inserted);
	is($inserted, $value, "inserted key found");
	my $insertedindex = $object->getKeyIndex($key);
	is($insertedindex, $index, "inserted key index");	
}



method testPretty ($originalfile, $inputfile, $application, $prettyfile) {
	#### SET UP
	$self->setUpFile($originalfile, $inputfile);

	my $command = qq{$application \\
--inputfile "$inputfile" \\
--mode pretty};
	$self->logDebug("command", $command);
	`$command`;

	#compare_ok($inputfile, $prettyfile, "input and pretty file comparison");
	my $diff = `diff -wB $inputfile $prettyfile`;
	is($diff, '', "testPretty: input and pretty files are identical");

	#### CLEAN UP
	$self->setUpFile($originalfile, $inputfile);
}

method testUnpretty ($originalfile, $inputfile, $application, $prettyfile, $unprettyfile) {
	diag("Test unpretty");

	#### SET UP: COPY PRETTY TO INPUT
	$self->setUpFile($prettyfile, $inputfile);

	my $command = qq{$application \\
--inputfile "$inputfile" \\
--mode unpretty};
	$self->logDebug("command", $command);
	`$command`;
	
	my $diff = `diff -wB $inputfile $unprettyfile`;
	is($diff, '', "testUnpretty: input and unpretty files are identical");

	#### CLEAN UP
	$self->setUpFile($originalfile, $inputfile);
}

method testInsert ($originalfile, $inputfile, $prettyfile, $insertedfile, $logfile, $application, $key, $value) {
	diag("Test insert");

	#### SET UP: COPY PRETTY TO INPUT
	$self->setUpFile($prettyfile, $inputfile);
	
	my $command = qq{$application \\
--inputfile "$inputfile" \\
--mode insert \\
--key $key \\
--value "$value"
};	
	#print "command: $command\n";
	`$command`;

	my $diff = `diff -wB $inputfile $insertedfile`;
	is($diff, '', "testInsert: input and inserted files are identical");

	#### CLEAN UP
	$self->setUpFile($originalfile, $inputfile);
}

method testMultiInsert ($originalfile, $multifile, $inputfile, $prettyfile, $insertedfile, $logfile, $application, $key, $value) {
	diag("Test multiInsert");

	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("multifile", $multifile);
	$self->logDebug("insertedfile", $insertedfile);
	
	#### SET UP
	$self->setUpDirs();
	my $command = qq{$application \\
--inputfile "$multifile" \\
--mode pretty
};	
	`$command`;

	$command = qq{$application \\
--inputfile "$multifile" \\
--mode insert \\
--key $key \\
--value "$value"
};	
	$self->logDebug("command", $command);
	`$command`;

	my $expectedfile = $insertedfile;
	$expectedfile =~ s/inputs/outputs/;
	$command = "diff -wB $expectedfile $insertedfile";
	$self->logDebug("command", $command);

	my $diff = `$command`;
	is($diff, '', "testMultiInsert: input and inserted files are identical");

	#### CLEAN UP
	$self->setUpDirs();
}

}