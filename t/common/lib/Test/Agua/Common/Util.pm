package Test::Agua::Common::Util;
use Moose::Role;
use Method::Signatures::Simple;

use Test::More;
use Test::DatabaseRow;
use Data::Dumper;
use JSON;

has 'jsonparser'	=> ( isa => 'JSON', is => 'rw', lazy => 1, builder => "setJsonParser" );
has 'loaded'		=> ( isa => 'Int', is => 'rw', default	=> 0, required => 0 );

#### SETUP
method setUpDirs ($sourcedir, $targetdir) {
	$self->logCaller("");
	$self->logNote("sourcedir", $sourcedir);
	$self->logNote("targetdir", $targetdir);

	$self->logNote("rm -fr $targetdir");
	`rm -fr $targetdir`;
	$self->logNote("cp -r $sourcedir $targetdir");
	`cp -r $sourcedir $targetdir`;
	
	$self->logError("Can't find targetdir: $targetdir") and exit if not -d $targetdir;

	#### REDIRECT STDERR TO MASK 'No such file or directory' ERROR
	my $olderr;
	open $olderr, ">&STDERR";	
	open(STDERR, ">/dev/null") or die "Can't redirect STDERR to /dev/null\n";
	
	my $command = 	"cd $targetdir; find . -type d -exec chmod 0755 {} \\;; find . -type f -exec chmod 0644 {} \\;;";
	$self->logNote("command", $command);
	`$command`;
	
	#### RESTORE STDERR
	open STDERR, ">&", $olderr;
}

method setUpFile ($sourcefile, $targetfile) {
	#$self->logNote("") if $self->can('logNote');
	`cp $sourcefile $targetfile`;
	`chmod 644 $targetfile`;	
}


#### COMPARISON
method diff ($sourcefile, $targetfile) {
	$self->logNote("sourcefile not defined") and return 0 if not defined $sourcefile;
	$self->logNote("targetfile not defined") and return 0 if not defined $targetfile;
	$self->logNote("sourcefile not found") and return 0 if not -f $sourcefile;
	$self->logNote("targetfile not defined") and return 0 if not -f $targetfile;
	my $diff = `diff -wb $sourcefile $targetfile`;
	
	return 1 if $diff eq "";
	
	return 0;
}

method identicalArray ($actuals, $expecteds) {
	return 1 if not defined $actuals and not defined $expecteds;
	return 0 if defined $actuals xor defined $expecteds;
	return 0 if scalar(@$actuals) != scalar(@$expecteds);
	for ( my $i = 0; $i < @$actuals; $i++ ) {
		return 0 if $$actuals[$i] ne $$expecteds[$i];
	}

	$self->logNote("returning 1");
	return 1;
}

#### FILES
method listFiles ($directory) {
	opendir(DIR, $directory) or $self->logNote("Can't open directory", $directory);
	my $files;
	@$files = readdir(DIR);
	closedir(DIR) or $self->logNote("Can't close directory", $directory);

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

method printFile ($outfile, $contents) {
	$self->logError("outfile not defined") if not defined $outfile;

	open(OUT, ">$outfile") or die "Can't open outfile: $outfile\n";
	print OUT $contents;
	close(OUT);
}



#### CLEAR
method clear {
	#### GET ATTRIBUTES
	use Moose::Meta::Attribute;
	my $meta = __PACKAGE__->meta();
	my $attributes;
	@$attributes = $meta->get_attribute_list();
	$self->logDebug("attributes", $attributes);

	#### RESET TO DEFAULT OR CLEAR ALL ATTRIBUTES
	foreach my $attribute ( @$attributes ) {
		$self->logDebug("attribute", $attribute);
        next if $attribute eq "showlog";
        next if $attribute eq "printlog";
        next if $attribute eq "db";
        
		my $attr = $meta->get_attribute($attribute);
		#$self->logDebug("attr", $attr);
		my $options = $attr->original_options();
		$self->logDebug("options", $options);
	
		my $default	=	$attr->{default};
		$self->logDebug("default", $default);
		#my $required	=	$attr->{required};
		#$self->logDebug("required", $required);
		my $isa	=	$attr->{isa};
		$self->logDebug("isa", $isa);
		#my $is	=	$attr->{is};
		#$self->logDebug("is", $is);
		my $value	=	$self->$attribute();
		$self->logDebug("value", $value);

		my $ref = ref $default;
		$self->logDebug("ref", $ref);
		
		next if not defined $value;
		if ( not defined $default ) {
			#$self->logDebug("CLEARING NO-DEFAULT ATTRIBUTE $attribute: $isa value", $value);
			if ( $ref ne "CODE" ) {
				$self->$attribute();
			}
		}
		else {
			#$self->logDebug("SETTING VALUE TO DEFAULT", $default);
			if ( $ref ne "CODE" ) {
				#$self->logDebug("re ne 'CODE'. SETTING TO DEFAULT ATTRIBUTE $attribute: $isa value", $value);
				$self->$attribute($default);
			}
			else {
				#$self->logDebug("ref eq 'CODE'. SETTING TO DEFAULT CODE ATTRIBUTE $attribute: $isa value", $value);
				$self->$attribute(&$default);
			}
		}
		#$self->logNote("CLEARED $attribute ($isa)", $self->$attribute());
	}

	$self->loaded(0);
}


method initialise ($hash) {	
	$self->logDebug("hash", $hash);
	foreach my $key ( keys %$hash ) {
		$self->$key($hash->{$key}) if defined $hash->{$key} and $self->can($key);
	}
}


1;
