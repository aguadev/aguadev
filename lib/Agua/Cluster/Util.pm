package Agua::Cluster::Util;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Data::Dumper;
use File::Path;
#use lib "..";

=head2

	SUBROUTINE		unzipFiles
	
	PURPOSE

		UNZIP FILES, FILTERING BY STRING MATCH OR REGEX
		
=cut
sub unzipFiles {
	my $self		=	shift;
	$self->logDebug("");

	my $args		=	shift;
	my $type 		=	$args->{type};
	my $inputdir 	=	$args->{inputdir};
	my $outputdir 	=	$args->{outputdir};
	my $filter 		=	$args->{filter};
	my $regex 		=	$args->{regex};
	my $delete 		=	$args->{delete};
	
	#### CREATE OUTPUT DIRECTORY IF NOT EXISTS
	File::Path::mkpath($outputdir) if not -d $outputdir;
	die "Can't create output directory: $outputdir" if not -d $outputdir;
	
	#### GET FILES
	$self->logDebug("inputdir", $inputdir);
	opendir(DIR, $inputdir) or die "Can't open inputdir: $inputdir\n";
	my @files = readdir(DIR);
	closedir(DIR) or die "Can't close inputdir: $inputdir\n";
	$self->logDebug("files", \@files);

	#### CHANGE TO OUTPUT DIRECTORY
	chdir($outputdir) or die "Can't change to download directory: $outputdir\n";
	foreach my $file ( @files )
	{
		next if defined $regex and not $file =~ /$regex/;
		next if defined $filter and not $file =~ /\Q$filter\E/;
		$self->logDebug("unzipping file", $file);

		$self->unzip("$inputdir/$file", $outputdir, $delete) if $type eq "unzip";
		my $outfile = $file;
		$outfile =~ s/\.gz$//;
		$self->gunzip("$inputdir/$file", "$outputdir/$outfile", $delete) if $type eq "gunzip";
	}
}

sub gunzip {
	my $self		=	shift;
	my $inputfile	=	shift;
	my $outputfile	=	shift;
	my $delete		=	shift;
	$self->logDebug("inputfile", $inputfile);
	
	my $command = "gunzip -f -c $inputfile > $outputfile";
	$self->logDebug("command", $command);
	`$command`;
	`rm -fr $inputfile` if defined $delete;
}

sub unzip {
	my $self		=	shift;
	my $inputfile	=	shift;
	my $outputdir	=	shift;
	my $delete		=	shift;
	$self->logDebug("inputfile", $inputfile);
	
	my $command = "unzip $inputfile -d $outputdir";
	$self->logDebug("command", $command);
	`$command`;
	`rm -fr $inputfile` if defined $delete;
}

=head2

	SUBROUTINE		createReferenceDirs
	
	PURPOSE

		CREATE REFERENCE SUB-DIRECTORIES, ONE FOR EACH
		
		CHROMOSOME INSIDE THE TOP LEVEL DIRECTORY. EACH
		
		REFERENCE SUB-DIRECTORY CONTAINS A LINKED COPY
		
		OF THE CORRESPONDING CHROMOSOME IN THE TOP LEVEL
		
		DIRECTORY
		
=cut
sub createReferenceDirs {
	my $self		=	shift;
	my $source		=	shift;
	my $target		=	shift;
	my $regex		=	shift;
	$regex = "\\.fa\$" if not defined $regex;

	opendir(DIR, $source) or die "Can't open source: $source\n";
	my @reffiles = readdir(DIR);
	closedir(DIR) or die "Can't close source: $source\n";

	foreach my $reffile ( @reffiles )
	{
		next if not $reffile =~ /$regex/;
		my $chromosome = $reffile;
		$chromosome =~ s/(chr[A-Z0-9]+).*$/$1/i;
		my $dirpath = "$target/$chromosome";
		File::Path::mkpath($dirpath);
		$self->logDebug("Can't create dirpath", $dirpath) and die if not -d $dirpath;
		
		my $link = "ln -s $source/$reffile $dirpath/$reffile";
		$self->logDebug("$link");
		print `$link`;
	}
}

=head2

	SUBROUTINE		loop
	
	PURPOSE

        CONVERT AN ARGUMENT OF THE FORM "1-3,five,six" INTO
		
		AN ARRAY OF THE FORM [1,2,3,"five","six"]

