package Test::Illumina::WGS::Util::Dumper;

=pod

PACKAGE		Test::Illumina::WGS::Util::Dumper

PURPOSE		TEST CLASS Illumina::WGS::Util::Dumper

=cut

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";
use lib "$Bin/../../../../../../lib";

use Test::Common;
use Illumina::WGS::Util::Dumper;
use base qw(Test::Common Illumina::WGS::Util::Dumper Logger);

use Test::More;

####/////}}}

sub testRemoveQuotes {
	my $self		=	shift;
	
	my $tests = [
		{
			text => "CREATE TABLE  'flowcell_samplesheet' (",
			expected => "CREATE TABLE  flowcell_samplesheet ("
		}
		,
		{
			text => "COMMENT '',",
			expected => "COMMENT '',"
		}
		,
		{
			text => "CONSTRAINT 'fk_flowcell_id' FOREIGN KEY ('flowcell_id') REFERENCES 'flowcell' ('flowcell_id') ON DELETE CASCADE ON UPDATE NO ACTION,",
			expected => "CONSTRAINT fk_flowcell_id FOREIGN KEY (flowcell_id) REFERENCES flowcell (flowcell_id) ON DELETE CASCADE ON UPDATE NO ACTION,"
		}
	];

	foreach my $test ( @$tests ) {
		$self->runRemoveQuotes($test->{text}, $test->{expected});
	}
}

sub runRemoveQuotes {
	my $self		=	shift;
	my $text		=	shift;
	my $expected	=	shift;
	
	my $actual = $self->removeQuotes($text);
	$self->logDebug("actual", $actual);
	ok($actual eq $expected, "removeQuotes    \n$text\n$expected\n$actual");
}

sub testCleanQuotes {
	my $self		=	shift;
	
	my $tests = [
		{
			text 	=> "  'coverage_flag' enum('Y','N','O') DEFAULT NULL,",
			expected=> "  coverage_flag enum('Y','N','O') DEFAULT NULL,"
		}
		,
		{	
			text 	=> "  'status_id' int(10) unsigned NOT NULL DEFAULT '0',",
			expected=> "  status_id int(10) unsigned NOT NULL DEFAULT '0',"
		}
		,
		{
			text 	=> "  UNIQUE KEY 'un_fbq_ss' ('workflow_queue_id','flowcell_samplesheet_id'),",
			expected=> "  UNIQUE KEY un_fbq_ss (workflow_queue_id,flowcell_samplesheet_id),"
		}
		,
		{
			text 	=> "  'workflow_id' int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '              ',",
			expected=> "  workflow_id int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '              ',"
		}
		,
		{
			text	=>	"  'workflow_id' int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '		',",
			expected=>	"  workflow_id int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '		',"
		}
	];

	foreach my $test ( @$tests ) {
		$self->runCleanQuotes($test->{text}, $test->{expected});
	}
}

sub runCleanQuotes {
	my $self		=	shift;
	my $text		=	shift;
	my $expected	=	shift;
	
	my $actual = $self->cleanQuotes($text);
	$self->logDebug("actual", $actual);
	ok($actual eq $expected, "cleanQuotes    \n$text\n$expected\n$actual");
}

