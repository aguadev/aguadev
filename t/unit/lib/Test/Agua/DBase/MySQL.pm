use MooseX::Declare;

class Test::Agua::DBase::MySQL extends Agua::DBase::MySQL {
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# Strings
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

use JSON;

#####/////}}}}}

method testFieldTypes {
	diag("# fieldTypes");
	
	my $tests = [
		{
			testname	=>	"success",
			sqlfile		=>	"$Bin/inputs/sql/sample.sql",
			jsonfile	=>	"$Bin/inputs/json/sampletypes.json"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $sqlfile		=	$test->{sqlfile};
		my $jsonfile	=	$test->{jsonfile};
		
		my $types		=	$self->fieldTypes($sqlfile);
		$self->logDebug("types", $types);

		my $jsonparser = JSON->new();
		my $json		=	$self->fileContents($test->{jsonfile});
		my $expected	=	$jsonparser->decode($json);
		$self->logDebug("expected", $expected);
	
		is_deeply($types, $expected, $test->{testname})
	}
}

method testFileFields {
	diag("# fileFields");

	my $tests = [
		{
			testname	=>	"success",
			sqlfile		=>	"$Bin/inputs/sql/sample.sql",
			jsonfile	=>	"$Bin/inputs/json/samplefields.json"
		}
	];

	foreach my $test ( @$tests ) {
		my $sqlfile			=	$test->{sqlfile};
		my $jsonfile		=	$test->{jsonfile};
		
		my $fields =	$self->fileFields($sqlfile);
		$self->logDebug("fields", $fields);
		
		my $jsonparser = JSON->new();
		my $json		=	$self->fileContents($test->{jsonfile});
		my $expected	=	$jsonparser->decode($json);
		$self->logDebug("expected", $expected);
	
		is_deeply($fields, $expected, $test->{testname})
	}
}

method testVerifyFieldType {
	diag("# verifyFieldType");
	
	my $tests = [
		{
			testname	=>	"all-valid",
			sqlfile		=>	"$Bin/inputs/sql/sample.sql",
			tsvfile		=>	"$Bin/inputs/tsv/sample-valid.tsv",
			validfile	=>	"$Bin/inputs/tsv/valid.tsv",
		}
		,
		{
			testname	=>	"some-invalid",
			sqlfile		=>	"$Bin/inputs/sql/sample.sql",
			tsvfile		=>	"$Bin/inputs/tsv/sample-invalid.tsv",
			validfile	=>	"$Bin/inputs/tsv/invalid.tsv",
		}
	];
	
	foreach my $test ( @$tests ) {
		my $sqlfile			=	$test->{sqlfile};
		my $tsvfile			=	$test->{tsvfile};
		my $validfile		=	$test->{validfile};
		
		my $types		=	$self->fieldTypes($sqlfile);
		#$self->logDebug("types", $types);
		
		my $fields		=	$self->fileFields($sqlfile);
		#$self->logDebug("fields", $fields);
		
		my $line = $self->fileContents($test->{tsvfile});
		my @values = split "\t", $line;
		#$self->logDebug("values", \@values);
		
		$line = $self->fileContents($test->{validfile});
		my @valids = split "\t", $line;

		my $wanted = [];
		
		for ( my $i = 0; $i < $#values + 1; $i++ ) {
			
			$self->logDebug("#### counter", $i);
			my $value =	 $values[$i];
			my $valid =	 $valids[$i];
			my $field =	 $$fields[$i];
			#$self->logDebug("value", $value);
			#$self->logDebug("valid", $valid);
			#$self->logDebug("field", $field);
			
			my $verified	=	$self->verifyFieldType($types, $field, $value);
			#$self->logDebug("verified", $verified);
			
			push @$wanted, $verified;
		}
		#$self->logDebug("\nwanted", $wanted);

		is_deeply(\@valids, $wanted, $test->{testname});
	}
}


}	####	Agua::Upload  