=cut
sub stringToArray {
	my $self	=	shift;
	my $string	=	shift;
	
	my $array;
	if ( $string =~ /^(\d+)\-(\d+)$/ )
	{
		my $start = $1;
		my $end = $2;
		for my $time ( $start .. $end )
		{
			push @$array, $time;
		}
	}
	else
	{
		@$array = split ",", $string;

		for ( my $i = 0; $i < @$array; $i++ )
		{
			my $replicate = $$array[$i];
			if ( $replicate =~ /^(\d+)\-(\d+)$/ )
			{
				splice @$array, $i, 1;
				$i--;
				my $start = $1;
				my $end = $2;
				for my $time ( $start .. $end )
				{
					push @$array, $time;
					$i++;
				}
			}
		}
	}

	return $array;
}

=head2

	SUBROUTINE     chromosomeSizes
	    
    PURPOSE
  
        CALCULATE CHROMOSOME SIZES AND PRINT TO FILE

    INPUT

        1. FULL PATH TO DIRECTORY CONTAINING FASTA FILES

		2. [optional] REFERENCE FILE SUFFIX (DEFAULT = .fa)

    OUTPUT
    
        1. OUTPUT FILE IN INPUT DIRECTORY: chromosome-sizes.txt 
		
		2. FILE CONTAINS THESE COLUMNS: 
        
            chromosome  start   stop    length

=cut

sub chromosomeSizes {
	my $self		=	shift;
	my $directory	=	shift;
	my $suffix		=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logDebug("directory not defined", $directory) if not defined $directory or not $directory;
	$self->logDebug("directory is ''", $directory) if not defined $directory;
	$self->logDebug("Can't find directory", $directory) if not -d $directory;
	
	#### GET REFERENCE FASTA FILES	
	$suffix = "*.fa" if not defined $suffix;
	my $files = $self->listFiles($directory, $suffix);

	#### SORT FILES BY NUMBER
	@$files = Util::sort_naturally(\@$files);
	#### CHDIR TO OUTPUT DIRECTORY
	chdir($directory) or die "Could not CHDIR to directory: $directory\n";

	#### OPEN OUTPUT FILE
	my $outputfile = "$directory/chromosome-sizes.txt";
	open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
	
	#### GO THROUGH FASTA FILES
	my $file_sizes;
	my $start = 0;
	my $stop = 0;
	foreach my $file ( @$files )
	{
		if ( not -f $file )
		{
			$self->logError("File not found", $directory/$file);
			exit;
		}
	
		open(FILE, $file);
		$/ = "END OF FILE";
		my $contents = <FILE>;
		close(FILE);
		my $total_length = length($contents);
		my $header = `grep ">" $file`;
		$header =~ s/\s+$//;
		my $header_length = length($header);
		$header =~ s/^>//;
		$total_length = $total_length - $header_length;
		#### SET stop
		$stop = $start + $total_length;
	
		#### PRINT TO OUTFILE    
		print OUTFILE "$header\t$start\t$stop\t$total_length\n";
		$self->logDebug("$header\t$start\t$stop\t$total_length");
	
		#### SET start
		$start = $stop + 1;
	}
	
	#### CLOSE OUTPUT FILE AND REPORT
	close(OUTFILE);
	$self->logDebug("Output file printed:\n\n$outputfile\n");
}


=head2

	SUBROUTINE		getFilenames
	
	PURPOSE
	
		RETURN AN ARRAY OF FILE NAMES GIVEN THEIR FULL PATHS

=cut
sub getFilenames {
	my $self		=	shift;
	my $filepaths	=	shift;
	my $filenames = [];
	foreach my $filepath ( @$filepaths )
	{
		my ($filename) = $filepath =~ /^.+?\/([^\/]+)$/;
		push @$filenames, $filename if defined $filename;
		$self->logDebug("filename not defined for filepath", $filepath) if not defined $filename;
	}

	return $filenames;	
}

=head2

	SUBROUTINE		subfiles
	
	PURPOSE
	
		RETURN AN ARRAY OF SAM FILES GENERATED BY TOPHAT ALIGNMENT 
		
		BASED ON THE OUTPUT DIRECTORY, REFERENCE AND SPLIT FILES