sub testDumpToSql {
	my $self		=	shift;
	
	diag("dumpToSql");

	my $testgroups = [
		{
			dumpfile	=>	"$Bin/inputs/dumptosql/wgspipe-no-create.dump",
			outputdir	=>	"$Bin/outputs/dumptosql/wgspipe-no-create",
			expecteddir	=>	"$Bin/inputs/dumptosql/wgspipe-no-create",
			message		=>	"nocreate"
		}
		,
		{
			dumpfile	=>	"$Bin/inputs/dumptosql/workflow_queue_samplesheet.dump",
			outputdir	=>	"$Bin/outputs/dumptosql/workflow_queue_samplesheet",
			expecteddir	=>	"$Bin/inputs/dumptosql/workflow_queue_samplesheet",
			message		=>	"workflow_queue_samplesheet"
		}
		,
		{
			dumpfile	=>	"$Bin/inputs/dumptosql/create-no-insert.dump",
			outputdir	=>	"$Bin/outputs/dumptosql/create-no-insert",
			expecteddir	=>	"$Bin/inputs/dumptosql/create-no-insert",
			message		=>	"create-no-insert"
		}
	];
	
	foreach my $testgroup ( @$testgroups )
	{	
		my $dumpfile 	= 	$testgroup->{dumpfile};
		my $outputdir 	= 	$testgroup->{outputdir};
		my $expecteddir	=	$testgroup->{expecteddir};
		my $message		=	$testgroup->{message};
		
		#### CONVERT DUMP TO SQL AND TSV
		$self->dumpToSql($dumpfile, $outputdir);
		
		#### CHECK OUTPUTS
		my $sqldir		=	"$outputdir/sql";
		my $tsvdir		=	"$outputdir/tsv";
		my $expectedsqldir	=	"$expecteddir/sql";
		my $expectedtsvdir	=	"$expecteddir/tsv";
	
		ok($self->createDir($outputdir), "create outputdir");
		ok($self->createDir($sqldir), "create sqldir");
		ok($self->createDir($tsvdir), "create tsvdir");
		
		my $sqldiff = `diff -r $sqldir $expectedsqldir`;
		$self->logDebug("sqldiff", $sqldiff);
		ok($sqldiff eq "", "$message    output sql files");

		my $tsvdiff = `diff -r $tsvdir $expectedtsvdir`;
		$self->logDebug("tsvdiff", $tsvdiff);
		ok($tsvdiff eq "", "$message    output tsv files");

		#### CLEAN UP
		`rm -fr $sqldir/*`;
		`rm -fr $tsvdir/*`;
	}
}

sub testParseBlock {
	my $self		=	shift;

	diag("parseBlock");

	my $testgroups = [
		{
			blockfile	=>	"$Bin/inputs/parseblock/create-and-insert-and-view.dump",
			outputdir	=>	"$Bin/outputs/parseblock",
			expectedcreate	=> "$Bin/inputs/parseblock/workflow-queue-samplesheet-expected-create.txt",
			expectedinsert	=>	"$Bin/inputs/parseblock/workflow-queue-samplesheet-expected-insert.txt"
		}
	];
	
	foreach my $testgroup ( @$testgroups )
	{	
		my $blockfile = $testgroup->{blockfile};
		my $outputdir = $testgroup->{outputdir};

		my $block = $self->getFileContents($blockfile);
		my ($create, $insert) = $self->parseBlock($block);
		my $expectedcreate = $self->getFileContents($testgroup->{expectedcreate});
		my $expectedinsert = $self->getFileContents($testgroup->{expectedinsert});
		
		#print "create: $create\n";
		#print "expectedcreate: $expectedcreate\n";
		ok($create eq $expectedcreate, "create");
		#print "insert: $insert\n";
		#print "expectedinsert: $expectedinsert\n";
		ok($insert eq $expectedinsert, "insert");
	}
}

