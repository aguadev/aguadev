use MooseX::Declare;

class Test::Conf::Yaml extends Conf::Yaml with (Test::Agua::Common) {

#### EXTERNAL MODULES
use Test::More;
use JSON;
use Data::Dumper;
use FindBin qw($Bin);

#####////}}}}

method testRead {
	diag("#### read");
	
	my $inputfile	=	"$Bin/inputs/config.yaml";
	my $logfile		=	"$Bin/outputs/read/read.log";	
	my $expectedfile=	"$Bin/inputs/read/config.json";
	my $expectedjson=	$self->getFileContents($expectedfile);

	my $expected = JSON->new()->decode($expectedjson);
	$self->logDebug("expected", $expected);
	
	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	my $yaml 		= 	$self->yaml();
	$self->logDebug("yaml", $yaml);
	
	is_deeply($yaml->[0], $expected);
}

method testGetKey {
	diag("#### getKey");
	
	my $inputfile	=	"$Bin/inputs/config.yaml";
	my $logfile		=	"$Bin/outputs/getkey/getkey.log";	
	my $expectedfile=	"$Bin/inputs/getkey/config.json";
	my $expectedjson=	$self->getFileContents($expectedfile);

	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	my $tests	=	[
		{
			name		=>	"scalar, no subkey",
			key			=>	"username",
			subkey		=>	undef,
			expected	=>	"billy",
		}
		,
		{
			name		=>	"array, no subkey",
			key			=>	"error_emails",
			subkey		=>	undef,
			expected	=>	[
				"BATMAN\@batcave.com",
				"ROBIN\@batcave.com"
			]
		}
		,
		{
			name		=>	"hash, no subkey",
			key			=>	"fasta_locations",
			subkey		=>	undef,
			expected	=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"scalar, subkey",
			key			=>	"test",
			subkey		=>	"TESTUSER",
			expected	=>	"testuser"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"data:aquarius-8",
			subkey		=>	"JBROWSEDATA",
			expected	=>	"/data/jbrowse/species"
		}
	];

	foreach my $test ( @$tests ) {

		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $subkey	=	$test->{subkey};
		my $value	=	$self->getKey($key, $subkey);
		my $expected=	$test->{expected};
		
		is_deeply($value, $expected, $name);
	}
}


method testSetKey {
	diag("#### setKey");
	
	my $inputfile	=	"$Bin/inputs/config.yaml";
	my $outputfile	=	"$Bin/outputs/setkey/config.yaml";
	my $logfile		=	"$Bin/outputs/setkey/setkey.log";	

	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->outputfile($outputfile);
	$self->logfile($logfile);
	$self->read($inputfile);
	$self->write($outputfile);

	my $tests	=	[
		{
			name		=>	"scalar, no subkey",
			key			=>	"username",
			subkey		=>	undef,
			value		=>	"nobody",
		}
		,
		{
			name		=>	"array, no subkey",
			key			=>	"error_emails",
			subkey		=>	undef,
			value		=>	[
				"HEMAN\@universe.com",
				"GREYSKULL\@universe.com"
			]
		}
		,
		{
			name		=>	"hash, no subkey",
			key			=>	"TEMP_FASTA",
			subkey		=>	undef,
			value		=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"scalar, subkey",
			key			=>	"test",
			subkey		=>	"TESTUSER",
			value		=>	"testuser"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"data:aquarius-8",
			subkey		=>	"JBROWSEDATA",
			value	=>	"/data/jbrowse/species"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"aws:info",
			subkey		=>	"AWS_USER_ID",
			value		=>	"1234567890"
		}
	];

	foreach my $test ( @$tests ) {
		$self->inputfile($outputfile);

		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $subkey	=	$test->{subkey};
		my $value	=	$test->{value};
		$self->setKey($key, $subkey, $value);

		my $expected=	$self->getKey($key, $subkey);
		
		is_deeply($value, $expected, "$name: $value");
	}
}

method testReadFromMemory {
	diag("#### readFromMemory");
	
	my $inputfile	=	"$Bin/inputs/config.yaml";
	my $expectedfile=	"$Bin/inputs/config.expected.yaml";
	my $logfile		=	"$Bin/outputs/memory/memory.log";	
	
	#### SET MEMORY
	$self->memory(1);
	
	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->logfile($logfile);
	$self->read($inputfile);
	
	#### INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");	

	my $tests	=	[
		{
			name		=>	"scalar, no subkey",
			key			=>	"username",
			subkey		=>	undef,
			expected	=>	"billy",
		}
		,
		{
			name		=>	"array, no subkey",
			key			=>	"error_emails",
			subkey		=>	undef,
			expected	=>	[
				"BATMAN\@batcave.com",
				"ROBIN\@batcave.com"
			]
		}
		,
		{
			name		=>	"hash, no subkey",
			key			=>	"fasta_locations",
			subkey		=>	undef,
			expected	=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"scalar, subkey",
			key			=>	"test",
			subkey		=>	"TESTUSER",
			expected	=>	"testuser"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"data:aquarius-8",
			subkey		=>	"JBROWSEDATA",
			expected	=>	"/data/jbrowse/species"
		}
	];

	foreach my $test ( @$tests ) {

		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $subkey	=	$test->{subkey};
		my $value	=	$self->getKey($key, $subkey);
		my $expected=	$test->{expected};
		
		is_deeply($value, $expected, $name);
	}

	#### MAKE SURE INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");
}

method testWriteToMemory {
	diag("#### writeToMemory");
	
	my $inputfile	=	"$Bin/inputs/config.yaml";
	my $expectedfile=	"$Bin/inputs/config.expected.yaml";
	my $outputfile	=	"$Bin/outputs/memory/config.yaml";
	my $logfile		=	"$Bin/outputs/memory/memory.log";
	$self->logDebug("outputfile", $outputfile);
	
	#### SET MEMORY
	$self->memory(1);
	
	#### LOAD SLOTS AND READ FILE	
	$self->inputfile($inputfile);
	$self->outputfile($outputfile);
	$self->logfile($logfile);
	$self->read($inputfile);

	#### MAKE SURE OUTPUT FILE NOT PRINTED
	$self->write($outputfile);
	my $found =	 -f $outputfile;
	$self->logDebug("found", $found);
	is_deeply($found, undef, "outputfile not printed");

	#### MAKE SURE INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");	
	
	my $tests	=	[
		{
			name		=>	"scalar, no subkey",
			key			=>	"username",
			subkey		=>	undef,
			value		=>	"nobody",
		}
		,
		{
			name		=>	"array, no subkey",
			key			=>	"error_emails",
			subkey		=>	undef,
			value		=>	[
				"HEMAN\@universe.com",
				"GREYSKULL\@universe.com"
			]
		}
		,
		{
			name		=>	"hash, no subkey",
			key			=>	"TEMP_FASTA",
			subkey		=>	undef,
			value		=>	{
				"NCBI37_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
				"NCBI37_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
				"NCBI36_XY" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
				"NCBI36_XX" => "/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
			}
		}
		,
		{
			name		=>	"scalar, subkey",
			key			=>	"test",
			subkey		=>	"TESTUSER",
			value		=>	"testuser"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"data:aquarius-8",
			subkey		=>	"JBROWSEDATA",
			value	=>	"/data/jbrowse/species"
		}
		,
		{
			name		=>	"scalar, subkey, splitkey",
			key			=>	"aws:info",
			subkey		=>	"AWS_USER_ID",
			value		=>	"1234567890"
		}
	];

	foreach my $test ( @$tests ) {
		my $name	=	$test->{name};
		my $key		=	$test->{key};
		my $subkey	=	$test->{subkey};
		my $value	=	$test->{value};
		$self->setKey($key, $subkey, $value);

		my $expected=	$self->getKey($key, $subkey);
		$self->logDebug("expected", $expected);
		
		is_deeply($value, $expected, "$name: $value");
	}

	#### MAKE SURE INPUT FILE UNCHANGED
	ok($self->diff($inputfile, $expectedfile), "inputfile unchanged");	
}


}