=cut

sub subfiles {
	my $self		=	shift;
	my $outputdir	=	shift;
	my $reference	=	shift;
	my $splitfiles	=	shift;
	my $filename	=	shift;
	$self->logDebug("(outputdir, reference, splitfiles, filename)");
	$self->logDebug("reference", $reference);
	$self->logDebug("filename", $filename)  if defined $filename;
	#### USE TOPHAT accepted_hits.sam AS DEFAULT
	$filename = "accepted_hits.sam" if not defined $filename;
	my $subfiles = [];
	foreach my $splitfile ( @$splitfiles )
	{
		##### GET SPLITFILE NUMBER
		my ($splitnumber) = $$splitfile[0] =~ /(\d+)\/[^\/]+$/;	

		##### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
		my $outdir = "$outputdir/$reference/$splitnumber";
		
		#### NAME OUTPUT DIR AFTER REFERENCE FILE
		my $samfile = "$outdir/$filename";
		push @$subfiles, $samfile;
	}
	
	return $subfiles;
}


=head2
	
	SUBROUTINE		listReferenceSubdirs
	
	PURPOSE
	
		RETURN A LIST OF SUBDIRS GIVEN A PARENT DIRECTORY
	
=cut

sub listReferenceSubdirs {
	my $self			=	shift;
	my $referencedir	=	shift;
	$self->logDebug("referencedir", $referencedir);
	
	$self->logCritical("referencedir not defined") and exit if not defined $referencedir;

	#### GET SUBDIRS
	chdir($referencedir) or die "Can't change to reference directory: $referencedir\n";
	my $subdirs = Util::directories($referencedir);
	$self->logCritical("Quitting because no subdirs found in directory: $referencedir") and exit if scalar(@$subdirs) == 0;
	
	for ( my $i = 0; $i < @$subdirs; $i++ )
	{
		if ( $$subdirs[$i] !~ /^chr/ )
		{
			splice(@$subdirs, $i, 1);
			$i--;
		}
	}
	
	#### SORT SUBDIRS BY NUMBER
	@$subdirs = Util::sort_naturally(\@$subdirs);
	#### REVERSE SUBDIRS, SO THAT SMALLEST CHROMOSOMES ARE FIRST
	@$subdirs = reverse @$subdirs;
	return $subdirs;
}

=head2
	
	SUBROUTINE		listReferenceFiles
	
	PURPOSE
	
		RETURN A LIST OF FILES IN A DIRECTORY CORRESPONDING
		
		TO THE SUPPLIED PATTERN
	
=cut

sub listReferenceFiles {
	my $self			=	shift;
	return $self->listFiles( @_ );
}

=head2
	
	SUBROUTINE		listFiles
	
	PURPOSE
	
		RETURN A LIST OF FILES IN A DIRECTORY CORRESPONDING
		
		TO THE SUPPLIED PATTERN
	
=cut

sub listFiles {
	my $self		=	shift;
	my $directory	=	shift;
	my $pattern		=	shift;
	$self->logDebug("Agua::Cluster::listFiles(directory, pattern)");
	$self->logDebug("directory", $directory);
	$self->logDebug("pattern", $pattern);

	#### CHECK INPUTS
	$self->logCritical("directory not defined") and exit if not defined $directory;
	$self->logCritical("pattern not defined") and exit if not defined $pattern;

	#### GET REFERENCE FILES
	chdir($directory) or die "Can't change to reference directory: $directory\n";
	my $files;
	$self->logDebug("getting files <$directory/$pattern");
	@$files = <$directory/$pattern>;
	$self->logDebug("files: @$files");
	return if not defined $files;
	
	#### RETURN EMPTY ARRAY IF NO FILES
	$self->logDebug("No files found in directory", $directory) if scalar(@$files) == 0;
	return [] if scalar(@$files) == 0;
	
	#### SORT BY NUMBER
	$files = Util::sort_naturally($files);

	return $files;
}



=head2

	SUBROUTINE		checkFiles
	
	PURPOSE
	
		CHECK INPUT FILES ARE ACCESSIBLE AND NON-EMPTY

=cut

