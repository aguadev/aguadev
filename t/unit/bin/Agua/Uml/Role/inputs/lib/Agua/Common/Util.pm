package Agua::Common::Util;
use Moose::Role;

=head2

	PACKAGE		Agua::Common::Util
	
	PURPOSE
	
		UTILITY METHODS FOR Agua::Common
		
=cut
#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../../";
use lib "$Bin/../../external";

#### ARRAYS
sub objectInArray {
	my $self	=	shift;
	
	return 1 if defined $self->_indexInArray(@_);
	
	return 0;
}

sub _indexInArray {
	my $self	=	shift;
	my $array	=	shift;
	my $object	=	shift;
	my $keys	=	shift;
	use Data::Dumper;
	#$self->logDebug("array", $array);
	#$self->logDebug("object", $object);

	return if not defined $array or not defined $object;
	
	for ( my $i = 0; $i < @$array; $i++ )
	{
		#$self->logDebug("array[$i]", $$array[$i]);

		my $identified = 1;
		#$self->logDebug("counter $i START identified", $identified);
		for ( my $j = 0; $j < @$keys; $j++ )
		{
			if ( not defined $object
				or not defined $object->{$$keys[$j]}
				or defined $$array[$i]->{$$keys[$j]} xor defined $object->{$$keys[$j]}
				or $$array[$i]->{$$keys[$j]} ne $object->{$$keys[$j]} ) {
				#$self->logDebug("not identified for key", $$keys[$j]);
				$identified = 0; 
			}
		}
		#$self->logDebug("counter $i END identified", $identified);
		#$self->logDebug("Returning $i")  if $identified;

		return $i if $identified;
	}
	
	return;
}


sub parseHash {
=head2

	SUBROUTINE		parseHash
	
	PURPOSE

		HASH INTO ARRAY OF TAB-SEPARATED KEY PAIRS

=cut

	my $self	=	shift;
	my $json	= 	shift;
	
	$self->logDebug("Workflow::parseHash(json)");
	$self->logDebug("json", $json);

	#### INITIATE JSON PARSER
	use JSON -support_by_pp; 
	my $jsonParser = JSON->new();

	my $outputs = [];
	
	if ( defined $json )
	{
		my $hash = $jsonParser->decode($json);
		my @keys = keys %$hash;
		@keys = sort @keys;

		foreach my $key ( @keys )
		{
			my $value = $hash->{$key}->{value};
			if ( defined $value and $value )
			{
				push @$outputs, "$key\t$value\n";	
			}
		}
	}

	return $outputs;
}

sub hasharrayToHash {
	my $self		=	shift;
	my $hasharray	=	shift;
	my $key			=	shift;
	
	$self->logError("hasharray not defined.") and exit if not defined $hasharray;
	$self->logError("key not defined.") and exit if not defined $key;

	my $hash = {};
	foreach my $entry ( @$hasharray )
	{
		my $key = $entry->{$key};
		if ( not exists $hash->{$key} )
		{
			$hash->{$key} = [ $entry ];
		}
		else
		{
			push @{$hash->{$key}}, $entry;
		}
	}

	return $hash;
}
#### DIRECTORIES
sub createDir {
    my $self    	=   shift;
    my $directory	=   shift;
	
	$self->logDebug("directory", $directory);
	`mkdir -p $directory`;
	$self->logError("Can't create directory: $directory") and exit if not -d $directory;
	
	return $directory;
}

sub getDirs {
	my $self		=	shift;
	my $directory	=	shift;
	$self->logDebug("directory", $directory);
	
	opendir(DIR, $directory) or $self->logError("Can't open directory: $directory") and exit;
	my $dirs;
	@$dirs = readdir(DIR);
	closedir(DIR) or die "Can't close directory: $directory";
	$self->logDebug("dirs", $dirs);
	
	for ( my $i = 0; $i < @$dirs; $i++ ) {
		if ( $$dirs[$i] =~ /^\.+$/ ) {
			splice @$dirs, $i, 1;
			$i--;
		}
		last if scalar(@$dirs) == 0;
		my $filepath = "$directory/$$dirs[$i]";
		if ( not -d $filepath ) {
			splice @$dirs, $i, 1;
			$i--;
		}
	}
	
	return $dirs;	
}

sub getFileDirs {
	my $self		=	shift;
	my $directory	=	shift;
	$self->logDebug("directory", $directory);
	
	my $filedirs;
	opendir(DIR, $directory) or $self->logError("Can't open directory: $directory") and exit;
	@$filedirs = readdir(DIR);
	closedir(DIR) or die "Can't close directory: $directory";
	
	for ( my $i = 0; $i < @$filedirs; $i++ ) {
		if ( $$filedirs[$i] =~ /^\.+$/ ) {
			splice @$filedirs, $i, 1;
			$i--;
		}
	}
	
	return $filedirs;	
}