sub testInsertToTsv {
	my $self		=	shift;

	diag("insertToTsv");

	my $testgroups = [
		{
			test		=>	"single-insert",
			insertfile	=>	"$Bin/inputs/inserttotsv/single-insert.txt",
			outputdir	=>	"$Bin/outputs/inserttotsv",
			expectedfile=>	"$Bin/inputs/inserttotsv/single-insert-expected.tsv"
		}
		,
		{
			test		=>	"multiple-insert",
			insertfile	=>	"$Bin/inputs/inserttotsv/multiple-insert.txt",
			outputdir	=>	"$Bin/outputs/inserttotsv",
			expectedfile=>	"$Bin/inputs/inserttotsv/multiple-insert-expected.tsv"
		}
		,
		{
			test		=>	"text-values",
			insertfile	=>	"$Bin/inputs/inserttotsv/text-values.txt",
			outputdir	=>	"$Bin/outputs/inserttotsv",
			expectedfile=>	"$Bin/inputs/inserttotsv/text-values-expected.tsv"
		}
		,
		{
			test		=>	"handle-nulls",
			insertfile	=>	"$Bin/inputs/inserttotsv/handle-nulls.txt",
			outputdir	=>	"$Bin/outputs/inserttotsv",
			expectedfile=>	"$Bin/inputs/inserttotsv/handle-nulls-expected.tsv"
		}
		,
		{
			test		=>	"handle-commas",
			insertfile	=>	"$Bin/inputs/inserttotsv/handle-commas.txt",
			outputdir	=>	"$Bin/outputs/inserttotsv",
			expectedfile=>	"$Bin/inputs/inserttotsv/handle-commas-expected.tsv"
		}
		,
		{
			test		=>	"backslash-quote",
			insertfile	=>	"$Bin/inputs/inserttotsv/backslash-quote.txt",
			outputdir	=>	"$Bin/outputs/inserttotsv",
			expectedfile=>	"$Bin/inputs/inserttotsv/backslash-quote-expected.tsv"
		}
	];
	
	foreach my $testgroup ( @$testgroups ) {	
		my $insertfile 		= $testgroup->{insertfile};
		my $outputdir 		= $testgroup->{outputdir};
		my $expectedfile 	= $testgroup->{expectedfile};
		my $test 			= $testgroup->{test};

		my $insert = $self->getFileContents($insertfile);
		$self->logDebug("insert", $insert);
		my $tsv = $self->insertToTsv($insert);
		$self->logDebug("tsv\n", $tsv);
		my $expectedtsv = $self->getFileContents($expectedfile);
		$self->logDebug("expectedtsv\n", $expectedtsv);

		ok($tsv eq $expectedtsv, "insertToTsv    $test");	
	}
}

sub testGetLineElements {
	my $self		=	shift;
	
	my $tests = [
		{
			test	=>	"trailing commas",
			file		=>	"$Bin/inputs/getlineelements/trailing-commas.txt",
			expectedfile=>	"$Bin/inputs/getlineelements/trailing-commas-expected.tsv"
		}
		,
		{
			test		=>	"spaces",
			file		=>	"$Bin/inputs/getlineelements/spaces.txt",
			expectedfile=>	"$Bin/inputs/getlineelements/spaces-expected.tsv"
		}
		,
		{
			test		=>	"commas inside",
			file		=>	"$Bin/inputs/getlineelements/commas-inside.txt",
			expectedfile=>	"$Bin/inputs/getlineelements/commas-inside-expected.tsv"
		}
		,
		{
			test		=>	"commas inside-2",
			file		=>	"$Bin/inputs/getlineelements/commas-inside-2.txt",
			expectedfile=>	"$Bin/inputs/getlineelements/commas-inside-2-expected.tsv"
		}
		,
		{
			test		=>	"backslash-quote",
			file		=>	"$Bin/inputs/getlineelements/backslash.txt",
			expectedfile=>	"$Bin/inputs/getlineelements/backslash-expected.tsv"
		}
	];
	
	foreach my $test ( @$tests ) {	
		my $testname	= 	$test->{test};
		my $expectedfile= 	$test->{expectedfile};
		my $file		=	$test->{file};
		
		my $line = $self->getFileContents($file);
		$self->logDebug("line", $line);

		my $contents = $self->getFileContents($expectedfile);
		$self->logDebug("expectedfile", $expectedfile);
		my $expected;
		@$expected = split ("\t", $contents, -1);
		
		my $elements = $self->getLineElements($line);
		$self->logDebug("line", $line);
		$self->logDebug("elements", $elements);
		$self->logDebug("expected", $expected);

		is_deeply($elements, $expected, "getLineElements    $testname");	
	}
}

#### Illumina::WGS::Util::Dumper

1;