sub checkFiles {
	my $self		=	shift;
	my $files		=	shift;

	#### SANITY CHECK
	foreach my $file ( @$files )
	{
		if ( not -f $file )
		{
			$self->logError("Can't find file", $file);
			exit;
		}
		if ( -z $file )
		{
			$self->logError("File is empty", $file);
			exit;
		}
	}
}


=head2

	SUBROUTINE		splitfileChunks
	
	PURPOSE
	
		LIMIT INPUT FILES TO SPECIFIED CHUNKS OF THE SPLIT FILE LIST
		
=cut

sub splitfileChunks {
	my $self		=	shift;	
	my $splitfiles	=	shift;
	my $chunks		=	shift;
	$self->logDebug("Agua::Cluster::splitfileChunks(splitfiles, chunks)");
	$self->logDebug("chunks", $chunks);

	my $new_splitfiles = [];
	my @groups = split ",", $chunks;
	foreach my $groupstring ( @groups )
	{
		if ( $groupstring =~ /^(\d+)$/ )
		{
			push @$new_splitfiles, $$splitfiles[$1 - 1];
		}
		elsif ( $groupstring =~ /^(\d+)\-(\d+)$/ )
		{
			for my $index ( $1..$2 )
			{
				push @$new_splitfiles, $$splitfiles[$index - 1];
			}
		}
	}
	$self->logDebug("new_splitfiles", $new_splitfiles);

	return $new_splitfiles;
}







=head2


	SUBROUTINE		splitfiles
	
	PURPOSE

		1. RETURN THE LIST OF SPLITFILE PATHS
	
=cut

sub getSplitfiles {
	my $self		=	shift;
	my $splitfile	=	shift;
	$self->logDebug("Agua::Cluster::splitfiles(splitfile)");
	$self->logDebug("splitfile not defined")  and exit if not defined $splitfile;
	
	
	$self->logDebug("splitfile", $splitfile);
	
	
	return $self->splitfiles() if defined $self->splitfiles();

	return Sampler::splitfiles($splitfile);
}



=head2


	SUBROUTINE		doSplitfiles
	
	PURPOSE

		1. SPLIT UP THE INPUT FILES INTO SMALLER 'SPLIT FILES' 
		
			CONTAINING A USER-SPECIFIED NUMBER OF READS
	
		2. RETURN THE LIST OF SPLITFILE PATHS
	
=cut

sub doSplitfiles {
	my $self		=	shift;
	my $splitfile	=	shift;
	my $label		=	shift;
	my $inputfiles	=	shift;
	my $matefiles	=	shift;
	my $outputdir	=	shift;
	my $maxlines	=	shift;
	my $clean		=	shift;
	$self->logDebug("Agua::Cluster::doSplitfiles(splitfile, label)");
	
	#### CHECK label IS DEFINED (REQUIRED FOR LATER FINDING SPLITFILES BY NUMBER AND LABEL)
	$self->logCritical("label not defined. Exiting") and exit if not defined $label;
	$self->logCritical("splitfile not defined. Exiting") and exit if not defined $splitfile;

	#### FILES AND DIRS	
	$outputdir 		=	$self->outputdir() if not defined $outputdir;
	$inputfiles 		=	$self->inputfiles() if not defined $inputfiles;
	$matefiles 		=	$self->matefiles() if not defined $matefiles;

	#### SPLIT FILES
	$maxlines 		=	$self->maxlines() if not defined $maxlines;
	$clean 			=	$self->clean() if not defined $clean;

	#### SET SUFFIX FOR Sampler::splitFiles
	#### (SUFFIX OF LAST COMMA-SEPARATED INPUT FILE)
	my ($suffix) = $self->fileSuffix($inputfiles);
	my $splitfiles;
	if ( (defined $clean and $clean) or not -f $splitfile or -z $splitfile )
	{
		$self->logDebug("Generating split files...");
		$splitfiles = Sampler::splitFiles(
			{
				'inputfiles' 	=> 	$inputfiles,
				'matefiles' 	=> 	$matefiles,
				'lines'			=> 	$maxlines,
				'splitfile'		=>	$splitfile,
				'outputdir'		=>	$outputdir,
				'label'			=>	$label,
				'suffix'		=> 	$suffix
			}
		);	
		$self->logDebug("Names file printed", $splitfile);
	}
	else
	{
		$self->logDebug("Getting splitfiles hash from splitfile", $splitfile);
		$splitfiles = Sampler::get_splitfiles($splitfile);
	}

	$self->{splitfiles} = $splitfiles;
	
	#### SANITY CHECK
	$self->logCritical("No splitfiles. Exiting") and exit if not defined $splitfiles or scalar(@$splitfiles) == 0;
	
	return $splitfiles;	
}


