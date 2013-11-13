use MooseX::Declare;
use Method::Signatures::Simple;

=head2

	PACKAGE		Conf::Json

    PURPOSE
    
        1. READ JSON ARRAY-FORMAT CONFIGURATION FILES (PRETTY FORMAT)

		2. ADD/EDIT/REMOVE ENTRIES
		
		3. WRITE TO OUTFILE PRESERVING ORDER OF KEYS
		
=cut


class Conf::Json with (Conf, Agua::Common::Logger) {

use Data::Dumper;
use JSON;

has 'backup' 	=>	(	is	=>	'rw',	isa	=>	'Bool', default	=>	0	);
has 'inputfile' =>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'outputfile' => (	is	=>	'rw',	isa	=>	'Str|Undef'	);
has 'ignore' 	=>	(	is	=>	'rw',	isa	=>	'Str',	default	=>	"#;\\[?"	);
has 'spacer' 	=>	(	is	=>	'rw',	isa	=>	'Str',	default	=>	"\\t=\\s"	);
has 'separator'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"="		);
has 'comment'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"#"		);
has 'sections'	=>	(	is 	=>	'rw', 	isa =>	'ArrayRef|Undef' );
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
	$self->logNote("inputfile", $inputfile);
	
	return if not defined $inputfile;
	#$self->logDebug("inputfile ", $inputfile);
	
	#### SKIP READ IF DIRECTORY ABSENT
	my $sections = [];

	#### SKIP READ IF FILE ABSENT
	$self->logNote("not -f $inputfile. Returning sections: ") if not -f $inputfile;
	return $sections if not -f $inputfile;

	#### GET ORDER OF SECTIONS
	my $order = $self->getSectionOrder($inputfile);
	
	#### PARSE JSON DATA
	my $data = $self->parseJson($inputfile);
	
	#### SET SECTIONS
	foreach my $key ( @$order ) {
		push @$sections, {	$key	=>	$data->{$key} };
	}
	
	#print Dumper $sections;
	$self->sections($sections);
	
	return $sections;
}

method getSectionOrder ($inputfile) {
	#$self->logDebug("inputfile", $inputfile);
	my $contents = $self->fileContents($inputfile);
	#$self->logDebug("");
	my $lines;
	@$lines = split "\n", $contents;
	my $order = [];
	my $counter = 0;

	my $line;
	while ( $counter < scalar(@$lines) ) {
		$line = $$lines[$counter];
		$counter++;

		#$self->logDebug("IN WHILE LOOP line $counter", $line);

		#### IF LINE HAS A KEY, STORE IT AND PUSH A CLOSER
		if ( $line =~ /^\s*"([^".]+)"\s*:\s*(\{|\[)\s*$/ ) {
			#$self->logDebug("NESTED pushing to order: $1 IN line", $line);
			push @$order, $1;
			my $opener = $2;
			my $closer = "]";
			$closer = "}" if $opener eq "{";

			#### SKIP ANY SUBLEVELS
			($counter, $lines) = $self->skipSubLevels($counter, $lines, $closer);
		}
		elsif ( $line =~ /^\s*"([^".]+)"\s*:\s*/ ) {
			#$self->logDebug("SIMPLE pushing to order: $1 IN line", $line);
			push @$order, $1;
		}
	}
	$self->order($order);

	return $order;
}

