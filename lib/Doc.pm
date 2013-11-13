use MooseX::Declare;

=head2

PACKAGE     Doc

PURPOSE

    GENERATE WIKI MARKUP FROM PERLDOC FOR APPLICATIONS AND MODULES
    
INPUT

    1. SOURCE DIRECTORY LOCATION
    
    2. OUTPUT DIRECTORY LOCATION
    
    
OUTPUT

    ONE DOCUMENTATION FILE FOR EACH SOURCE FILE IN NESTED
    
    SUBDIRS MIRRORING THE SOURCE DIRECTORY

USAGE

sudo ./doc.pl <--inputdir String> <--outputdir String> [--help]

--name      :   Name of application

--inputdir   :	Name of inputdir where the .git directory is located

--outputdir :	Create packages inside RELEASE dir in the outputdir

--help      :   Print help info


EXAMPLES

./doc.pl \ 
 --inputdir /agua/0.6/bin \
 --outputdir /agua/0.6/docs/bin


=cut

#class Doc with Agua::Common {
class Doc with Agua::Common::Logger {

# Strings
has 'inputdir'  =>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'outputdir' =>  (	is	=>	'rw',	isa	=>	'Str'	);
has 'prefix' 	=>	(	is	=>	'rw',	isa	=>	'Str'   );

#### EXTERNAL MODULES
use File::Path;
use Getopt::Long;
use Data::Dumper;

####////}}}}


method docToJson ($inputdir, $outputdir, $prefix) {
    $self->logDebug("inputdir", $inputdir);
    $self->logDebug("outputdir", $outputdir);
    $self->logDebug("prefix", $prefix);

    #### DO FILES IN INPUT DIRECTORY
    $self->docToJsonFiles($inputdir, $outputdir, $prefix);    
    
    #### DO FILES IN SUBDIRECTORIES
    my $dirs = $self->getDirs($inputdir);
    $self->logDebug("dirs: @$dirs");
    
    #### 2. GET PERLDOC FOR EACH FILE IN SEPARATE SUBDIRS
    foreach my $dir ( @$dirs ) {
        my $files = $self->getFiles("$inputdir/$dir");
        $self->logDebug("files: @$files");
    
        $self->docToJsonFiles("$inputdir/$dir", "$outputdir/$dir", $prefix);
    }    	
}

method docToWikiFiles ($inputdir, $outputdir, $prefix) {
    $self->logDebug("inputdir", $inputdir);
    $self->logDebug("outputdir", $outputdir);
    $self->logDebug("prefix", $prefix);

    my $files = $self->getFiles($inputdir);
    $self->logDebug("files: @$files");

    $self->createDir($outputdir);

    foreach my $file ( @$files ) {
        my $docfile = $file;
        $docfile =~ s/\.pl$/.json/;
        
        my $command = "perldoc $inputdir/$prefix$file";
        $self->logDebug("$command");
        my $output = `$command`;

        $self->logDebug("BEFORE output: **$output**");

        #### REMOVE FIRST LINE
        $output =~ s/^[^\n]+\n//;        

        #### REMOVE LAST LINE
        $output =~ s/[^\n]+\n\s*$//;    

        #### HEADERS
        $output =~ s/^\s*APPLICATION\s+(\S+)/\nh3. APPLICATION\n\n$1\n\n/ms;
        $output =~ s/^\s+PACKAGE/\nh3. PACKAGE/ms;
        $output =~ s/^\s+PURPOSE/\nh3. PURPOSE/mg;
        $output =~ s/^\s+INPUT/\nh3. INPUT/msg;
        $output =~ s/^\s+OUTPUT/\nh3. OUTPUT/msg;
        $output =~ s/^\s+USAGE/\nh3. USAGE/msg;
        $output =~ s/^\s+EXAMPLE/\nh3. EXAMPLE/msg;

        #### EXCESS SPACE
        $output =~ s/\n\n/\n*/g;
        $output =~ s/^\*\s+/*/msg;
        $output =~ s/\*/\n/g;
        
        #### MULTI-LINE ARGUMENTS
        $output =~ s/^\s+--/ --/msg;

        #### CODE TAGS
        $output =~ s/USAGE\S*\n\s*(.+?)\s*h3. EXAMPLE/USAGE\n\n{code}\n$1\n{code}\n\nh3. EXAMPLE/msg;
        $output =~ s/EXAMPLE\s*\n\s*(.+)?(.+?[^\\])\s*$/EXAMPLE\n\n{code}\n$1\{code}\n\n/msg;


        $self->logDebug("AFTER output: **$output**");
    
        $self->printToFile("$outputdir/$docfile", $output);    
    }    
}

method docToWiki ($inputdir, $outputdir, $prefix) {
    $self->logDebug("inputdir", $inputdir);
    $self->logDebug("outputdir", $outputdir);
    $self->logDebug("prefix", $prefix);

    #### DO FILES IN INPUT DIRECTORY
    $self->docToWikiFiles($inputdir, $outputdir, $prefix);    
    
    #### DO FILES IN SUBDIRECTORIES
    my $dirs = $self->getDirs($inputdir);
    $self->logDebug("dirs: @$dirs");
    
    #### 2. GET PERLDOC FOR EACH FILE IN SEPARATE SUBDIRS
    foreach my $dir ( @$dirs ) {
        my $files = $self->getFiles("$inputdir/$dir");
        $self->logDebug("files: @$files");
    
        $self->docToWikiFiles("$inputdir/$dir", "$outputdir/$dir", $prefix);
    }    
}

method docToWikiFiles ($inputdir, $outputdir, $prefix) {
    $self->logDebug("inputdir", $inputdir);
    $self->logDebug("outputdir", $outputdir);
    $self->logDebug("prefix", $prefix);

    my $files = $self->getFiles($inputdir);
    $self->logDebug("files: @$files");

    $self->createDir($outputdir);

    foreach my $file ( @$files ) {
        my $docfile = $file;
        $docfile =~ s/\.pl$/.txt/;
        
        my $command = "perldoc $inputdir/$prefix$file";
        $self->logDebug("$command");
        my $output = `$command`;

        $self->logDebug("BEFORE output: **$output**");

        #### REMOVE FIRST LINE
        $output =~ s/^[^\n]+\n//;        

        #### REMOVE LAST LINE
        $output =~ s/[^\n]+\n\s*$//;    

        #### HEADERS
        $output =~ s/^\s*APPLICATION\s+(\S+)/\nh3. APPLICATION\n\n$1\n\n/ms;
        $output =~ s/^\s+PACKAGE/\nh3. PACKAGE/ms;
        $output =~ s/^\s+PURPOSE/\nh3. PURPOSE/mg;
        $output =~ s/^\s+INPUT/\nh3. INPUT/msg;
        $output =~ s/^\s+OUTPUT/\nh3. OUTPUT/msg;
        $output =~ s/^\s+USAGE/\nh3. USAGE/msg;
        $output =~ s/^\s+EXAMPLE/\nh3. EXAMPLE/msg;

        #### EXCESS SPACE
        $output =~ s/\n\n/\n*/g;
        $output =~ s/^\*\s+/*/msg;
        $output =~ s/\*/\n/g;
        
        #### MULTI-LINE ARGUMENTS
        $output =~ s/^\s+--/ --/msg;

        #### CODE TAGS
        $output =~ s/USAGE\S*\n\s*(.+?)\s*h3. EXAMPLE/USAGE\n\n{code}\n$1\n{code}\n\nh3. EXAMPLE/msg;
        $output =~ s/EXAMPLE\s*\n\s*(.+)?(.+?[^\\])\s*$/EXAMPLE\n\n{code}\n$1\{code}\n\n/msg;


        $self->logDebug("AFTER output: **$output**");
    
        $self->printToFile("$outputdir/$docfile", $output);    
    }
    
}

method listFiles ($inputdir) {
    my $files;
    opendir(DIR, $inputdir) or $self->logCaller() and $self->logCritical("Can't open bin directory: $inputdir") and exit;
    @$files = readdir(DIR);
    closedir(DIR) or $self->logCaller() and $self->logCritical("Can't close bin directory: $inputdir") and exit;

    return $files;
}

method getDirs ($inputdir) {
    $self->logDebug("inputdir", $inputdir);
	my $dirs = $self->listFiles($inputdir);
    $self->logDebug("dirs", $dirs);
	
    for ( my $i = 0; $i < @$dirs; $i++ ) {
		if ( $$dirs[$i] =~ /^\.+$/ ) {
			splice @$dirs, $i, 1;
			$i--;
		}
	}
    for ( my $i = 0; $i < @$dirs; $i++ ) {
        my $filepath = "$inputdir/$$dirs[$i]";
		$self->logDebug("filepath", $filepath);
        if ( -f $filepath or $$dirs[$i] =~ /^\.+$/ ) {
            splice @$dirs, $i, 1;
            $i--;
        }
    }
    @$dirs = sort @$dirs;

    return $dirs;    
}

method getFiles ($dir) {
    my $files = $self->listFiles($dir);

    for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] =~ /^\.+$/ ) {
			splice @$files, $i, 1;
			$i--;
		}
	}
    for ( my $i = 0; $i < @$files; $i++ ) {
		my $filepath = "$dir/$$files[$i]";
        if ( not -f $filepath
             or $$files[$i] =~ /^\.+$/
             or ( $$files[$i] !~ /\.pl$/ and $$files[$i] !~ /\.pm$/) ) {
            splice @$files, $i, 1;
            $i--;
        }
    }
    @$files = sort @$files;

    return $files;    
}


method createDir ($dir) {
    File::Path::mkpath($dir);
    $self->logCritical("Could not create dir: $dir") and exit if not -d $dir;
}

method printToFile ($file, $text) {
    open(FILE, ">$file") or die "Can't open file: $file\n";
    print FILE $text;    
    close(FILE) or die "Can't close file: $file\n";
}




}
