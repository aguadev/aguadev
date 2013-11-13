use MooseX::Declare;
use Method::Signatures::Simple;
=head2

	PACKAGE		Conf::JsonArray

    PURPOSE
    
        1. READ JSON ARRAY-FORMAT CONFIGURATION FILES (PRETTY FORMAT)

		2. ADD/EDIT/REMOVE ENTRIES
		
		3. WRITE TO OUTFILE PRESERVING ORDER OF KEYS
		
=cut


class Conf::JsonArray extends Conf::Json {

use Data::Dumper;
use JSON;

has 'backup' 	=>	(	is	=>	'rw',	isa	=>	'Bool', default	=>	0	);
has 'inputfile' =>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'assign' 	=>	(	is	=>	'rw',	isa	=>	'Undef|Str'	);
has 'outputfile' => (	is	=>	'rw',	isa	=>	'Str'	);
has 'ignore' 	=>	(	is	=>	'rw',	isa	=>	'Str',	default	=>	"#;\\[?"	);
has 'spacer' 	=>	(	is	=>	'rw',	isa	=>	'Str',	default	=>	"\\t=\\s"	);
has 'separator'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"="		);
has 'comment'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"#"		);
has 'sections'	=>	(	is 	=>	'rw', 	isa =>	'ArrayRef' );
has 'order'		=>	(	is 	=>	'rw', 	isa =>	'ArrayRef' );
has 'jsonparser'=>	(	is 	=>	'rw', 	isa =>	'JSON' );

####///}}} 
=head2

	SUBROUTINE 		read
	
	PURPOSE
	
		1. IF NO section IS PROVIDED, RETURN A HASH OF {section => {KEY-VALUE PAIRS}} PAIRS
		
		2. IF NO key IS PROVIDED, RETURN A HASH OF KEY-VALUE PAIRS FOR THE section
		
		3. RETURN THE KEY-VALUE PAIR FOR THE section AND key
		
		4. RETURN IF THE GIVEN section IS NOT IN THE ini FILE
		
		5. RETURN IF THE GIVEN key IS NOT IN THE ini FILE

=cut

method read ($inputfile) {
	$inputfile = $self->inputfile() if not defined $inputfile;
	$self->inputfile($inputfile) if defined $inputfile;
	$inputfile = $self->outputfile() if not defined $inputfile;
	#$self->logDebug("inputfile", $inputfile);
	
	return if not defined $inputfile;
	#$self->logDebug("inputfile ", $inputfile);
	
	#### SKIP READ IF DIRECTORY ABSENT
	my $sections = [];

	#### SKIP READ IF FILE ABSENT
	$self->logDebug("not -f $inputfile. Returning sections: ") if not -f $inputfile;
	return $sections if not -f $inputfile;

	#### PARSE JSON DATA
	$sections = $self->parseJson($inputfile);
	$self->logDebug("ref(\$sections): " . ref($sections));
	if ( not ref($sections) eq "ARRAY" ) {
		$self->logDebug("File does not appear to be a json array", $inputfile);
	}
	
	$self->logDebug("sections: ");
	$self->logDebug(sprintf Dumper $sections);

	$self->sections($sections);
	
	return $sections;
}

method write ($file) {
	#$self->logDebug("sections", $sections) if defined $sections;
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	
	#$self->logDebug("file", $file);
	my $sections = $self->_getSections();

	#### SANITY CHECK
	$self->logError("Conf::JsonArray::write    file not defined") if not defined $file;
	$self->logError("Conf::JsonArray::write    sections not defined") if not defined $sections;
	
	#### KEEP COPIES OF FILES IF backup DEFINED
	$self->makeBackup($file) if $self->backup();

	#### CREATE FILE DIR IF NOT EXISTS	
	my ($dir) = $file =~ /^(.+)\/([^\/]+)$/;
	File::Path::mkpath($dir) if not -d $dir;
	$self->logError("Conf::JsonArray::write    Can't create dir: $dir") if not -d $dir;

	#### GENERATE JSON WITH OPTIONAL ASSIGN
	my $jsonparser = $self->getJsonParser();
	my $output = $jsonparser->pretty->encode($sections);
	my $assign = $self->assign();
	$output = "$assign = $output" if defined $assign;
	$self->logDebug("output: ***$output***");

	#### PRINT TO FILE
	open(OUT, ">$file") or die "Conf::JsonArray::write    Can't open file: $file\n";
	print OUT $output;
	close(OUT) or die "Can't close file: $file\n";

	return 1;
};