method skipSubLevels ($counter, $lines, $closer ) {	
	
	#### KEEP STACK OF NESTED CLOSERS
	my $stack = [];
	push @$stack, $closer;

	my $line = '';
	$counter--;
	while ( defined $line and scalar(@$stack) ) {
		$counter++;
		$line = $$lines[$counter];
		#$self->logDebug("LOOKING FOR CLOSER '$closer' INSIDE line $counter", $line);

		if ( $line =~ /^\s*"[^".]+"\s*:\s*(\{|\[)\s*$/
			or $line =~ /^\s*(\{|\[)\s*$/ ) {
			my $newopener = $1;
			my $newcloser = "]";
			$newcloser = "}" if $newopener eq "{";
			push @$stack, $newcloser;
			$closer = $newcloser;
			#$self->logDebug("NEW CLOSER '$closer' IN line", $line);
			#$self->logDebug("NEW STACK: @$stack");
		}
		elsif ( $line =~ /$closer,?\s*$/ ) {
			my $popped = pop @$stack;
			$closer = $$stack[scalar(@$stack) - 1] if @$stack;
			$closer = "UNDEFINED" if not @$stack;
			#$self->logDebug("popped closer: '$popped' in line $counter", $line);
			#$self->logDebug("NEW STACK: @$stack");
		}
		elsif ( $line =~ /^\s*(\{|\[)\s*$/ ) {
			my $newopener = $1;
			my $newcloser = "]";
			$newcloser = "}" if $newopener eq "{";
			push @$stack, $newcloser;
			$closer = $newcloser;
			#$self->logDebug("NEW CLOSER '$closer' IN line", $line);
			#$self->logDebug("NEW STACK: @$stack");
		}
	}

	return ($counter, $lines)
}

method copy ($inputfile, $outputfile) {
	$self->logDebug("Conf::copy(file)");
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->read($inputfile);
	$self->write($outputfile);	
}

method write ($file) {
	$self->logNote("file", $file) if defined $file;
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	
	#$self->logNote("file", $file);
	my $sections = $self->_getSections();

	#### SANITY CHECK
	$self->logError("Conf::Json::write    file not defined") if not defined $file;
	$self->logError("Conf::Json::write    sections not defined") if not defined $sections;
	
	#### KEEP COPIES OF FILES IF backup DEFINED
	$self->makeBackup($file) if $self->backup();

	#### CREATE FILE DIR IF NOT EXISTS	
	my ($dir) = $file =~ /^(.+)\/([^\/]+)$/;
	File::Path::mkpath($dir) if not -d $dir;
	$self->logError("Conf::Json::write    Can't create dir: $dir") if not -d $dir;

	my $jsonparser = $self->getJsonParser();

	my $output = "{\n";
	foreach my $section ( @$sections )
	{
		my $json = $jsonparser->pretty->indent->encode($section);
		$json =~ s/^\{\n//;
		$json =~ s/\s+\}\n*$//s;
		$json .= ",\n";
		$output .= $json;
	}
	$output =~ s/,\n$/\n/;
	$output .= "}";
	#$self->logNote("output: ***$output***");
	open(OUT, ">$file") or die "Conf::Json::write    Can't open file: $file\n";
	print OUT $output;
	close(OUT) or die "Can't close file: $file\n";

	return 1;
};


method pretty ($file) {
	$self->logDebug("");
	$file = $self->inputfile() if not defined $file;
	my $contents = $self->fileContents($file);
	my $parser = $self->getJsonParser();
	my $object = $parser->decode($contents);
	my $json = $parser->pretty->indent->encode($object);
	$self->logDebug("json", $json);

	#### KEEP COPIES OF FILES IF backup DEFINED
	$self->makeBackup($file) if $self->backup();

	$self->toFile($file, $json);	
}

method unpretty ($file) {
	$file = $self->inputfile() if not defined $file;
	my $contents = $self->fileContents($file);
	my $parser = $self->getJsonParser();
	my $object = $parser->decode($contents);
	my $json = $parser->encode($object);

	#### KEEP COPIES OF FILES IF backup DEFINED
	$self->makeBackup($file) if $self->backup();

	$self->toFile($file, $json);	
}


method toFile ($file, $text) {
	$self->logDebug("file", $file);
	open(OUT, ">$file") or die "Can't open file: $file\n";
	print OUT $text;
	close(OUT) or die "Can't close file: $file\n";
}

method _getSections {
=head2

	SUBROUTINE 		_getSections
	
	PURPOSE
	
		RETURN ALL SECTIONS IN THE INPUTFILE
		
=cut
	return $self->sections() if defined $self->sections();
	my $sections = $self->read(undef);
	$self->sections($sections);

	return $sections;
}

method getKey ($key) {
	#$self->logDebug("");
	my $sections = $self->_getSections();
	$self->read(undef) if not defined $sections or not @$sections;
	return if not defined $sections;
	return $self->_getKey($key, $sections);
}

method _getKey ($key, $sections) {
=head2

	SUBROUTINE 		_getSection
	
	PURPOSE
	
		1. RETURN A SECTION WITH THE GIVEN KEY
		
=cut
	my $index = $self->_getKeyIndex($key, $sections);
	return if not defined $index;
	my $section = $$sections[$index];
	my @keys = keys %$section;
	my $section_key = $keys[0];
		
	return $section->{$section_key};
}


method getKeyIndex ($key) {
	#$self->logDebug("key", $key);
	my $sections = $self->_getSections();
	return $self->_getKeyIndex($key, $sections);
}

method _getKeyIndex ($key, $sections) {
	#$self->logDebug("key", $key);
	$sections = $self->_getSections() if not defined $sections;	
	#$self->logDebug("sections: ");
	#$self->logDebug(sprintf Dumper $sections);	
	return if not defined $sections;
	
	for ( my $i = 0; $i < @$sections; $i++ ) {
		my $section = $$sections[$i];
		my @keys = keys %$section;
		my $section_key = $keys[0];
		return $i if $section_key eq $key;
	}

	return;
}

method insertKey ($key, $value, $index) {
	#$self->logDebug("key", $key);
	#$self->logDebug("value", $value);
	#$self->logDebug("index", $index);
	$self->read(undef);
	my $sections = $self->_getSections();
	my $existingindex = $self->_getKeyIndex($key, $sections);
	#$self->logDebug("existingindex", $existingindex);	
	$index = $existingindex if not defined $index;
	
	### BY DEFAULT, PUT NEW KEY ENTRY AT TOP OF FILE
	$index = 0 if not defined $index;
	#$self->logDebug("index", $index);

	return if not defined $index;
	if ( defined $existingindex ) {
		$self->_removeKey($key, $existingindex, $sections);	
	}
	$self->_insertKey($key, $value, $index);
	my $outputfile = $self->outputfile() || $self->inputfile();
	$self->write($outputfile);
}

method _insertKey ($key, $value, $index) {
    #$self->logDebug("key", $key);
    #$self->logDebug("value", $value);
    #$self->logDebug("index", $index);
	my $sections = $self->_getSections();	
	$index = scalar(@$sections) if not defined $index;
	#$self->logDebug("BEFORE splice sections: ");
	#$self->logDebug(sprintf Dumper $sections);
    splice @{$sections}, $index, 0, { $key => $value };
	$self->sections($sections);
	#$self->logDebug("AFTER splice sections: ");
	#$self->logDebug(sprintf Dumper $sections);
	
	return $sections;
}

method removeKey ($key) {
	my $inputfile = $self->inputfile();
	$self->read($inputfile);
	my $sections = $self->_getSections();
	my $index = $self->_getKeyIndex($key, $sections);
	$self->_removeKey($key, $index, $sections);
	my $outputfile = $self->outputfile();
	$outputfile = $self->inputfile() if not defined $outputfile;
	$self->write($outputfile);
}

method _removeKey ($key, $index, $sections) {
	#$self->logDebug("key", $key);
	return if not defined $index;
	splice (@{$sections}, $index, 1);
	$self->sections($sections);
#
#	my $sections = $self->_getSections();	
#	my $currentindex = $self->_getKeyIndex($key, $sections);
#    splice (@{$sections}, $currentindex, 1) if defined $currentindex;
#	$index = $currentindex if not defined $index;

}

method hasKey ($key) {
	return $self->_getKeyIndex($key);	
	return 0;
}

##################			HOUSEKEEPING SUBROUTINES			################
method getJsonParser {
	return $self->jsonparser() if defined $self->jsonparser();
	my $jsonparser = JSON->new();
	$self->jsonparser($jsonparser);

	return $self->jsonparser();
}

method parseJson ($inputfile) {
	$self->logNote("inputfile", $inputfile);
	my $contents = $self->fileContents($inputfile);
	#$self->logDebug("contents", $contents);
	my $parser = $self->getJsonParser();
	return $parser->decode($contents);
}

method fileContents ($filename) {
	$self->logNote("filename", $filename);
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
