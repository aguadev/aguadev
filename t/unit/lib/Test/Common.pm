package Test::Common;
use Moose::Role;

use Test::More;


sub getFileContents {
	my $self		=	shift;
	my $file		=	shift;
	
	open(FILE, $file) or print "Can't open file: $file\n" and exit;
	my $temp = $/;
	$/ = undef;
	my $contents = 	<FILE>;
	close(FILE);
	$/ = $temp;

	return $contents;
}

sub createDir {
	my $self		=	shift;
	my $directory	=	shift;

	#### CREATE OUTPUT DIRECTORY
	File::Path::mkpath($directory) if not -d $directory;
	print "Test::Common::createDir    Can't create directory: $directory\n" and return 0 if not -d $directory;

	return 1;	
}

sub getFiles {
	my $self		=	shift;
	my $directory	=	shift;
	#$self->logDebug("directory", $directory);

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

sub checkTsvLines {
	my $self		=	shift;
	my $table		=	shift;
	my $tsvfile		=	shift;
	my $message		=	shift;
	
	$message = "field values" if not defined $message;

	my $fields =	$self->db()->fields($table);
	#$self->logDebug("fields: @$fields");
	my $lines = $self->getLines($tsvfile);
	#$self->logDebug("no. lines", scalar(@$lines));
	$self->logWarning("file is empty: $tsvfile") and return if not defined $lines;
	
	foreach my $line ( @$lines ) {
		
		
		$line =~ s/\s+$//;
		my @elements = split "\t", $line;
		my $hash = {};
		for ( my $i = 0; $i < @$fields; $i++ ) {
			#$self->logDebug("elements[$i]", $elements[$i]);
			$hash->{$$fields[$i]} = $elements[$i];
			$hash->{$$fields[$i]} = '' if not defined $hash->{$$fields[$i]};
		}

		my $where = $self->db()->where($hash, $fields);
		
		#### FILTER BACKSLASHES
		$where =~ s/\\\\/\\/g;
		my $query = qq{SELECT 1 FROM $table $where};
		#$self->logDebug("query", $query);

		ok($self->db()->query($query), $message) or $self->logDebug($query) and exit;


	}	
}


1;