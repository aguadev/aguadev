use MooseX::Declare;

class Test::Agua::Upload extends Agua::Upload with (Test::Agua::Common::Util, Test::Agua::Common::Database) {
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use JSON;

# Ints
has 'showlog'		=> ( isa => 'Int', 		is => 'rw', default	=> 	2);
has 'printlog'		=> ( isa => 'Int', 		is => 'rw', default	=> 	2);

# Strings
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

#####/////}}}}}

method testSetData {
	diag("# setData");
	
	my $tests = [
		{
			filename	=>	"bigpic2.txt",
			maxindex	=>	96,
			firstline	=>	"------WebKitFormBoundaryzFTuSOyQ4BlTIUwc\r",
			secondline	=>	"Content-Disposition: form-data; name=\"uploadedfiles[]\"; filename=\"upload-bigpic-nouser.txt\"\r"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $filename	=	$test->{filename};
		my $expected	=	$test->{expected};
		my $filepath	=	"$Bin/inputs/$filename";
		
		open(STDIN, "<$filepath") or die print "Can't set STDIN to filepath: $filepath\n";
		$self->setData();

		#### SET DATA		
		my $data = $self->data();

		#### TESTS
		my $maxindex = $self->maxindex();
		$self->logDebug("maxindex", $maxindex);
		ok($maxindex eq $test->{maxindex}, "maxindex");

		ok($self->hasData(), "hasData affirmative");
		
		$self->counter(999999999);
		ok(!$self->hasData(), "hasData negatory");
	}
}

method testNextData {
	diag("# nextData");
	my $tests = [
		{
			filename	=>	"bigpic2.txt",
			maxindex	=>	96,
			firstline	=>	"------WebKitFormBoundaryzFTuSOyQ4BlTIUwc",
			secondline	=>	"Content-Disposition: form-data; name=\"uploadedfiles[]\"; filename=\"upload-bigpic-nouser.txt\""
		}
	];
	
	foreach my $test ( @$tests ) {
		my $filename	=	$test->{filename};
		my $expected	=	$test->{expected};
		my $filepath	=	"$Bin/inputs/$filename";
		
		open(STDIN, "<$filepath") or die print "Can't set STDIN to filepath: $filepath\n";
		$self->setData();

		#### SET DATA		
		my $data = $self->data();

		my $firstline = $self->nextData();
		my $counter = $self->counter();
		$self->logDebug("firstline", $firstline);
		$self->logDebug("counter", $counter);
		ok($firstline eq $test->{firstline}, "firstline");
		ok($counter == 0, "counter == 0");
		
		my $secondline = $self->nextData();
		$counter = $self->counter();
		$self->logDebug("secondline", "***". $secondline . "***");
		$self->logDebug("counter", $counter);
		ok($secondline eq $test->{secondline}, "secondline");
		ok($counter == 1, "counter == 1");
	}
}

method testGetBoundary {

	my $tests = [
		{
			contenttype =>	"multipart/form-data; boundary=----WebKitFormBoundaryQl9ZYFS9eLPI3vl6",
			expected 	=>	"WebKitFormBoundaryQl9ZYFS9eLPI3vl6"
		}
		,
		{
			contenttype =>	"multipart/form-data; boundary=-----------------------------21121370611278322191466223364",
			expected 	=>	"21121370611278322191466223364"
		}
	];
	
	#### TEST
	foreach my $test ( @$tests ) {
		my $contenttype = $test->{contenttype};
		$ENV{'CONTENT_TYPE'}	=	$contenttype;
		my $boundary = $self->getBoundary();
		$self->logDebug("boundary", $boundary);
		
		my $expected	=	$test->{expected};
		
		ok($boundary eq $expected, "boundary correct: $boundary");
	}
}

method testParseFilename {
	diag("# Test parseFilename");

	my $inputfiles = [
		"dctype.rdf"
		,
		"upload-parseFilename-no-blank-line.txt"
	];
	
	foreach my $inputfile ( @$inputfiles ) {
		my $filepath = "$Bin/inputs/$inputfile";
		$self->logDebug("filepath", $filepath);

		#### SET DATA
		open(STDIN, "<$filepath") or die print "Can't set STDIN to filepath: $filepath\n";
		$self->setData();

		my $filename = $self->parseFilename();

		ok($filename eq $inputfile, "parsed filename");
	}
}

method testPrintTempfile {
	diag("# Test printTempfile");

	my $tests = [
		{
			filename	=>	"dctype.rdf",
			contenttype	=>	"multipart/form-data; boundary=-----------------------------21121370611278322191466223364"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $filename	=	$test->{filename};
		diag("filename: $filename");

		#### SET FILEPATH	
		my $filepath	=	"$Bin/inputs/$filename";
		$self->logDebug("filepath", $filepath);

		#### SET BOUNDARY
		$ENV{'CONTENT_TYPE'}	= $test->{contenttype};
		my $boundary	=	$self->getBoundary();
	
		#### SET DATA
		open(STDIN, "<$filepath") or die print "Can't set STDIN to filepath: $filepath\n";
		$self->setData();
	
		#### PARSE OUT FILENAME
		$self->parseFilename();
	
		#### PRINT CONTENTS TO FILE
		my $tempfile =	$self->printTempfile($filename, $boundary);
	
		#### CLOSE INPUTFILE
		close(FILE);
		
		my $expected = "$Bin/inputs/$filename-contents-only";
		my $diff = `diff $tempfile $expected`;
	
		ok($diff eq '', "tempfile contents");
	}

}

method testParseParams {
	diag("# Test parseParams");
	
	my $tests = [
		{
			filename	=> 	"dctype.rdf-details",
			contenttype	=>	"multipart/form-data; boundary=-----------------------------17316985621204646634638386356",
			params		=>	{
				username	=>	"admin",
				path		=>	"Project2/Workflow1",
				sessionid	=>	"1234567890.1234.123"
			}
		}
		,
		{
			filename	=> "upload-username-etc.txt",
			params		=>	{
				username	=>	"admin",
				sessionid	=>	"0000000000.0000.000"
			}
		}
		,
		{
			testname	=> "linux-deb-file",
			filename	=> "google-chrome-stable_current_amd64.deb-linux-line-endings",
			params		=>	{
				username	=>	"guest",
				path		=>	"Project1/Workflow1/data",
				sessionid	=>	"1355898711.1206.532"
			}
		}
		,
		{
			testname	=> "big-pic2",
			filename	=> "bigpic2.txt",
			params		=>	{
				username	=>	"admin",
				sessionid	=>	"0000000000.0000.000"
			}
		}
		,	
		{
			testname	=> 	"OSX-deb-file",
			boundary	=>	"15400688611499959261267840338",
			filename	=> 	"google-chrome-stable_current_amd64.deb",
			params		=>	{
				sessionid	=>	"1355898711.1206.532",
				path		=>	"Project1/Workflow1/data",
				username	=>	"guest"
			}
		}
	];
	
	foreach my $test ( @$tests ) {
		
		#### SET CONTENT_TYPE
		$ENV{'CONTENT_TYPE'}	= $test->{contenttype};
		
		#### OPEN INPUTFILE
		my $filename = $test->{filename};
		my $filepath = "$Bin/inputs/$filename";
		$self->logDebug("filepath", $filepath);
		
		#### SET DATA
		open(STDIN, "<$filepath") or die print "Can't set STDIN to filepath: $filepath\n";
		$self->setData();

		my $params = $self->parseParams();
		$self->logDebug("params", $params);

		#### CLOSE INPUTFILE
		close(FILE);

		diag("filename: $filename");
		my $expected = $test->{params};
		foreach my $key ( keys %$expected ) {
			ok($params->{$key} eq $expected->{$key}, "parsed param '$key'");
		}
	}	
}

method testNotifyStatus {
	diag("# Test notifyStatus");
	
	my $tests = [
		{
			token		=> "1234123421341234123421",
			callback	=>	"postUpload",
			expectedfile=>	"$Bin/inputs/json/project-ok.json",
			project	=>	{
				username	=>	"guest",
				mode		=>	"manifest",
				project_name=>	"III_Test4",
				filename	=> 	"manifest-III_Test4.csv",
				error		=>	"project 'III_Test4' already exists in database"
			},
			samples	=>	[]
		}
	];
	
	my $exchange = Agua::Common::Exchange->new();
	$self->logDebug("exchange", $exchange);

	#### SET JSON PARSER
	my $jsonparser = JSON->new();
	
	foreach my $test ( @$tests ) {
		#### TEST DATA
		my $json = $self->fileContents($test->{expectedfile});
		$self->logDebug("json", $json);
		my $data = $jsonparser->decode($json);
	
		$self->logDebug("DOING self->notifyStatus(data)    data", $data);
		my $result = $self->notifyStatus($data);
		$self->logDebug("result", $result);
		
		isa_ok($result, "Net::RabbitFoot::Channel", "project ok")
	}	
}


}	####	Agua::Upload  