method _getSections {
=head2

	SUBROUTINE 		_getSections
	
	PURPOSE
	
		RETURN ALL SECTIONS IN THE INPUTFILE
		
=cut
	return $self->sections() if defined $self->sections();
	my $sections = $self->read();
	$self->sections($sections);

	return $sections;
}

method getSection ($key, $value) {
	#$self->logDebug("");
	my $sections = $self->_getSections();
	$self->read(undef) if not defined $sections or not @$sections;
	return if not defined $sections;
	return $self->_getSection($key, $value, $sections);
}

method _getSection ($key, $value, $sections) {
=head2

	SUBROUTINE 		_getSection
	
	PURPOSE
	
		1. RETURN A SECTION GIVEN THE KEY-VALUE PAIR
		
=cut

	foreach my $section ( @$sections ) {
		return $section if $section->{$key} = $value;
	}
	
	return;
}

method _getSectionIndex ($key, $value) {
	#$self->logDebug("key", $key);
	my $sections = $self->_getSections();	
	#$self->logDebug("sections: ");
	#$self->logDebug(sprintf Dumper $sections);
	
	my $counter = 0;
	foreach my $section ( @$sections ) {
		return $counter if $section->{$key} = $value;
		$counter++;
	}

	return;
}

method insertKey ($key, $value, $targetkey, $targetvalue) {
	$self->logDebug("key", $key);
	$self->logDebug("value", $value);
	$self->logDebug("targetkey", $targetkey) if defined $targetkey;
	$self->logDebug("targetvalue", $targetvalue) if defined $targetvalue;

	#### GET SECTIONS
	$self->read(undef);
	my $sections = $self->_getSections();
	
	#### PREPARE INDEXES OF SECTIONS TO PROCESS
	my $indexes = [];
	if ( defined $targetkey and $targetvalue ) {
		push @$indexes, $self->_getKeyIndex($key, $value);
	}
	else {
		for ( my $i = 0; $i < @$sections; $i++ ) {
			push @$indexes, $i;
		}
	}
	
	#### PROCESS SECTIONS	
	for ( my $i = 0; $i < @$indexes; $i++ ) {
		$self->_insertKey($key, $value, $i);
	}

	$self->logObject("sections", $sections);

	#### WRITE TO FILE
	my $outputfile = $self->outputfile() || $self->inputfile();
	$self->write($outputfile);
}

method _insertKey ($key, $value, $index) {
    $self->logDebug("key", $key);
    $self->logDebug("value", $value);
    $self->logDebug("index", $index);
	my $sections = $self->_getSections();
	$$sections[$index]->{$key} = $value;
	$self->logDebug("BEFORE insert key-value: ");
	$self->logDebug(sprintf Dumper $sections);
	$self->sections($sections);
	$self->logDebug("AFTER insert key-value: ");
	$self->logDebug(sprintf Dumper $sections);
	
	return $sections;
}

method removeKey ($key, $value) {
	#### GET SECTIONS
	$self->read(undef);
	my $sections = $self->_getSections();
	
	#### PROCESS SECTIONS	
	foreach my $section ( @$sections ) {
		delete $section->{$key} if $section->{$key} == $value;
	}

	#### WRITE TO FILE
	my $outputfile = $self->outputfile() || $self->inputfile();
	$self->write($outputfile);
}

##################			HOUSEKEEPING SUBROUTINES			################
method getJsonParser {
	return $self->jsonparser() if defined $self->jsonparser();
	my $jsonparser = JSON->new();
	$self->jsonparser($jsonparser);

	return $self->jsonparser();
}

method parseJson ($inputfile) {
	my $contents = $self->fileContents($inputfile);

	#### SKIP TEXT IN skipAssign IF DEFINED
	my $assign = $self->assign();
	if ( defined $assign ) {
		$assign =~ s/\s+$//;
		$assign =~ s/^\s+//;
		$contents =~ s/$assign\s*=\s*//;
	}
    $self->logDebug("contents", $contents);

	my $parser = $self->getJsonParser();
	return $parser->decode($contents);
}

method fileContents ($filename) {
	open(FILE, $filename) or die "Can't open filename: $filename\n";
	my $oldsep = $/;
	$/ = undef;
	my $contents = <FILE>;
	close(FILE);
	$/ = $oldsep;
	
	return $contents;
}

method dump { 
	$self->logDebug("Doing StarCluster::dump(@_)");
    require Data::Dumper;
    $Data::Dumper::Maxdepth = shift if @_;
    print Data::Dumper::Dumper $self;
}


=head1 LICENCE

This code is released under the GPL, a copy of which should
be provided with the code.

=end pod

=cut



}