sub copySplitfiles {
	my $self		=	shift;
	my $source	=	shift;
	my $target	=	shift;
	my $mode	=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logCritical("source not defined: $source") and exit if not defined $source;
	$self->logCritical("target not defined: $target") and exit if not defined $target;
	$self->logCritical("Can't find source: $source") and exit if not -d $source;
	
	#### CREATE TARGET DIR
	File::Path::mkpath($target) if not -d $target;
	
	#### SET TARGET NAME TO SECOND FROM TOP DIRECTORY
	my ($targetname) = $target =~ /([^\/]+)\/[^\/]+$/;
	#### CHDIR TO OUTPUT DIRECTORY
	chdir($source) or die "Could not CHDIR to source: $source\n";

	my $targetpath = $target;
	File::Path::mkpath($targetpath);
	$self->logDebug("Can't make targetpath", $targetpath) if not -d $targetpath;

	#### FORMAT:
	#### 0       0       /scratch/syoung/base/pipeline/SRA/NA18507/SRP000239/sampled/200bp/chr22/bowtie/1/1/bowtie-1_1.1.txt
	my $sourcesplitfile = "$source/splitfile.txt";
	my $targetsplitfile = "$target/splitfile.txt";
	open(OUT, ">$targetsplitfile") or die "Can't open targetsplitfile: $targetsplitfile\n";
	open(FILE,$sourcesplitfile) or die "Can't open sourcesplitfile: $sourcesplitfile\n";
	my @lines = <FILE>;
	close(FILE);
	foreach my $line ( @lines )
	{
		next if $line =~ /^\s*$/;
		my ($pairinfo, $sourcepath, $number, $sourcename, $suffix) = $line =~ /^(\d+\s+\d+\s+)(\S+\D+)(\d+)\/([^\/]+)(-\d+_\d+.\d+.txt)$/;
		File::Path::mkpath("$targetpath/$number");
		$self->logCritical("Exiting because can't make targetpath: $targetpath") and exit if not -d $targetpath;

		my $sourcefile = "$sourcepath$number/$sourcename$suffix";
		my $targetfile = "$targetpath/$number/$targetname$suffix";
		my $targetline = "$pairinfo$targetfile";
		print OUT $targetline, "\n";
		
		#### COPY OR LINK
		if ( $mode eq "copy" )
		{
			my $command = "cp -f $sourcefile $targetfile";
			`$command`;
		}
		elsif ( $mode eq "link" )
		{
			my $command = "rm -fr $targetfile; ln -s $sourcefile $targetfile";
			`$command`;
		}
		else
		{
			$self->logError("mode not supported", $mode);
			exit;
		}
	}

	close(OUT) or die "Can't close targetsplitfile: $targetsplitfile\n";
}


=head2

	SUBROUTINE		fileSuffix
	
	PURPOSE

		1. RETURN THE 1 TO 5-LETTER SUFFIX OF A FILE IF EXISTS
	
		2. RETURN SUFFIX OF LAST INPUT FILE IF COMMA-SEPARATED 

=cut

sub fileSuffix { 
	my $self		=	shift;
	my $filename	=	shift;
	return $filename =~ /(\.[^\.]{1,5})$/;
}


=head

	SUBROUTINE 		copyFiles
	
	PURPOSE
	
		MOVE NUMERIC DIRECTORIES

=cut

