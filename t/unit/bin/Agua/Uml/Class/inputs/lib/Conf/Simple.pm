use MooseX::Declare;

class Conf::Simple with (Conf, Agua::Common::Logger) {
=head2

	PACKAGE		ConfigFile

    PURPOSE
    
        1. READ AND WRITE ini-FORMAT CONFIGURATION FILES:
		
			[section name]
			KEY<SPACER>VALUE

			E.G.:

				[section name1]
				KEY1=VALUE1
				KEY2=VALUE2
	
				[section name2]
				KEY3=name2
				KEY4=VALUE3
	
=cut

use Data::Dumper;

# Ints
has 'valueoffset'		=>  ( isa => 'Int', is => 'rw', default => 24 );  

# Strings
has 'inputfile' =>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'outputfile' => (	is	=>	'rw',	isa	=>	'Str'	);
has 'ignore' 	=>	(	is	=>	'rw',	isa	=>	'Str',	default	=>	"#;\\[?"	);
has 'comment'	=>	(	is	=>	'rw',	isa	=> 	'Str',	default	=>	"#"		);
has 'spacer' 	=>	(	is	=>	'rw',	isa	=>	'Str',	default	=>	"\\s+"	);
has 'separator' 	=>	(	is	=>	'rw',	isa	=>	'Str'	);

# Objects
has 'sections'	=>	(	is 	=>	'rw', 	isa =>	'ArrayRef' );

####///}}}

sub getSeparator {
	my $self	=	shift;
	my $key		=	shift;
	
	return $self->separator() if defined $self->separator();
	
	my $separator = $self->valueoffset() - length($key);
	$separator = 4 if $separator < 4;

	return " " x $separator;
}

sub read {
=head2

	SUBROUTINE 		read
	
	PURPOSE
	
		1. IF NO section IS PROVIDED, RETURN A HASH OF {section => {KEY-VALUE PAIRS}} PAIRS
		
		2. IF NO key IS PROVIDED, RETURN A HASH OF KEY-VALUE PAIRS FOR THE section
		
		3. RETURN THE KEY-VALUE PAIR FOR THE section AND key
		
		4. RETURN IF THE GIVEN section IS NOT IN THE ini FILE
		
		5. RETURN IF THE GIVEN key IS NOT IN THE ini FILE

=cut
	my $self	=	shift;
	my $file	=	shift;
	$self->logNote("Conf::read(file, key, section)");
	$self->logNote("file", $file);
	
	$file = $self->inputfile() if not defined $file;
	$self->inputfile($file) if defined $file;
	$self->logNote("file after inputfile()", $file);
	
	$file = $self->outputfile() if not defined $file;
	$self->logNote("file after outputfile()", $file);
	return if not defined $file;
	#$self->logNote("file ", $file);
	
	#### SKIP READ IF FILE ABSENT
	my $sections = [];
	my ($dir) = $file =~ /^(.+)\/([^\/]+)$/;
	if ( not -d $dir )
	{
		$self->logNote("not -d $dir. Returning sections", $sections);
		return $sections;	
	}
	$self->logNote("not -f $file. Returning sections: ", $sections) if not -f $file;
	return $sections if not -f $file;

	#### GET FILE CONTENTS
	my $old = $/;
	$/ = undef;
	sleep(1);
	open(FILE, $file) or die "Conf::read    Can't open file: $file\n";
	my $contents = <FILE>;
	close(FILE) or die "Conf::read    Can't close file: $file\n";
	#$self->logNote("contents", $contents);

	#### PARSE LINES	
	my $counter = 0;
	my $lines;
	@$lines = split "\n", $contents;
	$self->logNote("number lines", scalar(@$lines));
	my $line_comment = '';
	for ( my $i = 0; $i < @$lines; $i++ )
	{
		$counter++;
		$self->logNote("Doing section $counter");
	
		my ($key, $value, $comment) = $self->parseline($$lines[$i]);
		#### STORE COMMENT IF PRESENT
		$line_comment .= "$comment\n" and next if defined $comment;

		#### ADD KEY-VALUE PAIR TO SECTION HASH
		if ( defined $key )
		{
			my $hash = {};
			$hash->{$key}->{value} = $value ;

			#### ADD COMMENT IF PRESENT
			$line_comment =~ s/\s+$//;
			$hash->{$key}->{comment} = $line_comment if $line_comment;
			$line_comment = '';

			push @$sections, $hash;
		}
	}
	$/ = $old;

	$self->logNote("sections", $sections);
	
	return $sections;
}

sub copy {
	my $self	=	shift;
	my $file	=	shift;

	$self->logNote("file", $file);
	$self->outputfile($file);
	$self->write();	
};

sub write {
	my $self	=	shift;
	my $sections=	shift;
	my $file	=	shift;

	$self->logNote("Conf::write(sections, file)");
	$self->logNote("file", $file);
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	

	#$self->logNote("BEFORE self->_getSections()");
	$sections = $self->_getSections() if not defined $sections;
	#$self->logNote("file", $file);
	#$self->logNote("sections", $sections);
	
	#### SANITY CHECK
	$self->logError("Conf::write    file not defined") if not defined $file;
	$self->logError("Conf::write    sections not defined") if not defined $sections;
	
	#### KEEP COPIES OF FILES IF backup DEFINED
	$self->makeBackup($file) if $self->backup();

	#### CREATE FILE DIR IF NOT EXISTS	
	my ($dir) = $file =~ /^(.+)\/([^\/]+)$/;
	File::Path::mkpath($dir) if not -d $dir;
	$self->logNote("Can't create dir", $dir) if not -d $dir;

	open(OUT, ">$file") or die "Conf::write    Can't open file: $file\n";
	foreach my $section ( @$sections )
	{
		my @keys = keys ( %{$section} );
		my $key = $keys[0];
		
		my $comment = $section->{$key}->{comment};
		my $value = $section->{$key}->{value};
		my $entry = '';
		$entry .= "\n" . $comment . "\n" if defined $comment;
		$entry .= $key . $self->getSeparator($key) . $value . "\n";
		$self->logNote("entry", $entry);
	
		print OUT $entry;
	}
	$self->logNote("finished printing file", $file);
	close(OUT) or die "Conf::write    Can't close file: $file\n";
};

sub parseline {
=head2

	SUBROUTINE 		parseline
	
	PURPOSE
	
		1. PARSE A KEY-VALUE PAIR FROM LINE
		
		2. RETURN A COMMENT AS A THIRD VALUE IF PRESENT

=cut

	my $self	=	shift;
	my $line 	=	shift;
	#$self->logNote("line", $line);
	
	my $ignore	=	$self->ignore();
	my $spacer	=	$self->spacer();
	#$self->logNote("ignore", $ignore);
	#$self->logNote("spacer", $spacer);

	#$self->logNote("ignoring line", $line) if $line =~ /^[$ignore]/;
	return (undef, undef, $line) if $line =~ /^[$ignore]+/;
	
	my ($key, $value) = $line =~ /^(.+?)[$spacer]+(.+)\s*$/;
	
	
	
	#### DEFINE VALUE AS '' FOR BOOLEAN key (I.E., ITS A FLAG)
	$value = '' if not defined $value;

	return ($key, $value);	
};

sub conf {
=head2

=head3 C<SUBROUTINE 		conf>
	
	PURPOSE
	
		RETURN A SIMPLE HASH OF CONFIG KEY-VALUE PAIRS

=cut

	my $self	=	shift;
	my $file	=	shift;
	
	$file = $self->inputfile() if not defined $file;
	return if not defined $file;
	
	$self->logNote("Conf::conf(file)");
	$self->logNote("file", $file);
	my $hash = {};
	open(FILE, $file) or die "Can't open file: $file\n";
	my @lines = <FILE>;
	close(FILE) or die "Can't close file: $file\n";
	foreach my $line ( @lines )
	{
		$self->logNote("line", $line);
		my ($key, $value) = $self->parseline($line);
		$self->logNote("$key\t=>\t$value");
	
		$hash->{$key} = $value if defined $key;
	}

	return $hash;
};


sub makeBackup {
=head2

	SUBROUTINE 		makeBackup
	
	PURPOSE
	
		COPY FILE TO NEXT NUMERICALLY-INCREMENTED BACKUP FILE

=cut
	my $self	=	shift;
	my $file	=	shift;
	
	$self->logError("Conf::makeBackup    file not defined") if not defined $file;
	
	#### BACKUP FSTAB FILE
	my $counter = 1;
	my $backupfile = "$file.$counter";
	while ( -f $backupfile )
	{
		$counter++;
		$backupfile = "$file.$counter";
	}
	$self->logNote("backupfile", $backupfile);

	require File::Copy;
	File::Copy::copy($file, $backupfile);
};

sub _getSections {
=head2

	SUBROUTINE 		_getSections
	
	PURPOSE
	
		RETURN ALL SECTIONS IN THE INPUTFILE
		
=cut

	my $self	=	shift;
	
	$self->logNote("Conf::_getSections()");
	return $self->sections() if defined $self->sections();
	$self->logNote("sections() not defined. Doing read()");
	my $sections = $self->read();
	$self->sections($sections);

	return $sections;
}

sub _getSection {
=head2

	SUBROUTINE 		_getSection
	
	PURPOSE
	
		1. RETURN A SECTION WITH THE GIVEN NAME (AND VALUE IF PROVIDED)
		
=cut

	my $self	=	shift;
	my $sections=	shift;
	my $name	=	shift;
	my $value	=	shift;
	$self->logNote("Conf::_getSection(sections, name, value)");
	$self->logNote("name", $name);
	
	#### SANITY CHECK
	$self->logError("Conf::_getSection    sections not defined") if not defined $sections;
	$self->logError("Conf::_getSection    name not defined") if not defined $name;

	#### SEARCH FOR SECTION AND ADD KEY-VALUE PAIR IF FOUND	
	foreach my $section ( @$sections )
	{
		next if not exists $section->{$name};
		return $section;
	}

	return {};
}

sub _addSection {
=head2

	SUBROUTINE 		_addSection
	
	PURPOSE
	
		1. ADD A SECTION
		
		2. ADD THE SECTION'S VALUE IF DEFINED
		
=cut

	my $self	=	shift;
	my $sections=	shift;
	my $key		=	shift;
	my $value	=	shift;
	my $comment	=	shift;
	$self->logNote("Conf::_addSection(section, key, value, comment)");
	$self->logNote("sections", $sections);
	$self->logNote("key", $key);
	$self->logNote("value", $value);
	$self->logNote("comment", $comment);

	#### SANTIY CHECK
	$self->logError("Conf::_addSection    sections not defined") if not defined $sections;
	$self->logError("Conf::_addSection    key not defined") if not defined $key;

	$value = '' if not defined $value;
	my $section;
	$section->{key} = $key;
	$section->{value} = $value;
	$section->{comment} = $comment;
	push @$sections, $section;

	return $section;
}


sub getKey {
	my $self	=	shift;
	my $key		=	shift;
	$self->logNote("Conf::getKey(key)");
	$self->logNote("key", $key);

	my $sections = $self->read();

	my $section = $self->_getSection($sections, $key);
	$self->logNote("section", $section);
	$self->logNote("key", $key);

	return $self->_getKey($section, $key);
}

sub _getKey {
=head2

	SUBROUTINE 		_getKey
	
	PURPOSE
	
		1. ADD A KEY-VALUE PAIR TO A SECTION
		
		2. RETAIN ANY EXISTING COMMENTS IF comment NOT DEFINED
		
		3. ADD COMMENTS IF comment DEFINED
		
=cut

	my $self	=	shift;
	my $section	=	shift;
	my $key		=	shift;
	$self->logNote("key", $key);
	$self->logNote("section", $section);

	#### SANITY CHECK
	$self->logError("Conf::_getKey    section not defined") if not defined $section;
	$self->logError("Conf::_getKey    key not defined") if not defined $key;

	return $section->{$key}->{value};
}

sub _sectionIsEmpty {
=head2

	SUBROUTINE 		_sectionIsEmpty
	
	PURPOSE
	
		1. RETURN 1 IF SECTION CONTAINS NO KEY-VALUE PAIRS
		
		2. OTHERWISE, RETURN 0
		
=cut

	my $self	=	shift;
	my $section =	shift;

	$self->logNote("Conf::_sectionIsEmpty(section)");
	$self->logNote("section", $section);
	
	#### SANITY CHECK
	$self->logError("Conf::_sectionIsEmpty    section not defined") if not defined $section;
	
	return 1 if not defined $section->{keypairs};
	my @keys = keys %{$section->{keypairs}};
	return 1 if not @keys;
	
	return 0;
}


sub _removeSection {
=head2

	SUBROUTINE 		_removeSection
	
	PURPOSE
	
		1. REMOVE A SECTION FROM THE CONFIG OBJECT
		
=cut

	my $self	=	shift;
	my $sections=	shift;
	my $section =	shift;

	$self->logNote("Conf::_removeSection(sections, section)");
	$self->logNote("sections", $sections);
	$self->logNote("section", $section);
	
	#### SANITY CHECK
	$self->logError("Conf::_removeSection    sections not defined") if not defined $sections;
	$self->logError("Conf::_removeSection    section not defined") if not defined $section;

	#### SEARCH FOR SECTION AND REMOVE IF FOUND	
	for ( my $i = 0; $i < @$sections; $i++ )
	{
		my $current_section = $$sections[$i];
		next if not $current_section->{key} eq $section->{key};
		next if defined $section->{value} and not $current_section->{value} eq $section->{value};
		splice(@$sections, $i, 1);
		return 1;
	}

	return 0;
}




sub setKey {
=head2

	SUBROUTINE 		setKey
	
	PURPOSE
	
		1. ADD A SECTION AND KEY-VALUE PAIR TO THE CONFIG
		
			FILE IF THE SECTION DOES NOT EXIST
		
		2. OTHERWISE, ADD A KEY-VALUE PAIR TO AN EXISTING SECTION

		3. REPLACE KEY ENTRY IF IT ALREADY EXISTS IN THE SECTION
		
=cut

	my $self	=	shift;
	my $key		=	shift;
	my $value	=	shift;
	my $comment	=	shift;
	$self->logNote("Conf::getKey(key)");
	$self->logNote("key", $key);
	$self->logNote("value", $value);
	$self->logNote("comment", $comment);

	#### SANITY CHECK
	$self->logError("Conf::setKey    key not defined") if not defined $key;

	#### SET VALUE TO '' IF UNDEFINED
	$value = '' if not defined $value;
	
	#### SEARCH FOR SECTION AND ADD KEY-VALUE PAIR IF FOUND	
	my $sections = $self->_getSections();
	#$self->logNote("sections", $sections);
	$self->logNote("sections length", scalar(@$sections));

	my $matched = 0;
	foreach my $current_section ( @$sections )
	{
		next if not exists $current_section->{$key};
		$matched = 1;
		$self->_setKey($current_section, $key, $value, $comment);
		last;
	}
	
	#### OTHERWISE, CREATE THE SECTION AND ADD THE 
	#### KEY-VALUE PAIR TO IT
	if ( not $matched )
	{
		$self->logNote("Creating section", $key);
		my $section = $self->_addSection($sections, $key, $value);
		$self->logNote("Added section", $section);
	}
	
	$self->logNote("sections length", scalar(@$sections));

	$self->write($sections);
}

sub _setKey {
=head2

	SUBROUTINE 		_setKey
	
	PURPOSE
	
		1. ADD A KEY-VALUE PAIR SECTION
		
		2. RETAIN ANY EXISTING COMMENTS IF comment NOT DEFINED
		
		3. ADD COMMENTS IF comment DEFINED
		
=cut
	my $self	=	shift;
	my $section	=	shift;
	my $key		=	shift;
	my $value	=	shift;
	my $comment =	shift;
	$self->logNote("Conf::_setKey(section, key, value)");
	$self->logNote("section", $section);
	$self->logNote("key", $key);
	$self->logNote("value", $value);

	#### SANITY CHECK
	$self->logError("Conf::_setKey    section not defined") if not defined $section;
	$self->logError("Conf::_setKey    key not defined") if not defined $key;
	$self->logError("Conf::_setKey    value not defined") if not defined $value;
	
	$section->{$key}->{value} = $value;
	$section->{$key}->{comment} = $comment if defined $comment;
}

sub removeKey {
=head2

	SUBROUTINE 		removeKey
	
	PURPOSE
	
		1. ADD A SECTION AND KEY-VALUE PAIR IF SECTION DOES NOT EXIST
		
		2. ADD A KEY-VALUE PAIR TO AN EXISTING SECTION

		3. REPLACE KEY ENTRY IF IT ALREADY EXISTS IN THE SECTION
		
=cut
	my $self		=	shift;
	my $section_keypair	=	shift;
	my $key			=	shift;
	$self->logNote("Conf::removeKey(section_keypair, key, value)");
	my ($section_name, $section_value) = $section_keypair =~ /^([^:]+):?(.*)$/;
	$self->logError("Conf::removeKey    section_name not defined") if not defined $section_name;
	$self->logError("Conf::removeKey    key not defined") if not defined $key;
	$self->logNote("Conf::setKey(section_keypair, key, value, comment)");

	$self->logNote("section_name: **$section_name**");
	$self->logNote("section_value", $section_value);
	$self->logNote("key", $key);
	
	#### SANITY CHECK
	$self->logError("Conf::removeKey    section_name not defined") if not defined $section_name;
	$self->logError("Conf::removeKey    key not defined") if not defined $key;

	#### SEARCH FOR SECTION AND ADD KEY-VALUE PAIR IF FOUND	
	my $sections = $self->read();
	my $matched = 0;
	my $removed_value;
	foreach my $current_section ( @$sections )
	{
		$self->logNote("current_section->{key}: **$current_section->{key}**");
		$self->logNote("current_section->{value}", $current_section->{value});
	
		next if not $current_section->{key} eq $section_name;
		$self->logNote("PASSED WITH KEY", $current_section->{key});

		$matched = 1;
		$self->logNote("matched", $matched);

		$removed_value = $self->_removeKey($current_section, $key);
		$self->logNote("_removeKey SUCCESS", $removed_value);
		return 0 if not $removed_value;
		
		#### REMOVE SECTION IF EMPTY
		if ( $self->_sectionIsEmpty($current_section) )
		{
			$self->logNote("section is empty");
			$self->_removeSection($sections, $current_section);
			$self->logNote("remove section removed_value", $removed_value);
			return 0 if not defined $removed_value;
		}
		last;
	}
	$self->logNote("Can't find section", $section_name) if not $matched;
	$self->logNote("OUT OF LOOP removed value", $removed_value);
	return 0 if not $matched;

	$self->write($sections);
	$self->logNote("Returning removed value", $removed_value);
	return $removed_value;
}

sub _removeKey {
=head2

	SUBROUTINE 		_removeKey
	
	PURPOSE
	
		1. REMOVE A KEY-VALUE PAIR FROM A SECTION
		
=cut

	my $self		=	shift;
	my $section		=	shift;
	my $key			=	shift;
	$self->logNote("Conf::_removeKey(section, key)");
	$self->logNote("key", $key);
	
	#### SANITY CHECK
	$self->logError("Conf::_removeKey    section not defined") if not defined $section;
	$self->logError("Conf::_removeKey    key not defined") if not defined $key;
	return 0 if not defined $section->{keypairs}->{$key};
	#return 0 if defined $value xor defined $section->{keypairs}->{$key}->{value};
	#return 0 if defined $value and $section->{keypairs}->{$key}->{value} ne $value;
	$self->logNote("section->{keypairs}->{$key}->{value}: ", $section->{keypairs}->{$key}->{value}, "");

	my $value = $section->{keypairs}->{$key}->{value};
	$self->logNote("value", $value);

	delete $section->{keypairs}->{$key};

	$self->logNote("key", $key);
	return $value;
}


##################			HOUSEKEEPING SUBROUTINES			################
sub dump { 
    my $self = shift;

	$self->logNote("Doing StarCluster::dump(@_)");
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