sub getFiles {
	my $self		=	shift;
	my $directory	=	shift;
	$self->logDebug("directory", $directory);

	opendir(DIR, $directory) or $self->logDebug("Can't open directory", $directory);
	my $files;
	@$files = readdir(DIR);
	closedir(DIR) or $self->logDebug("Can't close directory", $directory);

	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] =~ /^\.+$/ ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	for ( my $i = 0; $i < @$files; $i++ ) {
		my $filepath = "$directory/$$files[$i]";
		if ( not -f $filepath ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	return $files;
}

sub createParentDir {
	my $self		=	shift;
	my $file		=	shift;
	
	#### CREATE DIR IF NOT PRESENT
	my ($directory) = $file =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("directory", $directory);
	`mkdir -p $directory` if $directory and not -d $directory;
	
	return -d $directory;
}

sub getFileContents {
	my $self		=	shift;
	my $file		=	shift;
	
	$self->logNote("file", $file);
	open(FILE, $file) or $self->logCritical("Can't open file: $file") and exit;
	my $temp = $/;
	$/ = undef;
	my $contents = 	<FILE>;
	close(FILE);
	$/ = $temp;

	return $contents;
}

#### LINE METHODS
sub getLines {
	my $self	=	shift;
	my $file	=	shift;
	$self->logDebug("file", $file);
	$self->logWarning("file not defined") and return if not defined $file;
	my $temp = $/;
	$/ = "\n";
	open(FILE, $file) or $self->logCritical("Can't open file: $file\n") and exit;
	my $lines;
	@$lines = <FILE>;
	close(FILE) or $self->logCritical("Can't close file: $file\n") and exit;
	$/ = $temp;
	
	for ( my $i = 0; $i < @$lines; $i++ ) {
		if ( $$lines[$i] =~ /^\s*$/ ) {
			splice @$lines, $i, 1;
			$i--;
		}
	}
	
	return $lines;
}

sub printToFile {
	my $self		=	shift;
	my $file		=	shift;
	my $text		=	shift;

	$self->createParentDir($file);
	
	#### PRINT TO FILE
	open(OUT, ">$file") or $self->logCaller() and $self->logCritical("Can't open file: $file") and exit;
	print OUT $text;
	close(OUT) or $self->logCaller() and $self->logCritical("Can't close file: $file") and exit;	
}

#### FILES
sub setPermissions {
	my $self		=	shift;
	my $username 	=	shift;
	my $filepath 	=	shift;
	
	#### SET OWNERSHIP
	my $apache_user = $self->conf()->getKey("agua", 'APACHEUSER');
	$self->logDebug("apache_user", $apache_user);
	my $chown = "chown -R $username:$apache_user $filepath &> /dev/null";
	$self->logDebug("chown", $chown);
	print `$chown`;

	#### SET PERMISSIONS
	my $chmod = "find $filepath -type d -exec chmod 0775 {} \\;;";
	$self->logDebug("chmod", $chmod);
	print `$chmod`;
	$chmod = "find $filepath -type f -exec chmod 0664 {} \\;;";
	$self->logDebug("chmod", $chmod);
	print `$chmod`;
}

sub incrementFile {
	my $self		=	shift;
	my $file		=	shift;
    $self->logDebug("file", $file);

	$file .= ".1";
	return $file if not -f $file and not -d $file;
	my $is_file = -f $file;
	
	if ( $is_file and $self->foundFile($file)
		or not $is_file and $self->foundDir($file) )
	{
		my ($stub, $index) = $file =~ /^(.+?)\.(\d+)$/;
		$index++;
		$file = $stub . "." . $index;
	}

    $self->logDebug("Returning file", $file);
    return $file;    
}

sub fileTail {
	my $self	=	shift;
	my $file	=	shift;
	my $text	=	shift;
	my $pause	=	shift;
	my $maxwait	=	shift;

	$pause = 1 if not defined $pause;
	$maxwait = 1 if not defined $maxwait;
	$self->logDebug("file", $file);
	$self->logDebug("text", $text);
	$self->logDebug("pause", $pause);
	$self->logDebug("maxwait", $maxwait);
	
	my $elapsed = 0;
	my $time = time();

	#### WAIT UNTIL FILE APPEARS
	while ( not -f $file ) {
		# SLEEP AND ELAPSED
		sleep($pause);
		$elapsed = time() - $time ;
		return 0 if $elapsed > $maxwait;
	}

	open(FILE, $file);
	my $curpos;
	for (;;) {
		for ( $curpos = tell(FILE); <FILE>; $curpos = tell(FILE) )
		{
			$self->logDebug("FOUND IN LINE: $_") if $_ =~ /$text/;
			return 1 if $_ =~ /$text/;
			$time = time();
		}

		# SLEEP AND ELAPSED
		sleep($pause);
		$elapsed = time() - $time ;
		return 0 if $elapsed > $maxwait;

		seek(FILE, $curpos, 0);  # SEEK BACK TO LAST POSITION
	}

	return 0;
}

#### I/O
sub captureStderr {
	my $self	=	shift;
	my $command	=	shift;
	$self->logDebug("command", $command);

	my $tempfile = "/tmp/$$.command.stderr";
	$self->logDebug("tempfile", $tempfile);
	`$command 2> $tempfile`;
	my $output = `cat $tempfile`;
	$self->logDebug("output", $output);
	`rm -fr $tempfile`;
	
	return $output;
}

#### VARIABLES
sub addEnvars {
	my $self		=	shift;
	my $string		=	shift;
	my $args = {
		project		=>	$self->project(),
		workflow	=>	$self->workflow(),
		username	=>	$self->username()
	};
	
	return $self->systemVariables($string, $args);
}

sub systemVariables {
#### INSERT OPTIONAL SYSTEM VARIABLES BRACKETED BY '%', E.G., %project%
	my $self		=	shift;
	my $string		=	shift;
	my $args		=	shift;
	$string =~ s/%project%/$args->{project}/g if defined $args->{project};
	$string =~ s/%workflow%/$args->{workflow}/g if defined $args->{workflow};
	$string =~ s/%username%/$args->{username}/g if defined $args->{username};

	$self->logDebug("returning string", $string);

	return $string;
}

#### TEXT
sub json_parser {
=head2

	SUBROUTINE		json_parser
	
	PURPOSE
	
		RETURN A JSON PARSER OBJECT
		
=cut

	my $self		= 	shift;
	
	return $self->jsonparser() if $self->can('jsonparser') and $self->jsonparser();
	
	use JSON -support_by_pp; 
	my $jsonparser = JSON->new();
	$self->jsonparser($jsonparser) if $self->can('jsonparser');

	return $jsonparser;
}


sub cowCase {
    my $self    	=   shift;
    my $string   	=   shift;
	
	return uc(substr($string, 0, 1)) . substr($string, 1);
}

sub collapsePath {
    my $self    	=   shift;
    my $string   	=   shift;
	while ($string =~ s/\/[^\/^\.]+\/\.\.// ) { }
	
	return $string;
}
#### DATETIME
sub datetime {
=head2

	SUBROUTINE		datetime
	
	PURPOSE

		RETURN THE CURRENT DATE AND TIME

=cut

	my $self	=	shift;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
	$sec = sprintf "%02d", $sec;
	$min = sprintf "%02d", $min;
	$hour = sprintf "%02d", $hour;
	$mday = sprintf "%02d", $mday;
	$mon = sprintf "%02d", $mon;
	$year -= 100;
	$year = sprintf "%02d", $year;
	my $datetime = "$year-$mon-$mday-$hour-$min-$sec";

	return $datetime;
}

#### UNTAINT
sub unTaint {
	my $self		=	shift;
	my $input		=	shift;
	
	$input =~ s/;.*$//g;
	$input =~ s/`.*$//g;
	
	return $input;
}


sub addHashes {
	my $self		=	shift;
	my $hash1		=	shift;
	my $hash2		=	shift;
	
	foreach my $key ( keys %$hash2 ) {
		$hash1->{$key}	=	$hash2->{$key};
	}
	
	return $hash1;
}


1;

=head2
sub fakeTermination {
	my $self		=	shift;
	my $sleep		=	shift;
	$sleep = 1 if not defined $sleep;
	
	#### SAVE OLD STDOUT & STDERR
	my $oldout;
	open $oldout, ">&STDOUT" or die "Can't open old STDOUT\n";
	my $olderr;
	open $olderr, ">&STDERR" or die "Can't open old STDERR\n";

	close(STDOUT);  
	close(STDERR);
	close(STDIN);
	sleep($sleep);

	##### RESTORE OLD STDOUT & STDERR
	open STDERR, ">&", $olderr;
	open STDOUT, ">&", $oldout;
}

=cut