sub copyFiles {
	my $self		=	shift;
	my $source		=	shift;
	my $target		=	shift;
	my $filename	=	shift;
	my $mode		=	shift;
	my $directory	=	shift;
	$self->logDebug("Agua::Cluster::copyFile(source, target, filename)");
	$self->logDebug("source", $source);
	$self->logDebug("target", $target);
	$self->logDebug("filename", $filename);
	$self->logDebug("mode", $mode)  if defined $mode;
	$self->logDebug("directory", $directory)  if defined $directory;

	#### CHECK INPUTS
	$self->logCritical("mode not supported (subdirs|archive|delete) (Use --help for usage)") and exit if defined $mode and $mode !~ /^(name|regex)$/;
	$self->logDebug("source not defined", $source) if not defined $source or not $source;
	$self->logDebug("Can't find source", $source) if not -d $source;
	$self->logDebug("target not defined", $target) if not defined $target or not $target;
	$self->logDebug("Can't find target", $target) if not -d $target;
	$self->logDebug("mode not defined", $filename) if not defined $filename or not $filename;

	if ( not defined $mode or $mode =~ /^name$/ )
	{
		$self->logDebug("Running search by name", $filename);

		my @files = split "," , $filename;
		foreach my $file ( @files )
		{
			my $sourcefile = "$source/$file";
			$self->logDebug("Can't find sourcefile", $sourcefile) and next if not -f $sourcefile and not defined $directory;
			$self->logDebug("Can't find sourcefile", $sourcefile) and next if not -d $sourcefile and defined $directory;

			File::Path::mkpath($target) if not -d $target;
			$self->logDebug("Can't create target", $target) if not -d $target;

			my $command = "cp -r $sourcefile $target";
			$self->logDebug("command", $command);
			print `$command`;
		}
	}
	elsif ( $mode =~ /^regex$/ )
	{
		opendir(DIR, $source) or die "Can't open source directory: $source\n";
		my @foundfiles = readdir(DIR);
		close(DIR);

		foreach my $foundfile ( @foundfiles )
		{
			$self->logDebug("foundfile is not a file: $foundfile. Skipping")
				and next if -d $foundfile and not defined $directory;
			$self->logDebug("foundfile is a file: $foundfile. Skipping")
				and next if -f $foundfile and defined $directory;
			my @patterns = split "," , $filename;
			foreach my $pattern ( @patterns )
			{
				use re 'eval';		# EVALUATE $pattern AS REGULAR EXPRESSION
				
				if ( $foundfile =~ /$pattern/ )
				{
					my $command = "cp-r  $source/$foundfile $target";
					$self->logDebug("command", $command);
					print `$command`;
				}
				
				no re 'eval';		# STOP EVALUATING AS REGULAR EXPRESSION
			}
		}
	}
}


=head

	SUBROUTINE 		moveDirs
	
	PURPOSE
	
		MOVE NUMERIC OR ALPHABETIC DIRECTORIES

=cut

sub moveDirs {
	my $self		=	shift;
	my $source		=	shift;
	my $target		=	shift;
	my $mode		=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logDebug("source not defined", $source) if not defined $source or not $source;
	$self->logDebug("Can't find source", $source) if not -d $source;
	$self->logDebug("target not defined", $target) if not defined $target or not $target;
	$self->logDebug("Can't find target", $target) if not -d $target;
	$self->logDebug("mode not defined", $mode) if not defined $mode or not $mode;

	#### CHDIR TO OUTPUT DIRECTORY
	chdir($source) or die "Could not CHDIR to source: $source\n";
	opendir(DIR, $source) or die "Can't open source: $source\n";
	my @subdirs = readdir(DIR);
	close(DIR);
	for ( my $i = 0; $i < @subdirs; $i++ )
	{
		my $subdir = "$source/$subdirs[$i]";
		splice @subdirs, $i, 1 if not -d $subdir;
		$i-- if not -d $subdir;
	}
	$self->logDebug("subdirs: @subdirs");

	foreach my $subdir ( @subdirs )
	{
		next if not $subdir =~ /^\d+$/;
		$self->logDebug("subdir", $subdir);
		
		my $command = "mv $source/$subdir $target";
		$self->logDebug("command", $command);
		print `$command`;
	}
}


sub getSubdirs {
	my $self		=	shift;
	my $directory	=	shift;

	#### GET FILES
	opendir(DIR, $directory) or die "Can't open directory: $directory\n";
	my @files = readdir(DIR);
	closedir(DIR) or die "Can't close directory: $directory\n";
	
	return \@files;
	
}

1;
